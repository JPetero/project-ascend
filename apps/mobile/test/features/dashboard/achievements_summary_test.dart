import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/achievements/domain/achievement.dart';
import 'package:mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';

import '../../helpers/fake_achievement_repositories.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

const _onboardedProfile = ProfileModel(
  firstName: 'Ada',
  languageCode: 'en',
  timezone: 'UTC',
  unitSystem: UnitSystem.metric,
  sexForCalculations: SexForCalculations.unspecified,
  onboardingCompleted: true,
  onboardingStep: 8,
);

void main() {
  testWidgets('shows how many achievements the user has earned', (
    tester,
  ) async {
    final earned = Achievement(
      id: 'achievement-1',
      key: 'first_workout',
      title: 'First Steps',
      description: 'Complete your first workout.',
      iconAsset: 'fitness_center',
      category: AchievementCategory.workout,
      targetSteps: 1,
      progress: 1,
      earnedAt: DateTime(2026, 8, 1),
    );
    const locked = Achievement(
      id: 'achievement-2',
      key: 'ten_workouts',
      title: 'Building the Habit',
      description: 'Complete 10 workouts.',
      iconAsset: 'fitness_center',
      category: AchievementCategory.workout,
      targetSteps: 10,
      progress: 1,
      earnedAt: null,
    );

    final container = await createTestContainer(
      signedIn: true,
      initialProfile: _onboardedProfile,
      achievementRepository: FakeAchievementRepository(
        achievements: [earned, locked],
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    final summary = find.text('1 of 2 earned');
    await tester.scrollUntilVisible(
      summary,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(summary, findsOneWidget);
  });
}
