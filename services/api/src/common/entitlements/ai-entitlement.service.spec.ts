import { AiEntitlementService } from './ai-entitlement.service';
import { AiFeature } from './ai-entitlement.types';
import { AppCapability } from './capability.util';
import { CapabilityService } from './capability.service';

function buildService(hasCapabilityForUser: jest.Mock) {
  const capabilityService = { hasCapabilityForUser } as unknown as CapabilityService;
  return new AiEntitlementService(capabilityService);
}

describe('AiEntitlementService', () => {
  it('always allows ESSENTIAL_SAFETY without consulting CapabilityService at all', async () => {
    const hasCapabilityForUser = jest.fn();
    const service = buildService(hasCapabilityForUser);

    const decision = await service.checkAccess('user-1', AiFeature.ESSENTIAL_SAFETY);

    expect(decision).toEqual({ allowed: true, feature: AiFeature.ESSENTIAL_SAFETY });
    expect(hasCapabilityForUser).not.toHaveBeenCalled();
  });

  it('always allows BASIC_COACHING without consulting CapabilityService at all', async () => {
    const hasCapabilityForUser = jest.fn();
    const service = buildService(hasCapabilityForUser);

    const decision = await service.checkAccess('user-1', AiFeature.BASIC_COACHING);

    expect(decision.allowed).toBe(true);
    expect(hasCapabilityForUser).not.toHaveBeenCalled();
  });

  it('denies ADVANCED_CONVERSATION for a Free account and never invokes anything provider-cost-incurring itself', async () => {
    const hasCapabilityForUser = jest.fn().mockResolvedValue(false);
    const service = buildService(hasCapabilityForUser);

    const decision = await service.checkAccess('user-1', AiFeature.ADVANCED_CONVERSATION);

    expect(decision).toEqual({
      allowed: false,
      feature: AiFeature.ADVANCED_CONVERSATION,
      reason: 'This requires Ascend Premium.',
    });
    expect(hasCapabilityForUser).toHaveBeenCalledWith(
      'user-1',
      AppCapability.ADVANCED_AI_CONVERSATIONS,
    );
  });

  it('allows ADVANCED_CONVERSATION for a Premium account', async () => {
    const hasCapabilityForUser = jest.fn().mockResolvedValue(true);
    const service = buildService(hasCapabilityForUser);

    const decision = await service.checkAccess('user-1', AiFeature.ADVANCED_CONVERSATION);

    expect(decision).toEqual({ allowed: true, feature: AiFeature.ADVANCED_CONVERSATION });
  });

  it('checks RESEARCH against the same capability as ADVANCED_CONVERSATION', async () => {
    const hasCapabilityForUser = jest.fn().mockResolvedValue(false);
    const service = buildService(hasCapabilityForUser);

    await service.checkAccess('user-1', AiFeature.RESEARCH);

    expect(hasCapabilityForUser).toHaveBeenCalledWith(
      'user-1',
      AppCapability.ADVANCED_AI_CONVERSATIONS,
    );
  });

  it('checks VOICE_ADVANCED against PREMIUM_COMPANION_VOICES, not ADVANCED_AI_CONVERSATIONS', async () => {
    const hasCapabilityForUser = jest.fn().mockResolvedValue(false);
    const service = buildService(hasCapabilityForUser);

    await service.checkAccess('user-1', AiFeature.VOICE_ADVANCED);

    expect(hasCapabilityForUser).toHaveBeenCalledWith(
      'user-1',
      AppCapability.PREMIUM_COMPANION_VOICES,
    );
  });
});
