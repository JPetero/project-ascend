import { ForbiddenException } from '@nestjs/common';
import { AiEntitlementService } from '../../common/entitlements/ai-entitlement.service';
import { AiFeature } from '../../common/entitlements/ai-entitlement.types';
import { AssistantSafetyService } from './assistant-safety.service';
import { AssistantSafetyCategory, AssistantSafetyDecisionType } from './assistant-safety.types';
import { AssistantService } from './assistant.service';
import { CompanionMemoryService } from './companion-memory.service';
import { AiReplyProvider } from './providers/ai-reply-provider.interface';
import { CoachingStyleDto, CompanionDto } from './assistant.types';
import { PrismaService } from '../../prisma/prisma.service';

function buildService(options?: {
  provider?: Partial<AiReplyProvider>;
  aiMemoryEnabled?: boolean | null;
  memoryNotes?: string[];
  remember?: jest.Mock;
  classify?: jest.Mock;
  normalizeOutput?: jest.Mock;
  checkAccess?: jest.Mock;
}) {
  const generateReply = jest.fn().mockResolvedValue('Nice work today!');
  const provider: AiReplyProvider = {
    isConfigured: true,
    generateReply,
    ...options?.provider,
  };
  const prisma = {
    preference: {
      findUnique: jest
        .fn()
        .mockResolvedValue(
          options?.aiMemoryEnabled === null
            ? null
            : { aiMemoryEnabled: options?.aiMemoryEnabled ?? true },
        ),
    },
  } as unknown as PrismaService;
  const getNotes = jest.fn().mockResolvedValue(options?.memoryNotes ?? []);
  const remember = options?.remember ?? jest.fn().mockResolvedValue(undefined);
  const clear = jest.fn().mockResolvedValue(undefined);
  const memory = { getNotes, remember, clear } as unknown as CompanionMemoryService;

  const classify =
    options?.classify ??
    jest.fn().mockReturnValue({
      category: AssistantSafetyCategory.GENERAL,
      decision: AssistantSafetyDecisionType.ALLOW_PROVIDER,
    });
  const normalizeOutput = options?.normalizeOutput ?? jest.fn((reply: string) => reply);
  const safety = { classify, normalizeOutput } as unknown as AssistantSafetyService;

  const checkAccess =
    options?.checkAccess ??
    jest.fn().mockResolvedValue({ allowed: true, feature: AiFeature.ADVANCED_CONVERSATION });
  const entitlement = { checkAccess } as unknown as AiEntitlementService;

  const service = new AssistantService(provider, prisma, memory, safety, entitlement);
  return {
    service,
    generateReply,
    prisma,
    getNotes,
    remember,
    clear,
    classify,
    normalizeOutput,
    checkAccess,
  };
}

const dto = {
  input: 'plan my workout',
  companion: CompanionDto.ATLAS,
  style: CoachingStyleDto.BALANCED,
};

describe('AssistantService', () => {
  it('delegates isConfigured to whichever AiReplyProvider was injected', () => {
    const { service } = buildService({ provider: { isConfigured: true } });
    expect(service.isConfigured).toBe(true);
  });

  it('reports not configured when the injected provider is not', () => {
    const { service } = buildService({ provider: { isConfigured: false } });
    expect(service.isConfigured).toBe(false);
  });

  it('reply() passes the dto and current memory notes to the provider and returns its normalized result', async () => {
    const { service, generateReply, normalizeOutput } = buildService({
      memoryNotes: ['Training for a 10k.'],
    });

    const reply = await service.reply(dto, 'user-1');

    expect(generateReply).toHaveBeenCalledWith(dto, ['Training for a 10k.'], undefined);
    expect(normalizeOutput).toHaveBeenCalledWith('Nice work today!');
    expect(reply).toBe('Nice work today!');
  });

  it('records the input as a new memory note after a successful reply when memory is enabled', async () => {
    const { service, remember } = buildService({ aiMemoryEnabled: true });

    await service.reply(dto, 'user-1');

    expect(remember).toHaveBeenCalledWith('user-1', dto.input);
  });

  it('never reads or writes memory when aiMemoryEnabled is false', async () => {
    const { service, generateReply, getNotes, remember } = buildService({
      aiMemoryEnabled: false,
    });

    await service.reply(dto, 'user-1');

    expect(getNotes).not.toHaveBeenCalled();
    expect(remember).not.toHaveBeenCalled();
    expect(generateReply).toHaveBeenCalledWith(dto, [], undefined);
  });

  it('treats a missing Preference row as memory enabled, matching the schema default', async () => {
    const { service, remember } = buildService({ aiMemoryEnabled: null });

    await service.reply(dto, 'user-1');

    expect(remember).toHaveBeenCalledWith('user-1', dto.input);
  });

  it('a failed memory write never fails the reply itself', async () => {
    const { service } = buildService({
      aiMemoryEnabled: true,
      remember: jest.fn().mockRejectedValue(new Error('db down')),
    });

    await expect(service.reply(dto, 'user-1')).resolves.toBe('Nice work today!');
  });

  it('getMemory() delegates to CompanionMemoryService.getNotes', async () => {
    const { service, getNotes } = buildService({ memoryNotes: ['a fact'] });

    await expect(service.getMemory('user-1')).resolves.toEqual(['a fact']);
    expect(getNotes).toHaveBeenCalledWith('user-1');
  });

  it('clearMemory() delegates to CompanionMemoryService.clear', async () => {
    const { service, clear } = buildService();

    await service.clearMemory('user-1');

    expect(clear).toHaveBeenCalledWith('user-1');
  });

  // Build Session 11 Parts 1-2 — server-side entitlement + safety gate.
  describe('safety gate', () => {
    it('returns the local response directly and never touches the provider or entitlement check when the safety classifier short-circuits', async () => {
      const classify = jest.fn().mockReturnValue({
        category: AssistantSafetyCategory.MEDICAL_RED_FLAG,
        decision: AssistantSafetyDecisionType.ESCALATE,
        localResponse: 'Please seek medical attention right now.',
      });
      const { service, generateReply, checkAccess } = buildService({ classify });

      const reply = await service.reply(dto, 'user-1');

      expect(reply).toBe('Please seek medical attention right now.');
      expect(generateReply).not.toHaveBeenCalled();
      expect(checkAccess).not.toHaveBeenCalled();
    });

    it('a local safe response is returned even when this account has no Premium entitlement', async () => {
      const classify = jest.fn().mockReturnValue({
        category: AssistantSafetyCategory.EATING_DISORDER_RISK,
        decision: AssistantSafetyDecisionType.LOCAL_SAFE_RESPONSE,
        localResponse: 'Safe redirect content.',
      });
      const checkAccess = jest
        .fn()
        .mockResolvedValue({ allowed: false, feature: AiFeature.ADVANCED_CONVERSATION });
      const { service } = buildService({ classify, checkAccess });

      await expect(service.reply(dto, 'user-1')).resolves.toBe('Safe redirect content.');
    });

    it('passes safetyContext to the provider only for ALLOW_WITH_SAFETY_CONTEXT', async () => {
      const classify = jest.fn().mockReturnValue({
        category: AssistantSafetyCategory.OVERTRAINING,
        decision: AssistantSafetyDecisionType.ALLOW_WITH_SAFETY_CONTEXT,
        safetyContext: 'Frame the reply around rest and recovery.',
      });
      const { service, generateReply } = buildService({ classify });

      await service.reply(dto, 'user-1');

      expect(generateReply).toHaveBeenCalledWith(
        dto,
        [],
        'Frame the reply around rest and recovery.',
      );
    });

    it('runs the provider output through normalizeOutput before returning it', async () => {
      const normalizeOutput = jest.fn().mockReturnValue('normalized');
      const { service } = buildService({ normalizeOutput });

      await expect(service.reply(dto, 'user-1')).resolves.toBe('normalized');
    });
  });

  describe('entitlement gate', () => {
    it('rejects with ForbiddenException and never calls the provider when the account lacks the ADVANCED_CONVERSATION feature', async () => {
      const checkAccess = jest.fn().mockResolvedValue({
        allowed: false,
        feature: AiFeature.ADVANCED_CONVERSATION,
        reason: 'This requires Ascend Premium.',
      });
      const { service, generateReply } = buildService({ checkAccess });

      await expect(service.reply(dto, 'user-1')).rejects.toBeInstanceOf(ForbiddenException);
      expect(generateReply).not.toHaveBeenCalled();
    });

    it('checks access for AiFeature.ADVANCED_CONVERSATION on every allowed-by-safety turn', async () => {
      const { service, checkAccess } = buildService();

      await service.reply(dto, 'user-1');

      expect(checkAccess).toHaveBeenCalledWith('user-1', AiFeature.ADVANCED_CONVERSATION);
    });
  });
});
