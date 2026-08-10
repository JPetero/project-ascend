/**
 * Build Session 13 Part 1 — the explicit feature-flag registry that
 * replaces the old blanket "any absent key is enabled" contract
 * (Build Session 12 Part 15-17). That contract was fine for a purely
 * cosmetic nav icon (`trainer_dashboard`, the only flag anything ever
 * actually gated) but wrong the moment a flag controls something that
 * spends external money, exposes experimental tech, or bypasses
 * Premium — an outage or a typo'd key must never silently turn one of
 * those on.
 *
 * Every flag the product actually gates is declared here, once, with a
 * real default. `FeatureFlagsService.resolveForUser` always resolves
 * every registered key to a boolean (a stored `FeatureFlag` row
 * overrides the registry default; no row falls back to it) — a
 * registered key can never again be silently absent. The mobile client
 * mirrors this same registry (`ascend_feature.dart`) as a second,
 * independent safety net for the loading/network-failure case, since a
 * client that never received a resolved map at all has nothing to look
 * up server-side.
 */

export enum AscendFeatureKey {
  VISION_FORM_COACH = 'VISION_FORM_COACH',
  LIVE_AI = 'LIVE_AI',
  RESEARCH_MODE = 'RESEARCH_MODE',
  REMOTE_PUSH = 'REMOTE_PUSH',
  GOOGLE_SIGN_IN = 'GOOGLE_SIGN_IN',
  APPLE_SIGN_IN = 'APPLE_SIGN_IN',
  STORE_PURCHASES = 'STORE_PURCHASES',
  TRAINER_VERIFICATION = 'TRAINER_VERIFICATION',
  ASCEND_PROMOTE = 'ASCEND_PROMOTE',
  TRAINER_DASHBOARD = 'TRAINER_DASHBOARD',
}

/**
 * SAFE_CORE: normal product surface — failing open when flag
 * resolution is unavailable cannot spend external money, expose
 * experimental technology, violate privacy, bypass Premium, or depend
 * on unconfigured infrastructure.
 *
 * RISKY_EXTERNAL: the opposite of at least one of those. Defaults to
 * disabled; an admin must explicitly turn it on once the underlying
 * capability is actually ready for real users.
 */
export enum FeatureFlagRisk {
  SAFE_CORE = 'SAFE_CORE',
  RISKY_EXTERNAL = 'RISKY_EXTERNAL',
}

export interface FeatureFlagDefinition {
  key: AscendFeatureKey;
  description: string;
  defaultEnabled: boolean;
  risk: FeatureFlagRisk;
}

export const FEATURE_FLAG_REGISTRY: Record<AscendFeatureKey, FeatureFlagDefinition> = {
  [AscendFeatureKey.VISION_FORM_COACH]: {
    key: AscendFeatureKey.VISION_FORM_COACH,
    description:
      'Vision Form Coach — live camera-based pose analysis. Experimental technology and Premium; never on by default.',
    defaultEnabled: false,
    risk: FeatureFlagRisk.RISKY_EXTERNAL,
  },
  [AscendFeatureKey.LIVE_AI]: {
    key: AscendFeatureKey.LIVE_AI,
    description:
      'Live Ascend AI replies via a paid provider (OpenAI/Anthropic/Gemini). Spends external money per request.',
    defaultEnabled: false,
    risk: FeatureFlagRisk.RISKY_EXTERNAL,
  },
  [AscendFeatureKey.RESEARCH_MODE]: {
    key: AscendFeatureKey.RESEARCH_MODE,
    description:
      'Research Mode — live-web-backed research synthesis via a paid search provider. Spends external money per query.',
    defaultEnabled: false,
    risk: FeatureFlagRisk.RISKY_EXTERNAL,
  },
  [AscendFeatureKey.STORE_PURCHASES]: {
    key: AscendFeatureKey.STORE_PURCHASES,
    description:
      'Real in-app purchase flow (Play Billing / StoreKit). Financial transaction surface.',
    defaultEnabled: false,
    risk: FeatureFlagRisk.RISKY_EXTERNAL,
  },
  [AscendFeatureKey.ASCEND_PROMOTE]: {
    key: AscendFeatureKey.ASCEND_PROMOTE,
    description:
      "Paid distribution for a creator's own Community content. Financial transaction surface.",
    defaultEnabled: false,
    risk: FeatureFlagRisk.RISKY_EXTERNAL,
  },
  [AscendFeatureKey.REMOTE_PUSH]: {
    key: AscendFeatureKey.REMOTE_PUSH,
    description:
      'Remote push notification preference presentation. No spend, no experimental tech.',
    defaultEnabled: true,
    risk: FeatureFlagRisk.SAFE_CORE,
  },
  [AscendFeatureKey.GOOGLE_SIGN_IN]: {
    key: AscendFeatureKey.GOOGLE_SIGN_IN,
    description: 'Google Sign-In button on the login/register screens.',
    defaultEnabled: true,
    risk: FeatureFlagRisk.SAFE_CORE,
  },
  [AscendFeatureKey.APPLE_SIGN_IN]: {
    key: AscendFeatureKey.APPLE_SIGN_IN,
    description: 'Apple Sign-In button on the login/register screens.',
    defaultEnabled: true,
    risk: FeatureFlagRisk.SAFE_CORE,
  },
  [AscendFeatureKey.TRAINER_VERIFICATION]: {
    key: AscendFeatureKey.TRAINER_VERIFICATION,
    description: 'Apply-for-trainer-verification entry point on Edit Community Profile.',
    defaultEnabled: true,
    risk: FeatureFlagRisk.SAFE_CORE,
  },
  [AscendFeatureKey.TRAINER_DASHBOARD]: {
    key: AscendFeatureKey.TRAINER_DASHBOARD,
    description: 'Trainer Dashboard entry icon on the Trainer Groups screen.',
    defaultEnabled: true,
    risk: FeatureFlagRisk.SAFE_CORE,
  },
};

export function isRegisteredFeatureKey(key: string): key is AscendFeatureKey {
  return Object.prototype.hasOwnProperty.call(FEATURE_FLAG_REGISTRY, key);
}
