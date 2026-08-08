import { ConflictException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PurchasePlatformDto, VerifyPurchaseDto } from './dto/verify-purchase.dto';
import { ApplePurchaseVerifier } from './verifiers/apple-purchase-verifier';
import { GooglePurchaseVerifier } from './verifiers/google-purchase-verifier';

/**
 * The other half of the Store purchase flow SubscriptionsService's doc
 * comment forward-referenced: the mobile app's `in_app_purchase` package
 * hands back a platform receipt/token, and this module is the only
 * thing that ever writes a PREMIUM `UserSubscription` row — always
 * gated on a real Apple/Google server check, never on the client's say-
 * so (Build Session 9 Part 17/18).
 */
@Injectable()
export class PurchasesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly appleVerifier: ApplePurchaseVerifier,
    private readonly googleVerifier: GooglePurchaseVerifier,
  ) {}

  async verifyAndRecord(userId: string, dto: VerifyPurchaseDto) {
    const verifier =
      dto.platform === PurchasePlatformDto.IOS ? this.appleVerifier : this.googleVerifier;
    const result = await verifier.verify(dto.receipt, dto.productId);

    const existing = await this.prisma.purchase.findUnique({
      where: { platformTransactionId: result.transactionId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException(
        'This purchase has already been redeemed by a different account.',
      );
    }

    await this.prisma.purchase.upsert({
      where: { platformTransactionId: result.transactionId },
      update: { status: 'VERIFIED', verifiedAt: new Date() },
      create: {
        userId,
        platform: dto.platform,
        productId: dto.productId,
        platformTransactionId: result.transactionId,
        status: 'VERIFIED',
        verifiedAt: new Date(),
      },
    });

    await this.prisma.userSubscription.upsert({
      where: { userId },
      update: { tier: 'PREMIUM' },
      create: { userId, tier: 'PREMIUM' },
    });

    return { tier: 'PREMIUM' as const };
  }
}
