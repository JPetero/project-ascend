import { AppCapability, ENTITLEMENTS, PlanTier, resolveHasCapability } from './capability.util';

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
];

const PREMIUM_CAPABILITIES: AppCapability[] = [
  AppCapability.ADVANCED_AI_CONVERSATIONS,
  AppCapability.PREMIUM_COMPANION_VOICES,
  AppCapability.ADVANCED_ANALYTICS,
  AppCapability.ADVANCED_MEAL_PLANNING,
  AppCapability.SCANNER_FEATURES,
  AppCapability.LARGER_MEDIA_STORAGE,
  AppCapability.DEEPER_WEARABLE_INSIGHTS,
];

describe('resolveHasCapability', () => {
  it.each(FREE_CAPABILITIES)(
    'every free capability (%s) is available on the FREE tier — never accidentally gated',
    (capability) => {
      expect(resolveHasCapability(PlanTier.FREE, capability)).toBe(true);
    },
  );

  it.each(FREE_CAPABILITIES)('%s stays available on the PREMIUM tier too', (capability) => {
    expect(resolveHasCapability(PlanTier.PREMIUM, capability)).toBe(true);
  });

  it.each(PREMIUM_CAPABILITIES)('%s is not available on the FREE tier', (capability) => {
    expect(resolveHasCapability(PlanTier.FREE, capability)).toBe(false);
  });

  it.each(PREMIUM_CAPABILITIES)('%s is available on the PREMIUM tier', (capability) => {
    expect(resolveHasCapability(PlanTier.PREMIUM, capability)).toBe(true);
  });

  it('every capability in the enum has exactly one entitlement entry', () => {
    const allCapabilities = Object.values(AppCapability);
    const entitledCapabilities = ENTITLEMENTS.map((e) => e.capability);
    expect(new Set(entitledCapabilities).size).toBe(allCapabilities.length);
    for (const capability of allCapabilities) {
      expect(entitledCapabilities).toContain(capability);
    }
  });
});
