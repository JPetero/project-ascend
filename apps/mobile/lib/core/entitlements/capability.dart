/// Flutter-side counterpart to
/// `services/api/src/common/entitlements/capability.util.ts` — see
/// packages/docs/product/free-premium-policy.md. Every capability check in
/// the app should go through [hasCapability] rather than a scattered raw
/// `isPremium` flag, so the free/premium boundary lives in one place.
library;

enum PlanTier { free, premium }

enum AppCapability {
  // Free — see free-premium-policy.md's Free list.
  workoutLogging,
  personalWorkoutPlans,
  nutritionLogging,
  waterTracking,
  progressDashboard,
  companionSelection,
  coachingStyleSelection,
  basicCompanionInteractions,
  supportedAccountAuth,
  offlineUse,
  dataExport,
  // Founder Scenarios 11-20 addendum — see
  // packages/docs/product/user-scenario-bible.md. None of these are
  // built yet; the entries exist so the free/premium boundary is
  // explicit ahead of implementation.
  achievements,
  gpsCardioTracking,
  rankedLeaderboardOptIn,
  profilePrivacyControls,
  blockAndReport,
  accessibleScheduling,

  // Premium-future — see free-premium-policy.md's Premium list. Not
  // implemented yet; listed so the boundary is explicit.
  advancedAiConversations,
  premiumCompanionVoices,
  advancedAnalytics,
  advancedMealPlanning,
  scannerFeatures,
  largerMediaStorage,
  deeperWearableInsights,
  // Founder Scenarios 11-20 addendum premium-future entries.
  achievementCosmetics,
  socialJointSessionHosting,
  profileCosmeticCustomization,
  deepAdaptiveScheduling,
}

const _freeCapabilities = {
  AppCapability.workoutLogging,
  AppCapability.personalWorkoutPlans,
  AppCapability.nutritionLogging,
  AppCapability.waterTracking,
  AppCapability.progressDashboard,
  AppCapability.companionSelection,
  AppCapability.coachingStyleSelection,
  AppCapability.basicCompanionInteractions,
  AppCapability.supportedAccountAuth,
  AppCapability.offlineUse,
  AppCapability.dataExport,
  AppCapability.achievements,
  AppCapability.gpsCardioTracking,
  AppCapability.rankedLeaderboardOptIn,
  AppCapability.profilePrivacyControls,
  AppCapability.blockAndReport,
  AppCapability.accessibleScheduling,
};

/// True when [capability] is available at [tier]. Free capabilities are
/// always available; premium ones require [PlanTier.premium].
bool hasCapability(PlanTier tier, AppCapability capability) {
  if (_freeCapabilities.contains(capability)) return true;
  return tier == PlanTier.premium;
}
