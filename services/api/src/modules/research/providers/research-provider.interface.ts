import { ResearchDocumentResult } from '../research.types';

/**
 * Swappable retrieval adapter (Build Session 10 Part 16). Build Session
 * 12 Part 5 narrowed this to the retrieval pipeline's own stage —
 * fetching, normalizing, and classifying real search results into
 * [ResearchDocumentResult]s — and moved query planning + synthesis +
 * citation validation into `ResearchSynthesisService`, which orchestrates
 * one or more calls to this method. Every implementation honestly rejects
 * instead of fabricating a document when it isn't configured; see
 * ResearchModule's factory for how the active one is selected.
 */
export interface ResearchProvider {
  readonly isConfigured: boolean;
  fetchDocuments(query: string): Promise<ResearchDocumentResult[]>;
}

export const RESEARCH_PROVIDER = Symbol('RESEARCH_PROVIDER');
