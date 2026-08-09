import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EvidenceCategoryDto, EvidenceQualityDto } from '../research.types';
import { BraveSearchResearchProvider } from './brave-search-research-provider';

function configServiceWith(braveSearchApiKey: string | undefined): ConfigService {
  return { get: () => ({ braveSearchApiKey }) } as unknown as ConfigService;
}

describe('BraveSearchResearchProvider', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('honestly rejects instead of fabricating a citation-backed answer when no API key is configured', async () => {
    const provider = new BraveSearchResearchProvider(configServiceWith(undefined));

    expect(provider.isConfigured).toBe(false);
    await expect(provider.fetchDocuments('shin splints')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('reports configured when an API key is present, without making a network call', () => {
    const fetchSpy = jest.spyOn(global, 'fetch');
    const provider = new BraveSearchResearchProvider(configServiceWith('test-key'));

    expect(provider.isConfigured).toBe(true);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('keeps only results from trusted evidence categories, classifies each correctly, and never invents a source', async () => {
    const provider = new BraveSearchResearchProvider(configServiceWith('test-key'));
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        web: {
          results: [
            {
              title: 'Achilles tendinopathy: a systematic review',
              url: 'https://pubmed.ncbi.nlm.nih.gov/12345678/',
              description: 'A meta-analysis of eccentric loading protocols.',
              page_age: '2022-03-01T00:00:00.000Z',
            },
            {
              title: 'Shin splints overview',
              url: 'https://www.mayoclinic.org/diseases-conditions/shin-splints',
              description: 'Symptoms, causes, and treatment.',
            },
            {
              title: 'Exercise guidance for shin pain',
              url: 'https://www.nhs.uk/conditions/shin-splints/',
              description: 'NHS guidance on shin splints.',
            },
            {
              title: 'What are shin splints?',
              url: 'https://www.healthline.com/health/shin-splints',
              description: 'A general-audience explainer.',
            },
            {
              title: 'Some running blog post',
              url: 'https://www.example-running-blog.com/shin-splints',
              description: "One runner's personal experience.",
            },
          ],
        },
      }),
    } as unknown as Response);

    const documents = await provider.fetchDocuments('shin splints');

    expect(documents).toHaveLength(3);
    expect(documents.map((d) => d.evidenceCategory)).toEqual([
      EvidenceCategoryDto.PEER_REVIEWED,
      EvidenceCategoryDto.HEALTH_SYSTEM,
      EvidenceCategoryDto.GOVERNMENT,
    ]);
    expect(documents.map((d) => d.evidenceQuality)).toEqual([
      EvidenceQualityDto.HIGH,
      EvidenceQualityDto.LOW,
      EvidenceQualityDto.HIGH,
    ]);
    expect(documents.every((d) => d.url.startsWith('https://'))).toBe(true);
    expect(documents.every((d) => d.sourceId === d.url)).toBe(true);
    expect(documents[0].publisher).toBe('PubMed');
    expect(documents[0].publicationYear).toBe(2022);
    expect(documents[1].publicationYear).toBeUndefined();
    // Neither the un-trusted health publisher nor the personal blog is
    // ever surfaced, at any evidence tier.
    expect(documents.some((d) => d.url.includes('healthline'))).toBe(false);
    expect(documents.some((d) => d.url.includes('example-running-blog'))).toBe(false);
  });

  it('classifies international government and university TLDs, not just US-centric hosts', async () => {
    const provider = new BraveSearchResearchProvider(configServiceWith('test-key'));
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        web: {
          results: [
            {
              title: 'Physical activity guidelines',
              url: 'https://www.health.gov.au/topics/physical-activity',
              description: 'Australian government physical activity guidance.',
            },
            {
              title: 'Sports medicine research',
              url: 'https://www.some-university.ac.uk/research/sports-medicine',
              description: 'A UK university research summary.',
            },
          ],
        },
      }),
    } as unknown as Response);

    const documents = await provider.fetchDocuments('physical activity guidelines');

    expect(documents.map((d) => d.evidenceCategory)).toEqual([
      EvidenceCategoryDto.GOVERNMENT,
      EvidenceCategoryDto.UNIVERSITY,
    ]);
  });

  it('honestly reports no verified sources rather than fabricating one when nothing trusted matches', async () => {
    const provider = new BraveSearchResearchProvider(configServiceWith('test-key'));
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        web: {
          results: [{ title: 'Random forum post', url: 'https://forum.example.com/thread/1' }],
        },
      }),
    } as unknown as Response);

    const documents = await provider.fetchDocuments('made up query');

    expect(documents).toEqual([]);
  });

  it('rejects with a service-unavailable error when Brave Search itself fails', async () => {
    const provider = new BraveSearchResearchProvider(configServiceWith('test-key'));
    jest.spyOn(global, 'fetch').mockResolvedValue({ ok: false, status: 500 } as Response);

    await expect(provider.fetchDocuments('shin splints')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
