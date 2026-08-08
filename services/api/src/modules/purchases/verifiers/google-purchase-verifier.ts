import { Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleAuth } from 'google-auth-library';
import { IapConfig } from '../../../config/configuration';
import { PurchaseVerificationResult, PurchaseVerifier } from './purchase-verifier.interface';

interface GooglePurchaseResponse {
  // 0 = purchased, 1 = canceled, 2 = pending.
  purchaseState?: number;
  orderId?: string;
}

/**
 * Verifies a Google Play purchase token against the Google Play
 * Developer API using a service-account credential — the app never
 * trusts a purchase token the client reports without checking it
 * against Google's own record. No live
 * GOOGLE_PLAY_SERVICE_ACCOUNT_JSON exists in this environment (no
 * Google Cloud service account has been created this session), so this
 * code path is real but untested against a live Google purchase — see
 * build-session-9.md.
 */
@Injectable()
export class GooglePurchaseVerifier implements PurchaseVerifier {
  private readonly serviceAccountJson: string | undefined;
  private readonly packageName: string | undefined;
  private auth: GoogleAuth | undefined;

  constructor(private readonly configService: ConfigService) {
    const iapConfig = this.configService.get<IapConfig>('iap')!;
    this.serviceAccountJson = iapConfig.googleServiceAccountJson;
    this.packageName = iapConfig.googlePackageName;
  }

  get isConfigured(): boolean {
    return Boolean(this.serviceAccountJson && this.packageName);
  }

  async verify(purchaseToken: string, productId: string): Promise<PurchaseVerificationResult> {
    if (!this.serviceAccountJson || !this.packageName) {
      throw new ServiceUnavailableException(
        'Google Play purchase verification is not configured. Set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON and GOOGLE_PLAY_PACKAGE_NAME to enable it.',
      );
    }

    this.auth ??= new GoogleAuth({
      credentials: JSON.parse(this.serviceAccountJson) as Record<string, string>,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
      `${this.packageName}/purchases/products/${productId}/tokens/${purchaseToken}`;

    let response: { data: GooglePurchaseResponse };
    try {
      const client = await this.auth.getClient();
      response = await client.request<GooglePurchaseResponse>({ url });
    } catch {
      throw new UnauthorizedException('Google Play rejected this purchase token.');
    }

    if (response.data.purchaseState !== 0) {
      throw new UnauthorizedException('This purchase is not in a valid purchased state.');
    }
    if (!response.data.orderId) {
      throw new UnauthorizedException('Google Play did not return an order id for this purchase.');
    }

    return { transactionId: response.data.orderId };
  }
}
