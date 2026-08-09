import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ResearchConfig } from '../../../config/configuration';
import {
  EvidenceCategoryDto,
  ResearchDocumentResult,
  evidenceQualityForCategory,
} from '../research.types';
import { ResearchProvider } from './research-provider.interface';

const BRAVE_SEARCH_URL = 'https://api.search.brave.com/res/v1/web/search';
const RESULT_COUNT = 10;
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
// as a cited source — a raw web result outside these categories is
// dropped entirely (classifyHost returns undefined, i.e. OTHER) rather
// than labeled a weak-but-citable tier, since "a general web search
// engine is a discovery tool, not an evidence-quality category." This is
// also how spam/sales pages/blogs/influencer content/content farms are
// excluded: they simply never match any category below, so there's no
// separate spam-detection pass to maintain.
const PEER_REVIEWED_HOSTS = [
  'pubmed.ncbi.nlm.nih.gov',
  'ncbi.nlm.nih.gov',
  'nature.com',
  'thelancet.com',
  'nejm.org',
  'bmj.com',
  'jamanetwork.com',
  'sciencedirect.com',
];

const SYSTEMATIC_REVIEW_HOSTS = ['cochranelibrary.com'];

const CLINICAL_GUIDANCE_HOSTS = ['nice.org.uk', 'uptodate.com'];

const HEALTH_SYSTEM_HOSTS = ['mayoclinic.org', 'clevelandclinic.org', 'hopkinsmedicine.org'];

// Named government health bodies that don't happen to live on a `.gov`-
// pattern TLD (e.g. the UK's NHS is `nhs.uk`, not `gov.uk`) — matched
// alongside the TLD-pattern check in `isGovernmentTld`, not instead of
// it, so this list stays short and the TLD check carries the "globally
// aware, not US-centric" weight.
const GOVERNMENT_HOSTS = ['who.int', 'nhs.uk'];

const PROFESSIONAL_ORGANIZATION_HOSTS = [
  'acsm.org',
  'nasm.org',
  'acefitness.org',
  'heart.org',
  'diabetes.org',
  'eatright.org',
  'apa.org',
];

// Deliberately finite and reviewable — every host above has a name here.
// Anything else falls back to its own hostname rather than an invented
// display name.
const PUBLISHER_NAMES: Record<string, string> = {
  'pubmed.ncbi.nlm.nih.gov': 'PubMed',
  'ncbi.nlm.nih.gov': 'NCBI',
  'nature.com': 'Nature',
  'thelancet.com': 'The Lancet',
  'nejm.org': 'New England Journal of Medicine',
  'bmj.com': 'BMJ',
  'jamanetwork.com': 'JAMA Network',
  'sciencedirect.com': 'ScienceDirect',
  'cochranelibrary.com': 'Cochrane Library',
  'nice.org.uk': 'NICE',
  'uptodate.com': 'UpToDate',
  'mayoclinic.org': 'Mayo Clinic',
  'clevelandclinic.org': 'Cleveland Clinic',
  'hopkinsmedicine.org': 'Johns Hopkins Medicine',
  'who.int': 'World Health Organization',
  'nhs.uk': 'NHS',
  'nih.gov': 'National Institutes of Health',
  'cdc.gov': 'CDC',
  'fda.gov': 'FDA',
  'acsm.org': 'American College of Sports Medicine',
  'nasm.org': 'National Academy of Sports Medicine',
  'acefitness.org': 'American Council on Exercise',
  'heart.org': 'American Heart Association',
  'diabetes.org': 'American Diabetes Association',
  'eatright.org': 'Academy of Nutrition and Dietetics',
  'apa.org': 'American Psychological Association',
};

function hostMatches(hostname: string, domains: string[]): boolean {
  return domains.some((domain) => hostname === domain || hostname.endsWith(`.${domain}`));
}

// International government TLD patterns — `.gov`, `.gov.uk`, `.gov.au`,
// `.gc.ca`, `.gouv.fr`, etc. — rather than a single-country domain list,
// so this classifies non-US government health authorities correctly too.
function isGovernmentTld(hostname: string): boolean {
  return /(^|\.)(gov|gouv|gc)(\.[a-z]{2,3})?$/.test(hostname);
}

// `.edu`, `.edu.au`, `.ac.uk`, `.ac.jp`, etc. — same "match the pattern,
// not one country's TLD" approach as `isGovernmentTld`.
function isUniversityTld(hostname: string): boolean {
  return /(^|\.)(edu|ac)(\.[a-z]{2,3})?$/.test(hostname);
}

function classifyHost(
  hostname: string,
): Exclude<EvidenceCategoryDto, EvidenceCategoryDto.OTHER> | undefined {
  const host = hostname.toLowerCase().replace(/^www\./, '');
  if (hostMatches(host, PEER_REVIEWED_HOSTS)) return EvidenceCategoryDto.PEER_REVIEWED;
  if (hostMatches(host, SYSTEMATIC_REVIEW_HOSTS)) return EvidenceCategoryDto.SYSTEMATIC_REVIEW;
  if (hostMatches(host, CLINICAL_GUIDANCE_HOSTS)) return EvidenceCategoryDto.CLINICAL_GUIDANCE;
  if (hostMatches(host, HEALTH_SYSTEM_HOSTS)) return EvidenceCategoryDto.HEALTH_SYSTEM;
  if (hostMatches(host, PROFESSIONAL_ORGANIZATION_HOSTS))
    return EvidenceCategoryDto.PROFESSIONAL_ORGANIZATION;
  if (hostMatches(host, GOVERNMENT_HOSTS) || isGovernmentTld(host))
    return EvidenceCategoryDto.GOVERNMENT;
  if (isUniversityTld(host)) return EvidenceCategoryDto.UNIVERSITY;
  return undefined;
}

function publisherNameFor(hostname: string): string {
  const host = hostname.toLowerCase().replace(/^www\./, '');
  return PUBLISHER_NAMES[host] ?? host;
}

function extractPublicationYear(pageAge: string | undefined): number | undefined {
  if (!pageAge) return undefined;
  const parsed = new Date(pageAge);
  if (Number.isNaN(parsed.getTime())) return undefined;
  const year = parsed.getUTCFullYear();
  const currentYear = new Date().getUTCFullYear();
  return year >= MIN_PLAUSIBLE_YEAR && year <= currentYear ? year : undefined;
}

/**
 * Real retrieval (Build Session 10 Part 16) via Brave's Web Search API —
 * chosen for its simple REST/API-key shape (no OAuth dance, no scraping
 * ToS concerns). Build Session 12 Part 5 narrowed this class to the
 * retrieval + normalization + classification stage only — query planning
 * and synthesis now live in `ResearchQueryPlannerService`/
 * `ResearchSynthesisService`, which call `fetchDocuments` once per
 * planned sub-query. This class still never synthesizes prose itself:
 * every field it returns is either literal search-result text
 * (title/url/excerpt) or a deterministic classification, so there is no
 * generative step here that could hallucinate a fact not present in a
 * real result. No live BRAVE_SEARCH_API_KEY exists in this environment,
 * so this code path is real but untested against a live Brave response
 * outside the mocked unit test — see build-session-10.md.
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

  async fetchDocuments(query: string): Promise<ResearchDocumentResult[]> {
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

    const documents: ResearchDocumentResult[] = [];
    for (const result of results) {
      let hostname: string;
      try {
        hostname = new URL(result.url).hostname;
      } catch {
        continue;
      }

      const evidenceCategory = classifyHost(hostname);
      if (!evidenceCategory) continue;

      documents.push({
        sourceId: result.url,
        title: result.title,
        url: result.url,
        publisher: publisherNameFor(hostname),
        publicationYear: extractPublicationYear(result.page_age),
        evidenceCategory,
        evidenceQuality: evidenceQualityForCategory(evidenceCategory),
        excerpt: result.description?.trim() || undefined,
      });
    }

    return documents;
  }
}
