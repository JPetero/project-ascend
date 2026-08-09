import { PrismaService } from '../../prisma/prisma.service';
import { AiUsagePolicy, FAIR_USE_LIMIT_MESSAGE } from './ai-usage-policy.service';

function buildPolicy(count: number) {
  const prisma = {
    aiUsageEvent: {
      count: jest.fn().mockResolvedValue(count),
      create: jest.fn().mockResolvedValue(undefined),
    },
  } as unknown as PrismaService;
  return { policy: new AiUsagePolicy(prisma), prisma };
}

describe('AiUsagePolicy', () => {
  it('allows usage below the daily fair-use ceiling', async () => {
    const { policy } = buildPolicy(5);
    const { allowed, window } = await policy.checkWithinLimit('user-1', 'ADVANCED_CONVERSATION');

    expect(allowed).toBe(true);
    expect(window.count).toBe(5);
    expect(window.limit).toBe(200);
  });

  it('disallows usage at or above the daily fair-use ceiling', async () => {
    const { policy } = buildPolicy(200);
    const { allowed } = await policy.checkWithinLimit('user-1', 'ADVANCED_CONVERSATION');

    expect(allowed).toBe(false);
  });

  it('only counts successful events within the rolling window, scoped to this user and feature', async () => {
    const { policy, prisma } = buildPolicy(0);
    await policy.checkWithinLimit('user-1', 'ADVANCED_CONVERSATION');

    expect(prisma.aiUsageEvent.count).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          userId: 'user-1',
          feature: 'ADVANCED_CONVERSATION',
          success: true,
        }),
      }),
    );
  });

  it('records a usage event with every field the caller provided', async () => {
    const { policy, prisma } = buildPolicy(0);
    await policy.record({
      userId: 'user-1',
      provider: 'anthropic',
      model: 'claude-x',
      feature: 'ADVANCED_CONVERSATION',
      tier: 'PREMIUM',
      success: true,
      latencyMs: 120,
      inputChars: 20,
      outputChars: 40,
    });

    expect(prisma.aiUsageEvent.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId: 'user-1',
        provider: 'anthropic',
        model: 'claude-x',
        success: true,
        latencyMs: 120,
      }),
    });
  });

  it('never throws when recording fails — a logging failure must not break a reply the user already received', async () => {
    const prisma = {
      aiUsageEvent: {
        count: jest.fn(),
        create: jest.fn().mockRejectedValue(new Error('db down')),
      },
    } as unknown as PrismaService;
    const policy = new AiUsagePolicy(prisma);

    await expect(
      policy.record({
        userId: 'user-1',
        provider: 'anthropic',
        feature: 'ADVANCED_CONVERSATION',
        tier: 'PREMIUM',
        success: true,
        latencyMs: 1,
        inputChars: 1,
      }),
    ).resolves.toBeUndefined();
  });

  it('the fair-use limit message never guilts the user into upgrading', () => {
    expect(FAIR_USE_LIMIT_MESSAGE).not.toMatch(/upgrade|subscribe|premium/i);
  });
});
