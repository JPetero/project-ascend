import { Injectable } from '@nestjs/common';

const MAX_PLANNED_QUERIES = 2;

// A query that already looks like it's asking for the evidence itself
// ("shin splints treatment guidelines") doesn't benefit from a second,
// near-duplicate search — this keeps the common case to a single Brave
// Search call instead of always spending two.
const ALREADY_EVIDENCE_FOCUSED_PATTERN =
  /\b(guideline|guidelines|evidence|study|studies|research|systematic review|meta-analysis|clinical trial)\b/i;

const EVIDENCE_EXPANSION_SUFFIX = 'clinical evidence guidelines';

/**
 * Query planning (Build Session 12 Part 5) — the first stage of the
 * research pipeline. Deliberately simple and deterministic rather than
 * LLM-generated: a fixed, reviewable expansion rule broadens plain
 * questions ("is creatine safe") toward the vocabulary evidence-based
 * sources actually use, without ever inventing or guessing at query
 * intent. `ResearchSynthesisService` calls `plan` once per user query and
 * retrieves each planned sub-query separately before deduping.
 */
@Injectable()
export class ResearchQueryPlannerService {
  plan(query: string): string[] {
    const trimmed = query.trim();
    if (!trimmed) return [];

    const queries = [trimmed];
    if (!ALREADY_EVIDENCE_FOCUSED_PATTERN.test(trimmed) && queries.length < MAX_PLANNED_QUERIES) {
      queries.push(`${trimmed} ${EVIDENCE_EXPANSION_SUFFIX}`);
    }
    return queries;
  }
}
