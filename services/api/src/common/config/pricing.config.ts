/**
 * Centralized Premium pricing hypotheses — Founder Scenario 27. These
 * are explicitly non-final business assumptions, not live store prices
 * (no billing/payment integration exists this session — see
 * packages/docs/product/parking-lot.md). The point of this file is that
 * no pricing literal is ever hard-coded into a widget or endpoint;
 * everything reads from here so a single change updates every surface.
 */
export interface PricingPoint {
  currency: string;
  standardAmount: number;
  eligibleAmount: number;
}

export const PRICING_POINTS: PricingPoint[] = [
  { currency: 'USD', standardAmount: 12.99, eligibleAmount: 7.99 },
  { currency: 'PHP', standardAmount: 599, eligibleAmount: 299 },
];
