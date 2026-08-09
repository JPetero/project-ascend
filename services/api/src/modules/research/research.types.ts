/**
 * Mirrors `EvidenceQuality`/`ResearchSource`/`ResearchAnswer` on the
 * mobile side (features/companion/domain/research_answer.dart). See
 * packages/docs/product/user-scenario-bible.md Scenario 19: sources are
 * restricted to peer-reviewed research, medical organizations,
 * government health agencies, universities, and official clinical
 * guidance — "a general web search engine is a discovery tool, not an
 * evidence-quality category," so a result outside those categories is
 * never surfaced, at any quality tier.
 */
export enum EvidenceQualityDto {
  HIGH = 'HIGH',
  MODERATE = 'MODERATE',
  LOW = 'LOW',
}

export interface ResearchSourceResult {
  label: string;
  // Real, verifiable — the literal URL a real search returned, never
  // invented. Safe to include (unlike the mobile domain type's original
  // no-URL stance from before a real provider existed) because it is no
  // longer a fabricated citation.
  url: string;
  // The literal snippet text the search API returned for this result —
  // shown verbatim rather than summarized/rewritten, so nothing here is
  // ever an invented paraphrase of what a source says.
  snippet?: string;
  evidenceQuality: EvidenceQualityDto;
  publicationYear?: number;
}

export interface ResearchAnswerResult {
  summary: string;
  sources: ResearchSourceResult[];
}
