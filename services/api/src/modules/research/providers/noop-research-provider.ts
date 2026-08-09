import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ResearchAnswerResult } from '../research.types';
import { ResearchProvider } from './research-provider.interface';

/**
 * The default provider whenever `BRAVE_SEARCH_API_KEY` is unset — honestly
 * rejects rather than fabricating a citation-backed answer. No live key
 * exists in this environment, so this is what every test in this
 * repository runs against by default, mirroring NoopPushNotificationProvider.
 */
@Injectable()
export class NoopResearchProvider implements ResearchProvider {
  get isConfigured(): boolean {
    return false;
  }

  async search(): Promise<ResearchAnswerResult> {
    throw new ServiceUnavailableException(
      'Research mode is not configured. Set BRAVE_SEARCH_API_KEY to enable it.',
    );
  }
}
