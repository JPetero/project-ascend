import { ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PurchasePlatformDto } from './dto/verify-purchase.dto';
import { PurchasesService } from './purchases.service';
import { ApplePurchaseVerifier } from './verifiers/apple-purchase-verifier';
import { GooglePurchaseVerifier } from './verifiers/google-purchase-verifier';

describe('PurchasesService', () => {
  let service: PurchasesService;
  let prisma: {
    purchase: { findUnique: jest.Mock; upsert: jest.Mock };
    userSubscription: { upsert: jest.Mock };
  };
  let appleVerifier: { verify: jest.Mock };
  let googleVerifier: { verify: jest.Mock };

  beforeEach(() => {
    prisma = {
      purchase: { findUnique: jest.fn(), upsert: jest.fn() },
      userSubscription: { upsert: jest.fn() },
    };
    appleVerifier = { verify: jest.fn() };
    googleVerifier = { verify: jest.fn() };

    service = new PurchasesService(
      prisma as unknown as PrismaService,
      appleVerifier as unknown as ApplePurchaseVerifier,
      googleVerifier as unknown as GooglePurchaseVerifier,
    );
  });

  it('routes an iOS purchase to the Apple verifier and an Android purchase to the Google verifier', async () => {
    prisma.purchase.findUnique.mockResolvedValue(null);
    appleVerifier.verify.mockResolvedValue({ transactionId: 'apple-txn-1' });
    googleVerifier.verify.mockResolvedValue({ transactionId: 'google-order-1' });

    await service.verifyAndRecord('user-1', {
      platform: PurchasePlatformDto.IOS,
      productId: 'premium.monthly',
      receipt: 'base64-receipt',
    });
    expect(appleVerifier.verify).toHaveBeenCalledWith('base64-receipt', 'premium.monthly');
    expect(googleVerifier.verify).not.toHaveBeenCalled();

    await service.verifyAndRecord('user-1', {
      platform: PurchasePlatformDto.ANDROID,
      productId: 'premium.monthly',
      receipt: 'purchase-token',
    });
    expect(googleVerifier.verify).toHaveBeenCalledWith('purchase-token', 'premium.monthly');
  });

  it('upserts a VERIFIED purchase row and promotes the buyer to PREMIUM after a real verification succeeds', async () => {
    prisma.purchase.findUnique.mockResolvedValue(null);
    const expiresAt = new Date('2026-09-09T00:00:00.000Z');
    appleVerifier.verify.mockResolvedValue({
      transactionId: 'apple-txn-1',
      expiresAt,
      willRenew: true,
    });

    const result = await service.verifyAndRecord('user-1', {
      platform: PurchasePlatformDto.IOS,
      productId: 'premium.monthly',
      receipt: 'base64-receipt',
    });

    expect(prisma.purchase.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { platformTransactionId: 'apple-txn-1' },
        create: expect.objectContaining({
          userId: 'user-1',
          platform: PurchasePlatformDto.IOS,
          productId: 'premium.monthly',
          platformTransactionId: 'apple-txn-1',
          status: 'VERIFIED',
        }),
      }),
    );
    expect(prisma.userSubscription.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'user-1' },
        update: { tier: 'PREMIUM', expiresAt, willRenew: true },
        create: { userId: 'user-1', tier: 'PREMIUM', expiresAt, willRenew: true },
      }),
    );
    expect(result).toEqual({ tier: 'PREMIUM', expiresAt });
  });

  it('refuses to redeem a transaction id that already belongs to a different account', async () => {
    prisma.purchase.findUnique.mockResolvedValue({ userId: 'someone-else' });
    appleVerifier.verify.mockResolvedValue({ transactionId: 'apple-txn-1' });

    await expect(
      service.verifyAndRecord('user-1', {
        platform: PurchasePlatformDto.IOS,
        productId: 'premium.monthly',
        receipt: 'base64-receipt',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.purchase.upsert).not.toHaveBeenCalled();
    expect(prisma.userSubscription.upsert).not.toHaveBeenCalled();
  });

  it('lets the same account re-verify its own already-recorded transaction id idempotently', async () => {
    prisma.purchase.findUnique.mockResolvedValue({ userId: 'user-1' });
    appleVerifier.verify.mockResolvedValue({ transactionId: 'apple-txn-1' });

    await expect(
      service.verifyAndRecord('user-1', {
        platform: PurchasePlatformDto.IOS,
        productId: 'premium.monthly',
        receipt: 'base64-receipt',
      }),
    ).resolves.toEqual({ tier: 'PREMIUM', expiresAt: null });
  });
});
