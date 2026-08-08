/**
 * What a successful verification against the real Apple/Google server
 * gives back — just enough to record a durable, unique Purchase row.
 * `transactionId` is Apple's `original_transaction_id` (so renewals of
 * the same subscription redeem into the same row) or Google's
 * `orderId`.
 */
export interface PurchaseVerificationResult {
  transactionId: string;
}

export interface PurchaseVerifier {
  readonly isConfigured: boolean;
  verify(receipt: string, productId: string): Promise<PurchaseVerificationResult>;
}
