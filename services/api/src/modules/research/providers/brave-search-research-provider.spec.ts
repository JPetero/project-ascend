import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EvidenceQualityDto } from '../research.types';
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
    await expect(provider.search('shin splints')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('reports configured when an API key is present, without making a network call', () => {
    const fetchSpy = jest.spyOn(global, 'fetch');
    const provider = new BraveSearchResearchProvider(configServiceWith('test-key'));

    expect(provider.isConfigured).toBe(true);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('keeps only results from trusted domain tiers, classifies each correctly, and never invents a source', async () => {
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

    const answer = await provider.search('shin splints');

    expect(answer.sources).toHaveLength(3);
    expect(answer.sources.map((s) => s.evidenceQuality)).toEqual([
      EvidenceQualityDto.HIGH,
      EvidenceQualityDto.MODERATE,
      EvidenceQualityDto.LOW,
    ]);
    expect(answer.sources.every((s) => s.url.startsWith('https://'))).toBe(true);
    expect(answer.sources[0].publicationYear).toBe(2022);
    expect(answer.sources[1].publicationYear).toBeUndefined();
    expect(answer.summary).toContain('3 verified sources');
    // The untrusted blog is never surfaced, at any evidence tier.
    expect(answer.sources.some((s) => s.url.includes('example-running-blog'))).toBe(false);
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

    const answer = await provider.search('made up query');

    expect(answer.sources).toEqual([]);
    expect(answer.summary).toContain('No verified, source-backed information');
  });

  it('rejects with a service-unavailable error when Brave Search itself fails', async () => {
    const provider = new BraveSearchResearchProvider(configServiceWith('test-key'));
    jest.spyOn(global, 'fetch').mockResolvedValue({ ok: false, status: 500 } as Response);

    await expect(provider.search('shin splints')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
