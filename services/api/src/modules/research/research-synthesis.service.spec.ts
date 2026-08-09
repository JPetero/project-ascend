import { ResearchQueryPlannerService } from './research-query-planner.service';
import { ResearchSynthesisService } from './research-synthesis.service';
import { EvidenceCategoryDto, EvidenceQualityDto, ResearchDocumentResult } from './research.types';
import { ResearchProvider } from './providers/research-provider.interface';

function doc(overrides: Partial<ResearchDocumentResult> = {}): ResearchDocumentResult {
  return {
    sourceId: 'https://pubmed.ncbi.nlm.nih.gov/1',
    title: 'A study',
    url: 'https://pubmed.ncbi.nlm.nih.gov/1',
    publisher: 'PubMed',
    evidenceCategory: EvidenceCategoryDto.PEER_REVIEWED,
    evidenceQuality: EvidenceQualityDto.HIGH,
    excerpt: 'Evidence supports X.',
    ...overrides,
  };
}

function buildService(fetchDocumentsImpl: (query: string) => Promise<ResearchDocumentResult[]>) {
  const provider: ResearchProvider = {
    isConfigured: true,
    fetchDocuments: jest.fn(fetchDocumentsImpl),
  };
  const service = new ResearchSynthesisService(provider, new ResearchQueryPlannerService());
  return { service, provider };
}

describe('ResearchSynthesisService', () => {
  it('propagates the provider not-configured rejection rather than swallowing it', async () => {
    const provider: ResearchProvider = {
      isConfigured: false,
      fetchDocuments: jest.fn().mockRejectedValue(new Error('not configured')),
    };
    const service = new ResearchSynthesisService(provider, new ResearchQueryPlannerService());

    await expect(service.answer('creatine')).rejects.toThrow('not configured');
  });

  it('honestly reports no verified sources when the provider finds nothing citable', async () => {
    const { service } = buildService(async () => []);

    const answer = await service.answer('made up question');

    expect(answer.sources).toEqual([]);
    expect(answer.citations).toEqual([]);
    expect(answer.conciseAnswer).toContain('No verified, source-backed information');
  });

  it('dedupes the same source returned by multiple planned sub-queries', async () => {
    const shared = doc();
    const { service, provider } = buildService(async () => [shared]);

    const answer = await service.answer('is creatine safe');

    // Planner expands "is creatine safe" into 2 sub-queries — both return
    // the same document, but it must appear once.
    expect(provider.fetchDocuments).toHaveBeenCalledTimes(2);
    expect(answer.sources).toHaveLength(1);
  });

  it('ranks stronger evidence categories first and bases the concise answer on the strongest source', async () => {
    const weak = doc({
      sourceId: 'https://mayoclinic.org/a',
      url: 'https://mayoclinic.org/a',
      publisher: 'Mayo Clinic',
      evidenceCategory: EvidenceCategoryDto.HEALTH_SYSTEM,
      evidenceQuality: EvidenceQualityDto.LOW,
      excerpt: 'General guidance from a health system.',
    });
    const strong = doc({
      sourceId: 'https://nih.gov/b',
      url: 'https://nih.gov/b',
      publisher: 'National Institutes of Health',
      evidenceCategory: EvidenceCategoryDto.GOVERNMENT,
      evidenceQuality: EvidenceQualityDto.HIGH,
      excerpt: 'Government guidance on the topic.',
    });
    const { service } = buildService(async () => [weak, strong]);

    const answer = await service.answer('shin splints treatment guidelines');

    expect(answer.sources[0].sourceId).toBe(strong.sourceId);
    expect(answer.conciseAnswer).toBe(strong.excerpt);
  });

  it('flags uncertainty when only one source was found', async () => {
    const { service } = buildService(async () => [doc()]);

    const answer = await service.answer('shin splints treatment guidelines');

    expect(answer.uncertaintyNote).toContain('Only one verified source');
  });

  it('flags uncertainty when no source is at least HIGH quality', async () => {
    const weakOnly = doc({
      evidenceCategory: EvidenceCategoryDto.HEALTH_SYSTEM,
      evidenceQuality: EvidenceQualityDto.LOW,
    });
    const weakOnly2 = doc({
      sourceId: 'https://mayoclinic.org/x',
      url: 'https://mayoclinic.org/x',
      evidenceCategory: EvidenceCategoryDto.HEALTH_SYSTEM,
      evidenceQuality: EvidenceQualityDto.LOW,
    });
    const { service } = buildService(async () => [weakOnly, weakOnly2]);

    const answer = await service.answer('shin splints treatment guidelines');

    expect(answer.uncertaintyNote).toContain('No peer-reviewed research or government');
  });

  it('never flags uncertainty when at least two sources exist and one is HIGH quality', async () => {
    const strong = doc();
    const moderate = doc({
      sourceId: 'https://acsm.org/y',
      url: 'https://acsm.org/y',
      evidenceCategory: EvidenceCategoryDto.PROFESSIONAL_ORGANIZATION,
      evidenceQuality: EvidenceQualityDto.MODERATE,
    });
    const { service } = buildService(async () => [strong, moderate]);

    const answer = await service.answer('shin splints treatment guidelines');

    expect(answer.uncertaintyNote).toBeUndefined();
  });

  it('surfaces a literal contradictory-evidence excerpt rather than inventing a judgment call', async () => {
    const conflicted = doc({
      excerpt: 'Current studies show conflicting results and more research is needed.',
    });
    const { service } = buildService(async () => [conflicted]);

    const answer = await service.answer('shin splints treatment guidelines');

    expect(answer.contradictoryEvidenceNote).toContain('conflicting results');
    expect(answer.contradictoryEvidenceNote).toContain(conflicted.publisher);
  });

  it('never surfaces a contradictory-evidence note when no source hedges', async () => {
    const { service } = buildService(async () => [doc()]);

    const answer = await service.answer('shin splints treatment guidelines');

    expect(answer.contradictoryEvidenceNote).toBeUndefined();
  });

  it('strips a citation whose sourceId does not match any retrieved document — the hard "never cite an unretrieved source" boundary', async () => {
    const { service } = buildService(async () => [doc()]);

    const answer = await service.answer('shin splints treatment guidelines');
    expect(answer.citations.map((c) => c.sourceId)).toEqual([doc().sourceId]);

    // Exercises the private validation boundary directly with a rogue
    // citation a hypothetical future generative synthesizer might
    // produce — proves it never survives, regardless of how it arrived.
    const rogue = { sourceId: 'https://not-a-real-source.example.com', quote: 'invented' };
    const validated = (
      service as unknown as {
        validateCitations: (
          citations: { sourceId: string; quote: string }[],
          documents: ResearchDocumentResult[],
        ) => { sourceId: string; quote: string }[];
      }
    ).validateCitations([rogue, ...answer.citations], answer.sources);

    expect(validated).toEqual(answer.citations);
    expect(validated.some((c) => c.sourceId === rogue.sourceId)).toBe(false);
  });
});
