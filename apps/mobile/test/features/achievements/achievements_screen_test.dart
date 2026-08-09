import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/achievements/domain/achievement.dart';
import 'package:mobile/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:mobile/features/sharing/presentation/screens/share_content_screen.dart';

import '../../helpers/fake_achievement_repositories.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows earned and locked achievements grouped by category', (
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
      progress: 3,
      earnedAt: null,
    );

    final container = await createTestContainer(
      achievementRepository: FakeAchievementRepository(
        achievements: [earned, locked],
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AchievementsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('1 of 2 earned'), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('Building the Habit'), findsOneWidget);
    expect(find.text('3 / 10'), findsOneWidget);
  });

  testWidgets('shows an honest empty state with no achievements', (
    tester,
  ) async {
    final container = await createTestContainer(
      achievementRepository: FakeAchievementRepository(achievements: const []),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AchievementsScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No achievements yet'), findsOneWidget);
  });

  testWidgets(
    'an earned achievement has a working share action; a locked one does not '
    '(Build Session 10 Parts 20-21 — this was never wired up)',
    (tester) async {
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
        progress: 3,
        earnedAt: null,
      );

      final container = await createTestContainer(
        achievementRepository: FakeAchievementRepository(
          achievements: [earned, locked],
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AchievementsScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byTooltip('Share this achievement'), findsOneWidget);

      await tester.tap(find.byTooltip('Share this achievement'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(ShareContentScreen), findsOneWidget);
    },
  );
}
