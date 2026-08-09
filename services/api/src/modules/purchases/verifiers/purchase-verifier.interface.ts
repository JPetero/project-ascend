/**
 * What a successful verification against the real Apple/Google server
 * gives back — just enough to record a durable, unique Purchase row.
 * `transactionId` is Apple's `original_transaction_id` (so renewals of
 * the same subscription redeem into the same row) or Google's
 * `orderId`.
 *
 * `expiresAt`/`willRenew` (Build Session 10 Part 26) are the store's
 * own stated current-period expiration and auto-renew intent for this
 * auto-renewable subscription — real data both verify endpoints already
 * return, previously parsed out of the response and discarded. Either
 * may be omitted if the store's response didn't include it.
 */
export interface PurchaseVerificationResult {
  transactionId: string;
  expiresAt?: Date;
  willRenew?: boolean;
}

export interface PurchaseVerifier {
  readonly isConfigured: boolean;
  verify(receipt: string, productId: string): Promise<PurchaseVerificationResult>;
}
