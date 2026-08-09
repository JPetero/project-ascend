import { ResearchAnswerResult } from '../research.types';

/**
 * Swappable retrieval adapter (Build Session 10 Part 16) — the interface
 * `ResearchController` delegates to, so adding/replacing a search backend
 * never means touching the controller. Every implementation honestly
 * rejects instead of fabricating a citation when it isn't configured;
 * see ResearchModule's factory for how the active one is selected.
 */
export interface ResearchProvider {
  readonly isConfigured: boolean;
  search(query: string): Promise<ResearchAnswerResult>;
}

export const RESEARCH_PROVIDER = Symbol('RESEARCH_PROVIDER');
