import { ForbiddenException } from '@nestjs/common';
import { AiEntitlementService } from '../../common/entitlements/ai-entitlement.service';
import { AiFeature } from '../../common/entitlements/ai-entitlement.types';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { ResearchController } from './research.controller';
import { ResearchSynthesisService } from './research-synthesis.service';

function fakeUser(): AuthenticatedUser {
  return { id: 'user-1', email: 'ada@example.com' } as AuthenticatedUser;
}

describe('ResearchController', () => {
  it('rejects a query from a user without RESEARCH access instead of ever calling the synthesis pipeline', async () => {
    const entitlement = {
      checkAccess: jest
        .fn()
        .mockResolvedValue({ allowed: false, feature: AiFeature.RESEARCH, reason: 'nope' }),
    } as unknown as AiEntitlementService;
    const synthesis = { answer: jest.fn() } as unknown as ResearchSynthesisService;
    const controller = new ResearchController(entitlement, synthesis);

    await expect(controller.query(fakeUser(), { query: 'shin splints' })).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(synthesis.answer).not.toHaveBeenCalled();
  });

  it('checks access for AiFeature.RESEARCH specifically', async () => {
    const checkAccess = jest.fn().mockResolvedValue({ allowed: true, feature: AiFeature.RESEARCH });
    const entitlement = { checkAccess } as unknown as AiEntitlementService;
    const synthesis = {
      answer: jest.fn().mockResolvedValue({}),
    } as unknown as ResearchSynthesisService;
    const controller = new ResearchController(entitlement, synthesis);

    await controller.query(fakeUser(), { query: 'shin splints' });

    expect(checkAccess).toHaveBeenCalledWith('user-1', AiFeature.RESEARCH);
  });

  it('delegates to the synthesis pipeline once access is confirmed', async () => {
    const entitlement = {
      checkAccess: jest.fn().mockResolvedValue({ allowed: true, feature: AiFeature.RESEARCH }),
    } as unknown as AiEntitlementService;
    const answer = jest.fn().mockResolvedValue({
      query: 'shin splints',
      conciseAnswer: 'Found 1 verified source.',
      deeperExplanation: '',
      citations: [],
      sources: [],
    });
    const synthesis = { answer } as unknown as ResearchSynthesisService;
    const controller = new ResearchController(entitlement, synthesis);

    const result = await controller.query(fakeUser(), { query: 'shin splints' });

    expect(answer).toHaveBeenCalledWith('shin splints');
    expect(result).toEqual({
      query: 'shin splints',
      conciseAnswer: 'Found 1 verified source.',
      deeperExplanation: '',
      citations: [],
      sources: [],
    });
  });
});
