import { ResearchDocumentResult } from './research.types';

const CITATION_TAG_PATTERN = /\[S(\d+)\]/g;
// Splits after a sentence-ending mark followed by whitespace and more
// text — deliberately simple (no abbreviation handling) since the prompt
// this feeds controls the input shape; see buildSynthesisPrompt.
const SENTENCE_SPLIT_PATTERN = /(?<=[.!?])\s+(?=\S)/;

/**
 * The flat prompt sent to `AiReplyProvider.generateResearchSynthesis`
 * (S13 Part 10-12). Sources are numbered `[S1]`...`[Sn]` matching
 * `documents`' order, and the model is told every factual sentence must
 * end with the tag(s) of the source(s) it came from. This is the half of
 * the grounding contract enforced by instruction; `parseGroundedAnswer`
 * below is the half enforced by code — an untagged or wrongly-tagged
 * sentence never survives regardless of what the prompt asked for.
 */
export function buildSynthesisPrompt(query: string, documents: ResearchDocumentResult[]): string {
  const sourceList = documents
    .map((document, index) => {
      const excerpt = document.excerpt ? ` — "${document.excerpt}"` : '';
      return `[S${index + 1}] ${document.title} (${document.publisher})${excerpt}`;
    })
    .join('\n');

  return [
    'You are answering a fitness/health question using ONLY the numbered sources below. ' +
      'Do not use any outside knowledge, and never invent a fact the sources do not support.',
    '',
    `Question: ${query}`,
    '',
    'Sources:',
    sourceList,
    '',
    'Write a concise answer (2-4 sentences). Every sentence that states a fact MUST end with ' +
      `the tag(s) of the source(s) it came from, e.g. "Regular cardio lowers resting heart ` +
      `rate[S1]." Only use tags from the list above (S1 through S${documents.length}) — never ` +
      'a source not listed, and never a bare sentence with no tag. If the sources do not ' +
      'support an answer, say so plainly instead of guessing.',
  ].join('\n');
}

/**
 * The code-enforced half of the grounding contract. Splits the model's
 * raw text into sentences and keeps only sentences carrying at least one
 * `[S<n>]` tag that resolves to a real entry in `documents` — an
 * untagged sentence (ungrounded) or one whose tags are all out of range
 * (hallucinated source) is dropped outright. A sentence with a MIX of
 * valid and invalid tags is kept (the valid tag already proves it's
 * grounded); either way the visible `[S...]` markup is stripped before
 * the sentence is returned, since the tags exist only to let this
 * function verify grounding — the tags themselves were never meant to
 * reach the client (which already gets a separate, source-linked
 * `citations`/`sources` list from `ResearchSynthesisService`).
 *
 * Returns `null` when nothing survives, so the caller can fall back to
 * the extractive answer rather than ever returning an empty string.
 */
export function parseGroundedAnswer(
  rawText: string,
  documents: ResearchDocumentResult[],
): string | null {
  const maxSourceNumber = documents.length;
  const sentences = rawText
    .trim()
    .split(SENTENCE_SPLIT_PATTERN)
    .map((sentence) => sentence.trim())
    .filter((sentence) => sentence.length > 0);

  const groundedSentences: string[] = [];

  for (const sentence of sentences) {
    const tags = [...sentence.matchAll(CITATION_TAG_PATTERN)];
    if (tags.length === 0) continue;

    const hasValidTag = tags.some((tag) => {
      const sourceNumber = Number(tag[1]);
      return sourceNumber >= 1 && sourceNumber <= maxSourceNumber;
    });
    if (!hasValidTag) continue;

    const stripped = sentence
      .replace(CITATION_TAG_PATTERN, '')
      .replace(/\s+([.,!?;:])/g, '$1')
      .replace(/\s+/g, ' ')
      .trim();
    if (stripped.length === 0) continue;

    groundedSentences.push(stripped);
  }

  return groundedSentences.length > 0 ? groundedSentences.join(' ') : null;
}
