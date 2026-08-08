import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PurchasesController } from './purchases.controller';
import { PurchasesService } from './purchases.service';
import { ApplePurchaseVerifier } from './verifiers/apple-purchase-verifier';
import { GooglePurchaseVerifier } from './verifiers/google-purchase-verifier';

/**
 * Build Session 9 Part 17/18 — real store purchase verification. See
 * PurchasesService's doc comment.
 */
@Module({
  imports: [ConfigModule],
  controllers: [PurchasesController],
  providers: [PurchasesService, ApplePurchaseVerifier, GooglePurchaseVerifier],
})
export class PurchasesModule {}
