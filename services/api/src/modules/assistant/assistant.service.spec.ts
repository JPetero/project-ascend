import { ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiEntitlementService } from '../../common/entitlements/ai-entitlement.service';
import { AiFeature } from '../../common/entitlements/ai-entitlement.types';
import { AiProviderCircuitBreaker } from './ai-provider-circuit-breaker.service';
import { AiReplyProviderRouter } from './ai-reply-provider-router';
import { AiUsagePolicy } from './ai-usage-policy.service';
import { AssistantSafetyService } from './assistant-safety.service';
import { AssistantSafetyCategory, AssistantSafetyDecisionType } from './assistant-safety.types';
import { AssistantService } from './assistant.service';
import { CompanionMemoryService } from './companion-memory.service';
import { MemoryExtractionService } from './memory-extraction.service';
import { CompanionMemoryCategory } from './memory-extraction.types';
import { AiReplyProvider } from './providers/ai-reply-provider.interface';
import { AnthropicReplyProvider } from './providers/anthropic-reply-provider';
import { GeminiReplyProvider } from './providers/gemini-reply-provider';
import { OpenAiReplyProvider } from './providers/openai-reply-provider';
import { CoachingStyleDto, CompanionDto } from './assistant.types';
import { PrismaService } from '../../prisma/prisma.service';

function buildService(options?: {
  provider?: Partial<AiReplyProvider>;
  aiMemoryEnabled?: boolean | null;
  memoryNotes?: { id: string; category: CompanionMemoryCategory; value: string; createdAt: Date }[];
  remember?: jest.Mock;
  classify?: jest.Mock;
  normalizeOutput?: jest.Mock;
  checkAccess?: jest.Mock;
  extractCandidate?: jest.Mock;
  checkWithinLimit?: jest.Mock;
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
  const deleteNote = jest.fn().mockResolvedValue(undefined);
  const clear = jest.fn().mockResolvedValue(undefined);
  const memory = { getNotes, remember, deleteNote, clear } as unknown as CompanionMemoryService;

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

  const extractCandidate = options?.extractCandidate ?? jest.fn().mockReturnValue(null);
  const extraction = { extractCandidate } as unknown as MemoryExtractionService;

  const checkWithinLimit =
    options?.checkWithinLimit ??
    jest.fn().mockResolvedValue({
      allowed: true,
      window: { windowStart: new Date(), count: 0, limit: 200 },
    });
  const record = jest.fn().mockResolvedValue(undefined);
  const usagePolicy = { checkWithinLimit, record } as unknown as AiUsagePolicy;

  const service = new AssistantService(
    provider,
    prisma,
    memory,
    safety,
    entitlement,
    extraction,
    usagePolicy,
  );
  return {
    service,
    generateReply,
    prisma,
    getNotes,
    remember,
    deleteNote,
    clear,
    classify,
    normalizeOutput,
    checkAccess,
    extractCandidate,
    checkWithinLimit,
    record,
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

  it('reply() passes the dto and current memory note values to the provider and returns its normalized result', async () => {
    const { service, generateReply, normalizeOutput } = buildService({
      memoryNotes: [
        {
          id: 'n1',
          category: CompanionMemoryCategory.GOAL,
          value: 'Training for a 10k.',
          createdAt: new Date(),
        },
      ],
    });

    const result = await service.reply(dto, 'user-1');

    expect(generateReply).toHaveBeenCalledWith(dto, ['Training for a 10k.'], undefined);
    expect(normalizeOutput).toHaveBeenCalledWith('Nice work today!');
    expect(result.reply).toBe('Nice work today!');
  });

  it('never reads or writes memory when aiMemoryEnabled is false', async () => {
    const { service, generateReply, getNotes, remember, extractCandidate } = buildService({
      aiMemoryEnabled: false,
    });

    await service.reply(dto, 'user-1');

    expect(getNotes).not.toHaveBeenCalled();
    expect(extractCandidate).not.toHaveBeenCalled();
    expect(remember).not.toHaveBeenCalled();
    expect(generateReply).toHaveBeenCalledWith(dto, [], undefined);
  });

  it('treats a missing Preference row as memory DISABLED, matching the new opt-in schema default (Build Session 11 Part 4)', async () => {
    const { service, remember } = buildService({ aiMemoryEnabled: null });

    await service.reply(dto, 'user-1');

    expect(remember).not.toHaveBeenCalled();
  });

  it('getMemory() delegates to CompanionMemoryService.getNotes', async () => {
    const notes = [
      { id: 'n1', category: CompanionMemoryCategory.GOAL, value: 'a fact', createdAt: new Date() },
    ];
    const { service, getNotes } = buildService({ memoryNotes: notes });

    await expect(service.getMemory('user-1')).resolves.toEqual(notes);
    expect(getNotes).toHaveBeenCalledWith('user-1');
  });

  it('deleteMemory() delegates to CompanionMemoryService.deleteNote', async () => {
    const { service, deleteNote } = buildService();

    await service.deleteMemory('user-1', 'note-1');

    expect(deleteNote).toHaveBeenCalledWith('user-1', 'note-1');
  });

  it('clearMemory() delegates to CompanionMemoryService.clear', async () => {
    const { service, clear } = buildService();

    await service.clearMemory('user-1');

    expect(clear).toHaveBeenCalledWith('user-1');
  });

  describe('structured memory extraction (Build Session 11 Part 4)', () => {
    it('saves the candidate MemoryExtractionService finds, when memory is enabled', async () => {
      const candidate = { category: CompanionMemoryCategory.GOAL, value: 'Goal: build strength.' };
      const extractCandidate = jest.fn().mockReturnValue(candidate);
      const { service, remember } = buildService({ aiMemoryEnabled: true, extractCandidate });

      await service.reply(dto, 'user-1');

      expect(remember).toHaveBeenCalledWith('user-1', candidate);
    });

    it('never calls remember when the extractor finds nothing to save', async () => {
      const { service, remember, extractCandidate } = buildService({ aiMemoryEnabled: true });

      await service.reply(dto, 'user-1');

      expect(extractCandidate).toHaveBeenCalledWith(dto.input, AssistantSafetyCategory.GENERAL);
      expect(remember).not.toHaveBeenCalled();
    });

    it('passes the classified safety category to the extractor, not a hardcoded one', async () => {
      const classify = jest.fn().mockReturnValue({
        category: AssistantSafetyCategory.NUTRITION,
        decision: AssistantSafetyDecisionType.ALLOW_PROVIDER,
      });
      const { service, extractCandidate } = buildService({ aiMemoryEnabled: true, classify });

      await service.reply(dto, 'user-1');

      expect(extractCandidate).toHaveBeenCalledWith(dto.input, AssistantSafetyCategory.NUTRITION);
    });

    it('a failed memory write never fails the reply itself', async () => {
      const candidate = { category: CompanionMemoryCategory.GOAL, value: 'Goal: build strength.' };
      const { service } = buildService({
        aiMemoryEnabled: true,
        extractCandidate: jest.fn().mockReturnValue(candidate),
        remember: jest.fn().mockRejectedValue(new Error('db down')),
      });

      await expect(service.reply(dto, 'user-1')).resolves.toEqual(
        expect.objectContaining({ reply: 'Nice work today!' }),
      );
    });
  });

  describe('sensitive memory confirmation (Build Session 12 Part 4)', () => {
    it('never auto-saves a SENSITIVE-category candidate, and surfaces it as pendingMemory instead', async () => {
      const candidate = {
        category: CompanionMemoryCategory.ACCESSIBILITY_PREFERENCE,
        value: 'Uses a wheelchair.',
      };
      const extractCandidate = jest.fn().mockReturnValue(candidate);
      const { service, remember } = buildService({ aiMemoryEnabled: true, extractCandidate });

      const result = await service.reply(dto, 'user-1');

      expect(remember).not.toHaveBeenCalled();
      expect(result.pendingMemory).toEqual(candidate);
    });

    it('still auto-saves a STANDARD-category candidate and never sets pendingMemory', async () => {
      const candidate = { category: CompanionMemoryCategory.GOAL, value: 'Goal: build strength.' };
      const extractCandidate = jest.fn().mockReturnValue(candidate);
      const { service, remember } = buildService({ aiMemoryEnabled: true, extractCandidate });

      const result = await service.reply(dto, 'user-1');

      expect(remember).toHaveBeenCalledWith('user-1', candidate);
      expect(result.pendingMemory).toBeUndefined();
    });

    it('confirmMemory saves the candidate via CompanionMemoryService.remember', async () => {
      const { service, remember } = buildService();
      const candidate = {
        category: CompanionMemoryCategory.DIETARY_RESTRICTION,
        value: 'Allergic to peanuts.',
      };

      await service.confirmMemory('user-1', candidate);

      expect(remember).toHaveBeenCalledWith('user-1', candidate);
    });
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

      const result = await service.reply(dto, 'user-1');

      expect(result.reply).toBe('Please seek medical attention right now.');
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

      await expect(service.reply(dto, 'user-1')).resolves.toEqual(
        expect.objectContaining({ reply: 'Safe redirect content.' }),
      );
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

      await expect(service.reply(dto, 'user-1')).resolves.toEqual(
        expect.objectContaining({ reply: 'normalized' }),
      );
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

  describe('fair-use ceiling (Build Session 12 Part 6)', () => {
    it('rejects with ForbiddenException and never calls the provider once the daily ceiling is reached', async () => {
      const checkWithinLimit = jest.fn().mockResolvedValue({
        allowed: false,
        window: { windowStart: new Date(), count: 200, limit: 200 },
      });
      const { service, generateReply } = buildService({ checkWithinLimit });

      await expect(service.reply(dto, 'user-1')).rejects.toBeInstanceOf(ForbiddenException);
      expect(generateReply).not.toHaveBeenCalled();
    });

    it('never mentions upgrading in the fair-use rejection — this applies to Premium accounts already paying', async () => {
      const checkWithinLimit = jest.fn().mockResolvedValue({
        allowed: false,
        window: { windowStart: new Date(), count: 200, limit: 200 },
      });
      const { service } = buildService({ checkWithinLimit });

      await expect(service.reply(dto, 'user-1')).rejects.toMatchObject({
        message: expect.not.stringMatching(/upgrade|subscribe/i),
      });
    });

    it('checks the fair-use ceiling for this specific user and feature', async () => {
      const { service, checkWithinLimit } = buildService();

      await service.reply(dto, 'user-1');

      expect(checkWithinLimit).toHaveBeenCalledWith('user-1', AiFeature.ADVANCED_CONVERSATION);
    });
  });

  describe('provider resilience usage recording (Build Session 12 Part 6)', () => {
    // Bypasses buildService's plain-object `provider` composition — a
    // real class instance's methods live on its prototype, not as own
    // properties, so `{ ...router }` (what buildService's `provider`
    // override does) would silently drop `generateReply`. This test
    // needs an actual `AiReplyProviderRouter` instance so the
    // `instanceof` check in `AssistantService.reply` takes the real
    // branch, so it constructs `AssistantService` directly instead.
    function buildServiceWithRouter(router: AiReplyProviderRouter) {
      const prisma = {
        preference: { findUnique: jest.fn().mockResolvedValue({ aiMemoryEnabled: false }) },
      } as unknown as PrismaService;
      const memory = {
        getNotes: jest.fn().mockResolvedValue([]),
        remember: jest.fn().mockResolvedValue(undefined),
        deleteNote: jest.fn().mockResolvedValue(undefined),
        clear: jest.fn().mockResolvedValue(undefined),
      } as unknown as CompanionMemoryService;
      const safety = {
        classify: jest.fn().mockReturnValue({
          category: AssistantSafetyCategory.GENERAL,
          decision: AssistantSafetyDecisionType.ALLOW_PROVIDER,
        }),
        normalizeOutput: jest.fn((reply: string) => reply),
      } as unknown as AssistantSafetyService;
      const entitlement = {
        checkAccess: jest
          .fn()
          .mockResolvedValue({ allowed: true, feature: AiFeature.ADVANCED_CONVERSATION }),
      } as unknown as AiEntitlementService;
      const extraction = {
        extractCandidate: jest.fn().mockReturnValue(null),
      } as unknown as MemoryExtractionService;
      const record = jest.fn().mockResolvedValue(undefined);
      const usagePolicy = {
        checkWithinLimit: jest.fn().mockResolvedValue({
          allowed: true,
          window: { windowStart: new Date(), count: 0, limit: 200 },
        }),
        record,
      } as unknown as AiUsagePolicy;

      const service = new AssistantService(
        router,
        prisma,
        memory,
        safety,
        entitlement,
        extraction,
        usagePolicy,
      );
      return { service, record };
    }

    function buildRouter(overrides: {
      anthropicGenerateReply?: jest.Mock;
      openaiGenerateReply?: jest.Mock;
    }) {
      const anthropic = {
        isConfigured: true,
        generateReply: overrides.anthropicGenerateReply ?? jest.fn().mockResolvedValue('unused'),
      };
      const openai = {
        isConfigured: true,
        generateReply: overrides.openaiGenerateReply ?? jest.fn().mockResolvedValue('unused'),
      };
      const gemini = { isConfigured: true, generateReply: jest.fn().mockResolvedValue('unused') };
      const configService = {
        get: () => ({
          provider: 'anthropic',
          anthropicModel: 'claude-x',
          openaiModel: 'gpt-x',
          geminiModel: 'gemini-x',
        }),
      } as unknown as ConfigService;
      return new AiReplyProviderRouter(
        configService,
        new AiProviderCircuitBreaker(),
        anthropic as unknown as AnthropicReplyProvider,
        openai as unknown as OpenAiReplyProvider,
        gemini as unknown as GeminiReplyProvider,
      );
    }

    it('records one AiUsageEvent per attempt the router made, via the lastAttempts side-channel', async () => {
      const router = buildRouter({
        anthropicGenerateReply: jest.fn().mockRejectedValue(new Error('anthropic down')),
        openaiGenerateReply: jest.fn().mockResolvedValue('a live reply'),
      });
      const { service, record } = buildServiceWithRouter(router);

      const result = await service.reply(dto, 'user-1');

      expect(result.reply).toBe('a live reply');
      expect(record).toHaveBeenCalledTimes(2);
      expect(record).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({
          userId: 'user-1',
          provider: 'anthropic',
          feature: AiFeature.ADVANCED_CONVERSATION,
          tier: 'PREMIUM',
          success: false,
        }),
      );
      expect(record).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({
          userId: 'user-1',
          provider: 'openai',
          success: true,
          outputChars: 'a live reply'.length,
        }),
      );
    });

    it('does not attempt to record anything when the provider is not the resilience router', async () => {
      const { service, record } = buildService();

      await service.reply(dto, 'user-1');

      expect(record).not.toHaveBeenCalled();
    });
  });

  describe('context minimization (Build Session 12 Part 7)', () => {
    it('reply() never queries any Prisma model besides Preference — a Proxy trap fires if a future change adds a forbidden DB read (DMs, gallery, support tickets, GPS routes, wearables, etc.)', async () => {
      const touched: string[] = [];
      const prisma = new Proxy(
        {},
        {
          get(_target, prop: string) {
            if (prop === 'preference') {
              return { findUnique: jest.fn().mockResolvedValue({ aiMemoryEnabled: false }) };
            }
            touched.push(prop);
            throw new Error(`AssistantService.reply() touched forbidden Prisma model "${prop}"`);
          },
        },
      ) as unknown as PrismaService;

      const generateReply = jest.fn().mockResolvedValue('a reply');
      const provider: AiReplyProvider = { isConfigured: true, generateReply };
      const memory = {
        getNotes: jest.fn().mockResolvedValue([]),
        remember: jest.fn().mockResolvedValue(undefined),
      } as unknown as CompanionMemoryService;
      const safety = {
        classify: jest.fn().mockReturnValue({
          category: AssistantSafetyCategory.GENERAL,
          decision: AssistantSafetyDecisionType.ALLOW_PROVIDER,
        }),
        normalizeOutput: jest.fn((reply: string) => reply),
      } as unknown as AssistantSafetyService;
      const entitlement = {
        checkAccess: jest
          .fn()
          .mockResolvedValue({ allowed: true, feature: AiFeature.ADVANCED_CONVERSATION }),
      } as unknown as AiEntitlementService;
      const extraction = {
        extractCandidate: jest.fn().mockReturnValue(null),
      } as unknown as MemoryExtractionService;
      const usagePolicy = {
        checkWithinLimit: jest.fn().mockResolvedValue({
          allowed: true,
          window: { windowStart: new Date(), count: 0, limit: 200 },
        }),
        record: jest.fn().mockResolvedValue(undefined),
      } as unknown as AiUsagePolicy;

      const service = new AssistantService(
        provider,
        prisma,
        memory,
        safety,
        entitlement,
        extraction,
        usagePolicy,
      );

      await service.reply(dto, 'user-1');

      expect(touched).toEqual([]);
    });

    it('only ever sends the companion, style, capped history, current input, structured memory notes, and an optional safety-context string to the provider — never a raw object from elsewhere', async () => {
      const { service, generateReply } = buildService({
        memoryNotes: [
          {
            id: 'note-1',
            category: CompanionMemoryCategory.GOAL,
            value: 'Goal: build strength.',
            createdAt: new Date(),
          },
        ],
      });

      await service.reply(dto, 'user-1');

      const [passedDto, passedNotes, passedSafetyContext] = generateReply.mock.calls[0];
      expect(passedDto).toBe(dto);
      expect(passedNotes).toEqual(['Goal: build strength.']);
      expect(passedSafetyContext).toBeUndefined();
      // dto only ever has the fields AssistantReplyDto declares — the
      // global ValidationPipe's forbidNonWhitelisted already strips/
      // rejects anything else before this method is ever reached (see
      // the e2e test in assistant.e2e-spec.ts for that boundary).
      expect(
        Object.keys(passedDto).every((key) =>
          ['companion', 'history', 'input', 'style'].includes(key),
        ),
      ).toBe(true);
    });
  });
});
