/**
 * Single source of Trainer Groups' free-tier numeric limits — see
 * packages/docs/product/user-scenario-bible.md Scenario 24: "a centrally
 * configurable small-member limit (three to five members, not hard-coded
 * per-widget)". Both `TrainerGroupsService` and any future admin/config
 * surface read from here rather than each declaring their own literal.
 */
export const TRAINER_GROUP_OWNED_LIMIT_FREE = 1;
export const TRAINER_GROUP_MEMBER_LIMIT_FREE = 5;
