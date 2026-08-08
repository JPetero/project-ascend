/**
 * Single source of Trainer Groups' free-tier numeric limits — see
 * packages/docs/product/user-scenario-bible.md Scenario 24: "a centrally
 * configurable small-member limit (three to five members, not hard-coded
 * per-widget)". Both `TrainerGroupsService` and any future admin/config
 * surface read from here rather than each declaring their own literal.
 */
export const TRAINER_GROUP_OWNED_LIMIT_FREE = 1;
export const TRAINER_GROUP_MEMBER_LIMIT_FREE = 5;

/**
 * Premium-tier limits (Build Session 9 Part 20) — Scenario 24's
 * Premium-future list says "more groups per owner, larger group sizes"
 * without specifying exact numbers. These are illustrative business
 * values, not confirmed final numbers, the same caveat as
 * common/config/pricing.config.ts's non-final pricing hypotheses.
 */
export const TRAINER_GROUP_OWNED_LIMIT_PREMIUM = 5;
export const TRAINER_GROUP_MEMBER_LIMIT_PREMIUM = 25;
