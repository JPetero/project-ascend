import { ForbiddenException } from '@nestjs/common';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { ResearchController } from './research.controller';
import { ResearchProvider } from './providers/research-provider.interface';

function fakeUser(): AuthenticatedUser {
  return { id: 'user-1', email: 'ada@example.com' } as AuthenticatedUser;
}

describe('ResearchController', () => {
  it('rejects a query from a user without ADVANCED_AI_CONVERSATIONS instead of ever calling the provider', async () => {
    const capabilityService = {
      hasCapabilityForUser: jest.fn().mockResolvedValue(false),
    } as unknown as CapabilityService;
    const provider: ResearchProvider = { isConfigured: true, search: jest.fn() };
    const controller = new ResearchController(capabilityService, provider);

    await expect(controller.query(fakeUser(), { query: 'shin splints' })).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(provider.search).not.toHaveBeenCalled();
  });

  it('delegates to the provider once ADVANCED_AI_CONVERSATIONS is confirmed', async () => {
    const capabilityService = {
      hasCapabilityForUser: jest.fn().mockResolvedValue(true),
    } as unknown as CapabilityService;
    const search = jest
      .fn()
      .mockResolvedValue({ summary: 'Found 1 verified source.', sources: [] });
    const provider: ResearchProvider = { isConfigured: true, search };
    const controller = new ResearchController(capabilityService, provider);

    const result = await controller.query(fakeUser(), { query: 'shin splints' });

    expect(search).toHaveBeenCalledWith('shin splints');
    expect(result).toEqual({ summary: 'Found 1 verified source.', sources: [] });
  });
});
