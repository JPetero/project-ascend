/**
 * Mirrors the mobile domain types in
 * features/companion/domain/research_answer.dart. See
 * packages/docs/product/user-scenario-bible.md Scenario 19: sources are
 * restricted to peer-reviewed research, medical organizations,
 * government health agencies, universities, and official clinical
 * guidance — "a general web search engine is a discovery tool, not an
 * evidence-quality category," so a result outside those categories is
 * never surfaced, at any quality tier.
 *
 * Build Session 12 Part 5 replaced the original flat HIGH/MODERATE/LOW
 * host-list classification with [EvidenceCategoryDto] — the underlying
 * kind of publisher, which is what actually determines evidence strength
 * — and derives the coarser [EvidenceQualityDto] tier from it. Neither
 * list is US-centric: GOVERNMENT and UNIVERSITY match by TLD pattern
 * (`.gov`, `.gov.uk`, `.edu`, `.ac.uk`, etc.), not a hardcoded American
 * domain list.
 */
export enum EvidenceCategoryDto {
  PEER_REVIEWED = 'PEER_REVIEWED',
  SYSTEMATIC_REVIEW = 'SYSTEMATIC_REVIEW',
  GOVERNMENT = 'GOVERNMENT',
  PROFESSIONAL_ORGANIZATION = 'PROFESSIONAL_ORGANIZATION',
  UNIVERSITY = 'UNIVERSITY',
  CLINICAL_GUIDANCE = 'CLINICAL_GUIDANCE',
  HEALTH_SYSTEM = 'HEALTH_SYSTEM',
  // Anything that doesn't match one of the categories above — a general
  // web search engine result, a blog, a content farm, a sales page. Never
  // cited, at any quality tier; see BraveSearchResearchProvider's
  // `classifyHost`.
  OTHER = 'OTHER',
}

export enum EvidenceQualityDto {
  HIGH = 'HIGH',
  MODERATE = 'MODERATE',
  LOW = 'LOW',
}

/** OTHER-category documents are filtered out before this is ever called. */
export function evidenceQualityForCategory(
  category: Exclude<EvidenceCategoryDto, EvidenceCategoryDto.OTHER>,
): EvidenceQualityDto {
  switch (category) {
    case EvidenceCategoryDto.PEER_REVIEWED:
    case EvidenceCategoryDto.SYSTEMATIC_REVIEW:
    case EvidenceCategoryDto.GOVERNMENT:
      return EvidenceQualityDto.HIGH;
    case EvidenceCategoryDto.CLINICAL_GUIDANCE:
    case EvidenceCategoryDto.PROFESSIONAL_ORGANIZATION:
    case EvidenceCategoryDto.UNIVERSITY:
      return EvidenceQualityDto.MODERATE;
    case EvidenceCategoryDto.HEALTH_SYSTEM:
      return EvidenceQualityDto.LOW;
  }
}

/**
 * A single retrieved, normalized, and classified source — the pipeline's
 * "grounding" unit. [sourceId] is the literal URL: stable, unique, and
 * verifiable (a client can open it directly), never an invented id.
 * [excerpt] is the literal snippet text a real search returned, shown
 * verbatim rather than summarized/rewritten, so nothing here is ever an
 * invented paraphrase of what a source says.
 */
export interface ResearchDocumentResult {
  sourceId: string;
  title: string;
  url: string;
  publisher: string;
  publicationYear?: number;
  evidenceCategory: EvidenceCategoryDto;
  evidenceQuality: EvidenceQualityDto;
  excerpt?: string;
}

/**
 * A citation the synthesis step attached to the answer. [sourceId] must
 * match a [ResearchDocumentResult.sourceId] present in the same
 * response's `sources` — `ResearchSynthesisService.validateCitations`
 * enforces this as a hard rule, stripping any citation that doesn't
 * resolve to a real retrieved document rather than ever surfacing an
 * unverifiable one.
 */
export interface ResearchCitationResult {
  sourceId: string;
  quote: string;
}

export interface ResearchAnswerResult {
  query: string;
  conciseAnswer: string;
  deeperExplanation: string;
  // Present whenever the evidence behind conciseAnswer is thin (fewer
  // than two sources) or entirely below HIGH quality — the pipeline
  // explicitly refuses to overstate certainty it doesn't have.
  uncertaintyNote?: string;
  // Present only when a retrieved excerpt itself contains literal
  // hedging/conflict language ("inconclusive," "no consensus," etc.) —
  // never an invented judgment call, always the source's own words.
  contradictoryEvidenceNote?: string;
  citations: ResearchCitationResult[];
  sources: ResearchDocumentResult[];
}
