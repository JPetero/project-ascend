/// Mirrors services/api's `AscendFeatureKey` registry
/// (feature-flag-registry.ts) — Build Session 13 Part 1. Every flag the
/// product actually gates is declared here, with the exact same wire
/// key string and the exact same registry default, so
/// `featureEnabledProvider` never has to guess.
enum AscendFeature {
  visionFormCoach,
  liveAi,
  researchMode,
  remotePush,
  googleSignIn,
  appleSignIn,
  storePurchases,
  trainerVerification,
  ascendPromote,
  trainerDashboard,
}

extension AscendFeatureWireKey on AscendFeature {
  /// The exact key string the backend resolves this flag under.
  String get key => switch (this) {
    AscendFeature.visionFormCoach => 'VISION_FORM_COACH',
    AscendFeature.liveAi => 'LIVE_AI',
    AscendFeature.researchMode => 'RESEARCH_MODE',
    AscendFeature.remotePush => 'REMOTE_PUSH',
    AscendFeature.googleSignIn => 'GOOGLE_SIGN_IN',
    AscendFeature.appleSignIn => 'APPLE_SIGN_IN',
    AscendFeature.storePurchases => 'STORE_PURCHASES',
    AscendFeature.trainerVerification => 'TRAINER_VERIFICATION',
    AscendFeature.ascendPromote => 'ASCEND_PROMOTE',
    AscendFeature.trainerDashboard => 'TRAINER_DASHBOARD',
  };

  /// Applied whenever the resolved flag map hasn't produced a value for
  /// this key yet — still loading, the fetch failed, or (should never
  /// happen for a registered key once the backend has responded, but
  /// defended anyway) the key is simply missing from the response. A
  /// risky/external/Premium feature must never come back on merely
  /// because the network call didn't land — see the backend registry's
  /// doc comment for the same reasoning.
  bool get registryDefault => switch (this) {
    AscendFeature.visionFormCoach => false,
    AscendFeature.liveAi => false,
    AscendFeature.researchMode => false,
    AscendFeature.storePurchases => false,
    AscendFeature.ascendPromote => false,
    AscendFeature.remotePush => true,
    AscendFeature.googleSignIn => true,
    AscendFeature.appleSignIn => true,
    AscendFeature.trainerVerification => true,
    AscendFeature.trainerDashboard => true,
  };
}
