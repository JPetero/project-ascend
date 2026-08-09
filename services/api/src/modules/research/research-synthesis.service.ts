import { Inject, Injectable } from '@nestjs/common';
import { ResearchQueryPlannerService } from './research-query-planner.service';
import {
  EvidenceCategoryDto,
  ResearchAnswerResult,
  ResearchCitationResult,
  ResearchDocumentResult,
} from './research.types';
import { RESEARCH_PROVIDER, ResearchProvider } from './providers/research-provider.interface';

const MAX_SOURCES = 6;
const MAX_DEEPER_EXPLANATION_SOURCES = 3;

// Lower = stronger. Ties (PEER_REVIEWED/SYSTEMATIC_REVIEW) are broken by
// retrieval order. This is a ranking signal, not the citable/not-citable
// boundary — that boundary is `classifyHost` returning `undefined`
// (OTHER), which never reaches this service at all.
const CATEGORY_STRENGTH: Record<EvidenceCategoryDto, number> = {
  [EvidenceCategoryDto.PEER_REVIEWED]: 1,
  [EvidenceCategoryDto.SYSTEMATIC_REVIEW]: 1,
  [EvidenceCategoryDto.GOVERNMENT]: 2,
  [EvidenceCategoryDto.CLINICAL_GUIDANCE]: 3,
  [EvidenceCategoryDto.PROFESSIONAL_ORGANIZATION]: 3,
  [EvidenceCategoryDto.UNIVERSITY]: 3,
  [EvidenceCategoryDto.HEALTH_SYSTEM]: 4,
  [EvidenceCategoryDto.OTHER]: 5,
};

const STRONG_CATEGORIES = new Set([
  EvidenceCategoryDto.PEER_REVIEWED,
  EvidenceCategoryDto.SYSTEMATIC_REVIEW,
  EvidenceCategoryDto.GOVERNMENT,
]);

// Literal hedging/conflict language a source might use about its own
// evidence base — surfaced verbatim as `contradictoryEvidenceNote` rather
// than an invented "sources disagree" judgment call.
const CONFLICT_SIGNAL_PATTERN =
  /\b(conflicting|inconclusive|insufficient evidence|no consensus|more research is needed|mixed evidence|contradictory findings|not enough evidence)\b/i;

function dedupeBySourceId(documents: ResearchDocumentResult[]): ResearchDocumentResult[] {
  const seen = new Set<string>();
  const result: ResearchDocumentResult[] = [];
  for (const document of documents) {
    if (seen.has(document.sourceId)) continue;
    seen.add(document.sourceId);
    result.push(document);
  }
  return result;
}

function rankByStrength(documents: ResearchDocumentResult[]): ResearchDocumentResult[] {
  return [...documents].sort(
    (a, b) => CATEGORY_STRENGTH[a.evidenceCategory] - CATEGORY_STRENGTH[b.evidenceCategory],
  );
}

function buildConciseAnswer(query: string, top: ResearchDocumentResult): string {
  return (
    top.excerpt ??
    `See "${top.title}" (${top.publisher}) for source-backed information on "${query}".`
  );
}

function buildDeeperExplanation(documents: ResearchDocumentResult[]): string {
  const withExcerpts = documents
    .slice(0, MAX_DEEPER_EXPLANATION_SOURCES)
    .filter((document) => document.excerpt);
  if (withExcerpts.length === 0) {
    return 'No further excerpt text was available from the retrieved sources — open a source below for the full detail.';
  }
  return withExcerpts.map((document) => `${document.publisher}: ${document.excerpt}`).join('\n\n');
}

function buildUncertaintyNote(documents: ResearchDocumentResult[]): string | undefined {
  if (documents.length < 2) {
    return (
      'Only one verified source was found — treat this as a starting point, not a full ' +
      'picture, and consider searching further or asking a qualified professional.'
    );
  }
  if (!documents.some((document) => STRONG_CATEGORIES.has(document.evidenceCategory))) {
    return (
      'No peer-reviewed research or government health guidance was found for this — the ' +
      'sources below are lower-certainty and should not be treated as clinical guidance.'
    );
  }
  return undefined;
}

function findContradictoryEvidenceNote(documents: ResearchDocumentResult[]): string | undefined {
  const flagged = documents.find(
    (document) => document.excerpt && CONFLICT_SIGNAL_PATTERN.test(document.excerpt),
  );
  return flagged ? `${flagged.publisher} notes: "${flagged.excerpt}"` : undefined;
}

function emptyAnswer(query: string): ResearchAnswerResult {
  return {
    query,
    conciseAnswer:
      `No verified, source-backed information was found for "${query}" among peer-reviewed ` +
      'research, government health agencies, clinical guidance, professional organizations, ' +
      'universities, or established health systems.',
    deeperExplanation:
      'Try rephrasing or narrowing your question, or consult a qualified professional directly.',
    citations: [],
    sources: [],
  };
}

/**
 * The grounded research pipeline itself (Build Session 12 Part 5):
 * query planning → retrieval → normalization/classification (both inside
 * `ResearchProvider.fetchDocuments`) → dedupe/ranking → extractive
 * synthesis → citation validation. `conciseAnswer`/`deeperExplanation`
 * are built by quoting/concatenating real retrieved excerpts, never by
 * generating new prose — the same "no generative step that could
 * hallucinate a fact" property `BraveSearchResearchProvider` documents,
 * just applied across multiple documents instead of one. `citations`
 * still goes through `validateCitations` as an explicit, tested hard
 * boundary: any citation whose `sourceId` doesn't match a real retrieved
 * `sources` entry is dropped rather than ever reaching the client — the
 * enforcement point a future generative synthesizer would also have to
 * pass through.
 */
@Injectable()
export class ResearchSynthesisService {
  constructor(
    @Inject(RESEARCH_PROVIDER) private readonly provider: ResearchProvider,
    private readonly planner: ResearchQueryPlannerService,
  ) {}

  async answer(query: string): Promise<ResearchAnswerResult> {
    const plannedQueries = this.planner.plan(query);

    const fetched = await Promise.all(
      plannedQueries.map((plannedQuery) => this.provider.fetchDocuments(plannedQuery)),
    );
    const documents = rankByStrength(dedupeBySourceId(fetched.flat())).slice(0, MAX_SOURCES);

    if (documents.length === 0) {
      return emptyAnswer(query);
    }

    const citations: ResearchCitationResult[] = documents
      .filter((document) => document.excerpt)
      .map((document) => ({ sourceId: document.sourceId, quote: document.excerpt! }));

    return {
      query,
      conciseAnswer: buildConciseAnswer(query, documents[0]),
      deeperExplanation: buildDeeperExplanation(documents),
      uncertaintyNote: buildUncertaintyNote(documents),
      contradictoryEvidenceNote: findContradictoryEvidenceNote(documents),
      citations: this.validateCitations(citations, documents),
      sources: documents,
    };
  }

  /**
   * Hard rule per user-scenario-bible.md Scenario 19: the synthesizer may
   * only cite a source present in this response's own retrieved
   * documents. By construction every citation above already comes from
   * `documents`, but this filter is the explicit, unit-tested enforcement
   * boundary — never trust "this should already be true," verify it.
   */
  private validateCitations(
    citations: ResearchCitationResult[],
    documents: ResearchDocumentResult[],
  ): ResearchCitationResult[] {
    const knownSourceIds = new Set(documents.map((document) => document.sourceId));
    return citations.filter((citation) => knownSourceIds.has(citation.sourceId));
  }
}
