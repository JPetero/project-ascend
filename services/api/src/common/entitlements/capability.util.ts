/**
 * Centralized free/premium capability model — see
 * packages/docs/product/free-premium-policy.md. The rule this exists to
 * enforce: premium adds depth, convenience, and personalization; it never
 * makes the core free experience less useful or gates basic health
 * improvement behind a paywall. Every capability check goes through
 * `CapabilityService.hasCapability` rather than scattered raw
 * `isPremium` checks, so that rule lives in one place.
 */

export enum PlanTier {
  FREE = 'FREE',
  PREMIUM = 'PREMIUM',
}

/** Every gate-able piece of app behavior — free and future-premium alike,
 * so the full picture is visible in one place even though nothing premium
 * is enforced yet (no billing this session). */
export enum AppCapability {
  // Free — see free-premium-policy.md's Free list.
  WORKOUT_LOGGING = 'WORKOUT_LOGGING',
  PERSONAL_WORKOUT_PLANS = 'PERSONAL_WORKOUT_PLANS',
  NUTRITION_LOGGING = 'NUTRITION_LOGGING',
  WATER_TRACKING = 'WATER_TRACKING',
  PROGRESS_DASHBOARD = 'PROGRESS_DASHBOARD',
  COMPANION_SELECTION = 'COMPANION_SELECTION',
  COACHING_STYLE_SELECTION = 'COACHING_STYLE_SELECTION',
  BASIC_COMPANION_INTERACTIONS = 'BASIC_COMPANION_INTERACTIONS',
  SUPPORTED_ACCOUNT_AUTH = 'SUPPORTED_ACCOUNT_AUTH',
  OFFLINE_USE = 'OFFLINE_USE',
  DATA_EXPORT = 'DATA_EXPORT',
  // Founder Scenarios 11-20 addendum — see
  // packages/docs/product/user-scenario-bible.md. None of these are
  // built yet; the entries exist so the free/premium boundary is
  // explicit ahead of implementation, per free-premium-policy.md.
  ACHIEVEMENTS = 'ACHIEVEMENTS',
  GPS_CARDIO_TRACKING = 'GPS_CARDIO_TRACKING',
  RANKED_LEADERBOARD_OPT_IN = 'RANKED_LEADERBOARD_OPT_IN',
  PROFILE_PRIVACY_CONTROLS = 'PROFILE_PRIVACY_CONTROLS',
  BLOCK_AND_REPORT = 'BLOCK_AND_REPORT',
  ACCESSIBLE_SCHEDULING = 'ACCESSIBLE_SCHEDULING',

  // Premium-future — see free-premium-policy.md's Premium list. Not
  // implemented yet; listed so the boundary is explicit rather than
  // decided ad hoc later.
  ADVANCED_AI_CONVERSATIONS = 'ADVANCED_AI_CONVERSATIONS',
  PREMIUM_COMPANION_VOICES = 'PREMIUM_COMPANION_VOICES',
  ADVANCED_ANALYTICS = 'ADVANCED_ANALYTICS',
  ADVANCED_MEAL_PLANNING = 'ADVANCED_MEAL_PLANNING',
  SCANNER_FEATURES = 'SCANNER_FEATURES',
  LARGER_MEDIA_STORAGE = 'LARGER_MEDIA_STORAGE',
  DEEPER_WEARABLE_INSIGHTS = 'DEEPER_WEARABLE_INSIGHTS',
  // Founder Scenarios 11-20 addendum premium-future entries.
  ACHIEVEMENT_COSMETICS = 'ACHIEVEMENT_COSMETICS',
  SOCIAL_JOINT_SESSION_HOSTING = 'SOCIAL_JOINT_SESSION_HOSTING',
  PROFILE_COSMETIC_CUSTOMIZATION = 'PROFILE_COSMETIC_CUSTOMIZATION',
  DEEP_ADAPTIVE_SCHEDULING = 'DEEP_ADAPTIVE_SCHEDULING',
}

export interface Entitlement {
  capability: AppCapability;
  minimumTier: PlanTier;
}

const TIER_RANK: Record<PlanTier, number> = {
  [PlanTier.FREE]: 0,
  [PlanTier.PREMIUM]: 1,
};

const FREE_CAPABILITIES: AppCapability[] = [
  AppCapability.WORKOUT_LOGGING,
  AppCapability.PERSONAL_WORKOUT_PLANS,
  AppCapability.NUTRITION_LOGGING,
  AppCapability.WATER_TRACKING,
  AppCapability.PROGRESS_DASHBOARD,
  AppCapability.COMPANION_SELECTION,
  AppCapability.COACHING_STYLE_SELECTION,
  AppCapability.BASIC_COMPANION_INTERACTIONS,
  AppCapability.SUPPORTED_ACCOUNT_AUTH,
  AppCapability.OFFLINE_USE,
  AppCapability.DATA_EXPORT,
  AppCapability.ACHIEVEMENTS,
  AppCapability.GPS_CARDIO_TRACKING,
  AppCapability.RANKED_LEADERBOARD_OPT_IN,
  AppCapability.PROFILE_PRIVACY_CONTROLS,
  AppCapability.BLOCK_AND_REPORT,
  AppCapability.ACCESSIBLE_SCHEDULING,
];

const PREMIUM_CAPABILITIES: AppCapability[] = [
  AppCapability.ADVANCED_AI_CONVERSATIONS,
  AppCapability.PREMIUM_COMPANION_VOICES,
  AppCapability.ADVANCED_ANALYTICS,
  AppCapability.ADVANCED_MEAL_PLANNING,
  AppCapability.SCANNER_FEATURES,
  AppCapability.LARGER_MEDIA_STORAGE,
  AppCapability.DEEPER_WEARABLE_INSIGHTS,
  AppCapability.ACHIEVEMENT_COSMETICS,
  AppCapability.SOCIAL_JOINT_SESSION_HOSTING,
  AppCapability.PROFILE_COSMETIC_CUSTOMIZATION,
  AppCapability.DEEP_ADAPTIVE_SCHEDULING,
];

export const ENTITLEMENTS: Entitlement[] = [
  ...FREE_CAPABILITIES.map((capability) => ({ capability, minimumTier: PlanTier.FREE })),
  ...PREMIUM_CAPABILITIES.map((capability) => ({ capability, minimumTier: PlanTier.PREMIUM })),
];

/** Pure lookup — kept dependency-free so both the Nest service wrapper and
 * a plain unit test can use it without a DI container. */
export function resolveHasCapability(tier: PlanTier, capability: AppCapability): boolean {
  const entitlement = ENTITLEMENTS.find((e) => e.capability === capability);
  if (!entitlement) return false;
  return TIER_RANK[tier] >= TIER_RANK[entitlement.minimumTier];
}
