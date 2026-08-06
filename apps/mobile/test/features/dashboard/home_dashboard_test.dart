import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';
import 'package:mobile/features/workout/presentation/providers/workout_session_controller.dart';

import '../../helpers/fake_nutrition_repositories.dart';
import '../../helpers/fake_workout_repositories.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';
import '../../helpers/workout_fixtures.dart';

const _profile = ProfileModel(
  firstName: 'Jordan',
  languageCode: 'en',
  timezone: 'UTC',
  unitSystem: UnitSystem.metric,
  sexForCalculations: SexForCalculations.unspecified,
  onboardingCompleted: true,
  onboardingStep: 8,
);

void main() {
  testWidgets('renders the signed-in user\'s first name in the greeting', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialProfile: _profile,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeDashboardScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.textContaining('Jordan'), findsOneWidget);
  });

  testWidgets(
    'shows the most recently completed real workout, not sample data, when there is no active session',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profile,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeDashboardScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      // FakeWorkoutHistoryRepository's default entry is sampleHistoryEntry,
      // whose workout plan is named after sampleWorkout.
      expect(find.text('Last workout'), findsOneWidget);
      expect(find.textContaining(sampleWorkout.name), findsOneWidget);
    },
  );

  testWidgets(
    'shows an empty, honest state — not sample data — when there is no workout history',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profile,
        workoutHistoryRepository: FakeWorkoutHistoryRepository(
          entries: const [],
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeDashboardScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('No workouts yet'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
    },
  );

  testWidgets(
    'the streak metric is computed from real completed-workout dates, not the sample fixture',
    (tester) async {
      // sampleHistoryEntry's completedAt is a fixed date in the past
      // relative to "now" in any test run, so the real streak must read 0
      // — proving the value comes from computeWorkoutStreak(), not from
      // DashboardFixture.sample()'s streakDays (which is 4).
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profile,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeDashboardScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('0 days'), findsOneWidget);
      expect(find.text('4 days'), findsNothing);
    },
  );

  testWidgets(
    'surfaces the most recent personal record with a real value, not sample data',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profile,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeDashboardScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('New personal record'), findsOneWidget);
      expect(
        find.textContaining(samplePersonalRecord.exercise.name),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows real protein and hydration values from the Nutrition backend, not the sample fixture',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profile,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeDashboardScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      // sampleNutritionDashboardSummary.proteinGrams is 42 — the sample
      // DashboardFixture's proteinGrams is 62, so this proves the ring
      // reads from the real nutrition summary provider.
      expect(find.text('42g'), findsOneWidget);
      expect(find.text('0.8L'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a graceful "no data" state instead of a fake value when the nutrition summary fails to load',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profile,
        nutritionSummaryRepository: FakeNutritionSummaryRepository(
          shouldFail: true,
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeDashboardScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('No data'), findsNWidgets(2));
      expect(find.text('42g'), findsNothing);
    },
  );

  testWidgets(
    'shows a Resume affordance instead of the last-workout card while a session is active',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profile,
      );
      addTearDown(container.dispose);

      for (var i = 0; i < 40; i++) {
        if (container.read(authControllerProvider).status !=
            AuthStatus.unknown) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 25));
      }
      await container
          .read(workoutSessionControllerProvider.notifier)
          .start(workoutPlanId: 'plan-1', workoutPlanName: sampleWorkout.name);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeDashboardScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Workout in progress'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Last workout'), findsNothing);
    },
  );
}
