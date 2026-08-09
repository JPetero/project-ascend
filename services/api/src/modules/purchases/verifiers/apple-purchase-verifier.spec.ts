import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApplePurchaseVerifier } from './apple-purchase-verifier';

describe('ApplePurchaseVerifier', () => {
  it('honestly rejects instead of pretending to verify when no shared secret is configured', async () => {
    const configService = {
      get: () => ({ appleSharedSecret: undefined }),
    } as unknown as ConfigService;
    const verifier = new ApplePurchaseVerifier(configService);

    expect(verifier.isConfigured).toBe(false);
    await expect(
      verifier.verify('receipt', 'com.projectascend.premium.monthly'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('reports configured when a shared secret is present, without making a network call', () => {
    const configService = {
      get: () => ({ appleSharedSecret: 'test-secret' }),
    } as unknown as ConfigService;
    const verifier = new ApplePurchaseVerifier(configService);

    expect(verifier.isConfigured).toBe(true);
  });

  describe('with a configured shared secret', () => {
    const configService = {
      get: () => ({ appleSharedSecret: 'test-secret' }),
    } as unknown as ConfigService;

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it(
      "parses the receipt's expires_date_ms and pending_renewal_info into " +
        'expiresAt/willRenew (Build Session 10 Part 26)',
      async () => {
        jest.spyOn(global, 'fetch').mockResolvedValue({
          json: () =>
            Promise.resolve({
              status: 0,
              latest_receipt_info: [
                {
                  product_id: 'com.projectascend.premium.monthly',
                  transaction_id: 'txn-2',
                  original_transaction_id: 'txn-1',
                  purchase_date_ms: '1700000000000',
                  expires_date_ms: '1702592000000',
                },
              ],
              pending_renewal_info: [
                { original_transaction_id: 'txn-1', auto_renew_status: '1' },
              ],
            }),
        } as Response);
        const verifier = new ApplePurchaseVerifier(configService);

        const result = await verifier.verify('receipt', 'com.projectascend.premium.monthly');

        expect(result.transactionId).toBe('txn-1');
        expect(result.expiresAt).toEqual(new Date(1702592000000));
        expect(result.willRenew).toBe(true);
      },
    );

    it('leaves expiresAt/willRenew undefined when the receipt does not include them', async () => {
      jest.spyOn(global, 'fetch').mockResolvedValue({
        json: () =>
          Promise.resolve({
            status: 0,
            latest_receipt_info: [
              {
                product_id: 'com.projectascend.premium.monthly',
                transaction_id: 'txn-2',
                original_transaction_id: 'txn-1',
                purchase_date_ms: '1700000000000',
              },
            ],
          }),
      } as Response);
      const verifier = new ApplePurchaseVerifier(configService);

      const result = await verifier.verify('receipt', 'com.projectascend.premium.monthly');

      expect(result.expiresAt).toBeUndefined();
      expect(result.willRenew).toBeUndefined();
    });
  });
});
