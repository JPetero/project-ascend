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

  // Premium-future — see free-premium-policy.md's Premium list. Not
  // implemented yet; listed so the boundary is explicit.
  advancedAiConversations,
  premiumCompanionVoices,
  advancedAnalytics,
  advancedMealPlanning,
  scannerFeatures,
  largerMediaStorage,
  deeperWearableInsights,
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
};

/// True when [capability] is available at [tier]. Free capabilities are
/// always available; premium ones require [PlanTier.premium].
bool hasCapability(PlanTier tier, AppCapability capability) {
  if (_freeCapabilities.contains(capability)) return true;
  return tier == PlanTier.premium;
}
