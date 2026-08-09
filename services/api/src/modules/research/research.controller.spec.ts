import { ForbiddenException } from '@nestjs/common';
import { AiEntitlementService } from '../../common/entitlements/ai-entitlement.service';
import { AiFeature } from '../../common/entitlements/ai-entitlement.types';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { ResearchController } from './research.controller';
import { ResearchProvider } from './providers/research-provider.interface';

function fakeUser(): AuthenticatedUser {
  return { id: 'user-1', email: 'ada@example.com' } as AuthenticatedUser;
}

describe('ResearchController', () => {
  it('rejects a query from a user without RESEARCH access instead of ever calling the provider', async () => {
    const entitlement = {
      checkAccess: jest
        .fn()
        .mockResolvedValue({ allowed: false, feature: AiFeature.RESEARCH, reason: 'nope' }),
    } as unknown as AiEntitlementService;
    const provider: ResearchProvider = { isConfigured: true, search: jest.fn() };
    const controller = new ResearchController(entitlement, provider);

    await expect(controller.query(fakeUser(), { query: 'shin splints' })).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(provider.search).not.toHaveBeenCalled();
  });

  it('checks access for AiFeature.RESEARCH specifically', async () => {
    const checkAccess = jest.fn().mockResolvedValue({ allowed: true, feature: AiFeature.RESEARCH });
    const entitlement = { checkAccess } as unknown as AiEntitlementService;
    const provider: ResearchProvider = {
      isConfigured: true,
      search: jest.fn().mockResolvedValue({}),
    };
    const controller = new ResearchController(entitlement, provider);

    await controller.query(fakeUser(), { query: 'shin splints' });

    expect(checkAccess).toHaveBeenCalledWith('user-1', AiFeature.RESEARCH);
  });

  it('delegates to the provider once access is confirmed', async () => {
    const entitlement = {
      checkAccess: jest.fn().mockResolvedValue({ allowed: true, feature: AiFeature.RESEARCH }),
    } as unknown as AiEntitlementService;
    const search = jest
      .fn()
      .mockResolvedValue({ summary: 'Found 1 verified source.', sources: [] });
    const provider: ResearchProvider = { isConfigured: true, search };
    const controller = new ResearchController(entitlement, provider);

    const result = await controller.query(fakeUser(), { query: 'shin splints' });

    expect(search).toHaveBeenCalledWith('shin splints');
    expect(result).toEqual({ summary: 'Found 1 verified source.', sources: [] });
  });
});
