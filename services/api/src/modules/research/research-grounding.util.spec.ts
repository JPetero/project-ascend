import { buildSynthesisPrompt, parseGroundedAnswer } from './research-grounding.util';
import { EvidenceCategoryDto, EvidenceQualityDto, ResearchDocumentResult } from './research.types';

function doc(overrides: Partial<ResearchDocumentResult> = {}): ResearchDocumentResult {
  return {
    sourceId: 'https://pubmed.ncbi.nlm.nih.gov/1',
    title: 'A study on exercise',
    url: 'https://pubmed.ncbi.nlm.nih.gov/1',
    publisher: 'PubMed',
    evidenceCategory: EvidenceCategoryDto.PEER_REVIEWED,
    evidenceQuality: EvidenceQualityDto.HIGH,
    excerpt: 'Evidence supports X.',
    ...overrides,
  };
}

const twoDocs = [
  doc(),
  doc({
    sourceId: 'https://nih.gov/b',
    url: 'https://nih.gov/b',
    title: 'A government guideline',
    publisher: 'NIH',
  }),
];

describe('buildSynthesisPrompt', () => {
  it('numbers each source to match the [S<n>] tags the model must use', () => {
    const prompt = buildSynthesisPrompt('is creatine safe', twoDocs);

    expect(prompt).toContain('is creatine safe');
    expect(prompt).toContain('[S1] A study on exercise (PubMed)');
    expect(prompt).toContain('[S2] A government guideline (NIH)');
  });

  it('caps the instructed tag range at the number of sources given', () => {
    const prompt = buildSynthesisPrompt('is creatine safe', twoDocs);

    expect(prompt).toContain('S1 through S2');
  });
});

describe('parseGroundedAnswer', () => {
  it('keeps a fully grounded sentence and strips its citation tag', () => {
    const result = parseGroundedAnswer('Exercise lowers resting heart rate[S1].', twoDocs);

    expect(result).toBe('Exercise lowers resting heart rate.');
  });

  it('keeps a sentence with multiple valid tags and strips all of them', () => {
    const result = parseGroundedAnswer('Both sources agree on this[S1][S2].', twoDocs);

    expect(result).toBe('Both sources agree on this.');
  });

  it('drops a sentence with no citation tag at all', () => {
    const result = parseGroundedAnswer('This claim has no source attached.', twoDocs);

    expect(result).toBeNull();
  });

  it('drops a sentence whose only tag is out of range (a hallucinated source)', () => {
    const result = parseGroundedAnswer('This cites a source that does not exist[S99].', twoDocs);

    expect(result).toBeNull();
  });

  it('drops a sentence whose tag is S0 (below the valid range)', () => {
    const result = parseGroundedAnswer('This cites source zero[S0].', twoDocs);

    expect(result).toBeNull();
  });

  it('keeps a sentence with a mix of valid and invalid tags', () => {
    const result = parseGroundedAnswer('Partially grounded claim[S1][S99].', twoDocs);

    expect(result).toBe('Partially grounded claim.');
  });

  it('keeps only the grounded sentences out of a multi-sentence answer', () => {
    const raw = 'Grounded claim one[S1]. Ungrounded claim with no tag. Grounded claim two[S2].';

    const result = parseGroundedAnswer(raw, twoDocs);

    expect(result).toBe('Grounded claim one. Grounded claim two.');
  });

  it('returns null when every sentence is ungrounded', () => {
    const raw = 'First ungrounded claim. Second ungrounded claim.';

    const result = parseGroundedAnswer(raw, twoDocs);

    expect(result).toBeNull();
  });

  it('returns null for an empty response', () => {
    const result = parseGroundedAnswer('', twoDocs);

    expect(result).toBeNull();
  });

  it('collapses whitespace left behind after stripping a tag mid-sentence', () => {
    const result = parseGroundedAnswer('Exercise [S1] helps recovery[S1].', twoDocs);

    expect(result).toBe('Exercise helps recovery.');
  });

  it('treats a single retrieved document as a valid S1-only range', () => {
    const oneDoc = [doc()];

    expect(parseGroundedAnswer('Grounded claim[S1].', oneDoc)).toBe('Grounded claim.');
    expect(parseGroundedAnswer('Hallucinated claim[S2].', oneDoc)).toBeNull();
  });
});
