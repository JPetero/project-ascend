import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/entitlements/capability.dart';

const _freeCapabilities = [
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
];

const _premiumCapabilities = [
  AppCapability.advancedAiConversations,
  AppCapability.premiumCompanionVoices,
  AppCapability.advancedAnalytics,
  AppCapability.advancedMealPlanning,
  AppCapability.scannerFeatures,
  AppCapability.largerMediaStorage,
  AppCapability.deeperWearableInsights,
];

void main() {
  group('hasCapability', () {
    for (final capability in _freeCapabilities) {
      test('$capability is available on the free tier', () {
        expect(hasCapability(PlanTier.free, capability), isTrue);
      });

      test('$capability stays available on the premium tier too', () {
        expect(hasCapability(PlanTier.premium, capability), isTrue);
      });
    }

    for (final capability in _premiumCapabilities) {
      test('$capability is not available on the free tier', () {
        expect(hasCapability(PlanTier.free, capability), isFalse);
      });

      test('$capability is available on the premium tier', () {
        expect(hasCapability(PlanTier.premium, capability), isTrue);
      });
    }
  });
}
