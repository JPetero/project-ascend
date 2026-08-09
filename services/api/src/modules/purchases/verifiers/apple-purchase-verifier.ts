import { Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IapConfig } from '../../../config/configuration';
import { PurchaseVerificationResult, PurchaseVerifier } from './purchase-verifier.interface';

const PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';
const SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';

// Apple returns this status when a sandbox receipt is sent to the
// production endpoint — the documented signal to retry against sandbox
// rather than a real rejection.
const SANDBOX_RECEIPT_STATUS = 21007;

interface AppleReceiptTransaction {
  product_id: string;
  transaction_id: string;
  original_transaction_id: string;
  purchase_date_ms: string;
  // Only present for auto-renewable subscription transactions (absent
  // for one-time products) — the current period's expiration.
  expires_date_ms?: string;
}

// One entry per auto-renewable subscription on the receipt — carries
// the current auto-renew intent, separate from the transaction history.
interface ApplePendingRenewalInfo {
  original_transaction_id: string;
  auto_renew_status: string; // '1' = will renew, '0' = won't.
}

interface AppleVerifyReceiptResponse {
  status: number;
  receipt?: { in_app?: AppleReceiptTransaction[] };
  latest_receipt_info?: AppleReceiptTransaction[];
  pending_renewal_info?: ApplePendingRenewalInfo[];
}

/**
 * Verifies an App Store receipt against Apple's own servers using the
 * classic `verifyReceipt` endpoint (still functional for both
 * consumable and auto-renewable products) and the app's shared secret.
 * No live APPLE_IAP_SHARED_SECRET exists in this environment (no App
 * Store Connect account has been configured this session), so this code
 * path is real but untested against a live Apple receipt — see
 * build-session-9.md.
 */
@Injectable()
export class ApplePurchaseVerifier implements PurchaseVerifier {
  private readonly sharedSecret: string | undefined;

  constructor(private readonly configService: ConfigService) {
    this.sharedSecret = this.configService.get<IapConfig>('iap')!.appleSharedSecret;
  }

  get isConfigured(): boolean {
    return Boolean(this.sharedSecret);
  }

  async verify(receiptData: string, productId: string): Promise<PurchaseVerificationResult> {
    if (!this.sharedSecret) {
      throw new ServiceUnavailableException(
        'Apple purchase verification is not configured. Set APPLE_IAP_SHARED_SECRET to enable it.',
      );
    }

    let result = await this.callVerifyReceipt(receiptData, PRODUCTION_URL);
    if (result.status === SANDBOX_RECEIPT_STATUS) {
      result = await this.callVerifyReceipt(receiptData, SANDBOX_URL);
    }

    if (result.status !== 0) {
      throw new UnauthorizedException(`Apple rejected this receipt (status ${result.status}).`);
    }

    const transactions = result.latest_receipt_info ?? result.receipt?.in_app ?? [];
    const latest = transactions
      .filter((transaction) => transaction.product_id === productId)
      .sort((a, b) => Number(b.purchase_date_ms) - Number(a.purchase_date_ms))[0];

    if (!latest) {
      throw new UnauthorizedException(
        'This receipt contains no transaction for the requested product.',
      );
    }

    const renewalInfo = result.pending_renewal_info?.find(
      (info) => info.original_transaction_id === latest.original_transaction_id,
    );

    return {
      transactionId: latest.original_transaction_id,
      expiresAt: latest.expires_date_ms ? new Date(Number(latest.expires_date_ms)) : undefined,
      willRenew: renewalInfo ? renewalInfo.auto_renew_status === '1' : undefined,
    };
  }

  private async callVerifyReceipt(
    receiptData: string,
    url: string,
  ): Promise<AppleVerifyReceiptResponse> {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receiptData,
        password: this.sharedSecret,
        'exclude-old-transactions': true,
      }),
    });
    return (await response.json()) as AppleVerifyReceiptResponse;
  }
}
