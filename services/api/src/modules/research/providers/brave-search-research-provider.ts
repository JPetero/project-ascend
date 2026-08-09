import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ResearchConfig } from '../../../config/configuration';
import { EvidenceQualityDto, ResearchAnswerResult, ResearchSourceResult } from '../research.types';
import { ResearchProvider } from './research-provider.interface';

const BRAVE_SEARCH_URL = 'https://api.search.brave.com/res/v1/web/search';
const RESULT_COUNT = 10;
const MAX_SOURCES = 5;
const MIN_PLAUSIBLE_YEAR = 1990;

interface BraveWebResult {
  title: string;
  url: string;
  description?: string;
  page_age?: string;
}

interface BraveSearchResponse {
  web?: { results?: BraveWebResult[] };
}

// Per user-scenario-bible.md Scenario 19: only peer-reviewed research,
// professional medical organizations, government health agencies,
// established universities, and official clinical guidance ever qualify
// as a cited source — a raw web result outside these tiers is dropped
// entirely rather than labeled "low" evidence, since "a general web
// search engine is a discovery tool, not an evidence-quality category."
const HIGH_QUALITY_HOSTS = [
  'pubmed.ncbi.nlm.nih.gov',
  'ncbi.nlm.nih.gov',
  'nih.gov',
  'cochranelibrary.com',
  'cdc.gov',
  'fda.gov',
  'who.int',
];

const MODERATE_QUALITY_HOSTS = [
  'mayoclinic.org',
  'clevelandclinic.org',
  'hopkinsmedicine.org',
  'acsm.org',
  'nasm.org',
  'acefitness.org',
  'heart.org',
  'diabetes.org',
];

// Established health publishers with editorial/medical review, but not
// peer-reviewed, government, or academic — the weakest tier this
// provider will still cite, never anything below it.
const LOW_QUALITY_HOSTS = [
  'healthline.com',
  'webmd.com',
  'verywellfit.com',
  'medicalnewstoday.com',
];

function hostMatches(hostname: string, domains: string[]): boolean {
  return domains.some((domain) => hostname === domain || hostname.endsWith(`.${domain}`));
}

function classifyHost(hostname: string): EvidenceQualityDto | undefined {
  const host = hostname.toLowerCase().replace(/^www\./, '');
  if (hostMatches(host, HIGH_QUALITY_HOSTS)) {
    return EvidenceQualityDto.HIGH;
  }
  if (host.endsWith('.gov') || host.endsWith('.edu') || hostMatches(host, MODERATE_QUALITY_HOSTS)) {
    return EvidenceQualityDto.MODERATE;
  }
  if (hostMatches(host, LOW_QUALITY_HOSTS)) {
    return EvidenceQualityDto.LOW;
  }
  return undefined;
}

function extractPublicationYear(pageAge: string | undefined): number | undefined {
  if (!pageAge) return undefined;
  const parsed = new Date(pageAge);
  if (Number.isNaN(parsed.getTime())) return undefined;
  const year = parsed.getUTCFullYear();
  const currentYear = new Date().getUTCFullYear();
  return year >= MIN_PLAUSIBLE_YEAR && year <= currentYear ? year : undefined;
}

function buildSummary(query: string, sourceCount: number): string {
  if (sourceCount === 0) {
    return (
      `No verified, source-backed information was found for "${query}" among peer-reviewed ` +
      'research, medical organizations, government health agencies, or universities. Try ' +
      'rephrasing your question, or consult a qualified professional directly.'
    );
  }
  return `Found ${sourceCount} verified source${sourceCount === 1 ? '' : 's'} for "${query}".`;
}

/**
 * Real retrieval (Build Session 10 Part 16) via Brave's Web Search API —
 * chosen for its simple REST/API-key shape (no OAuth dance, no scraping
 * ToS concerns), following the same "read the real API before writing
 * the adapter" discipline as every other live integration this session.
 * Deliberately does not synthesize a summary paragraph with an LLM: per
 * Scenario 19's hard "must never invent a citation" rule, every string
 * this returns is either literal search-result text (title/url/snippet)
 * or a deterministic count — there is no generative step that could
 * hallucinate a fact not present in a real result. No live
 * BRAVE_SEARCH_API_KEY exists in this environment, so this code path is
 * real but untested against a live Brave response outside the mocked
 * unit test — see build-session-10.md.
 */
@Injectable()
export class BraveSearchResearchProvider implements ResearchProvider {
  private readonly apiKey: string | undefined;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<ResearchConfig>('research')!.braveSearchApiKey;
  }

  get isConfigured(): boolean {
    return Boolean(this.apiKey);
  }

  async search(query: string): Promise<ResearchAnswerResult> {
    if (!this.apiKey) {
      throw new ServiceUnavailableException(
        'Research mode is not configured. Set BRAVE_SEARCH_API_KEY to enable it.',
      );
    }

    const url = new URL(BRAVE_SEARCH_URL);
    url.searchParams.set('q', query);
    url.searchParams.set('count', String(RESULT_COUNT));

    const response = await fetch(url, {
      headers: {
        Accept: 'application/json',
        'X-Subscription-Token': this.apiKey,
      },
    });

    if (!response.ok) {
      throw new ServiceUnavailableException(`Brave Search request failed (${response.status}).`);
    }

    const body = (await response.json()) as BraveSearchResponse;
    const results = body.web?.results ?? [];

    const sources: ResearchSourceResult[] = [];
    for (const result of results) {
      if (sources.length >= MAX_SOURCES) break;

      let hostname: string;
      try {
        hostname = new URL(result.url).hostname;
      } catch {
        continue;
      }

      const evidenceQuality = classifyHost(hostname);
      if (!evidenceQuality) continue;

      sources.push({
        label: result.title,
        url: result.url,
        snippet: result.description,
        evidenceQuality,
        publicationYear: extractPublicationYear(result.page_age),
      });
    }

    return { summary: buildSummary(query, sources.length), sources };
  }
}
