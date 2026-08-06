import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';
import 'package:mobile/features/profile/domain/workout_schedule.dart';
import 'package:mobile/features/workout/domain/workout_history_entry.dart';
import 'package:mobile/features/workout/domain/workout_session.dart';
import 'package:mobile/features/workout/presentation/providers/workout_session_controller.dart';
import 'package:mobile/features/workout/presentation/screens/workout_summary_screen.dart';

import '../../helpers/fake_workout_repositories.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

const _profileWithSchedule = ProfileModel(
  firstName: 'Ada',
  languageCode: 'en',
  timezone: 'UTC',
  unitSystem: UnitSystem.metric,
  sexForCalculations: SexForCalculations.unspecified,
  onboardingCompleted: true,
  onboardingStep: 8,
  workoutSchedule: WorkoutSchedule(
    durationMinutes: 30,
    daysOfWeek: ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
  ),
);

WorkoutSessionState _finishedSession() {
  final now = DateTime.now();
  return WorkoutSessionState(
    localId: 'session-1',
    userId: 'user-1',
    status: WorkoutSessionStatus.completed,
    startedAt: now.subtract(const Duration(minutes: 30)),
    resumedAt: now,
    completedAt: now,
    activeDurationSeconds: 1800,
    sets: [
      LoggedSet(
        localId: 'set-1',
        exerciseId: 'exercise-1',
        exerciseName: 'Bench Press',
        setNumber: 1,
        reps: 8,
        weightKg: 60,
        completedAt: now,
      ),
    ],
  );
}

void main() {
  testWidgets(
    'shows a clearly-defined weekly completion percentage and a Meal Prep nudge',
    (tester) async {
      final now = DateTime.now();
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profileWithSchedule,
        workoutHistoryRepository: FakeWorkoutHistoryRepository(
          entries: [
            WorkoutHistoryEntry(
              id: 'entry-1',
              startedAt: now,
              completedAt: now,
              activeDurationSeconds: 1800,
              exerciseCount: 1,
              setCount: 1,
              totalVolumeKg: 480,
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      final result = WorkoutFinishResult(
        session: _finishedSession(),
        newPersonalRecords: const [],
        synced: true,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: WorkoutSummaryScreen(result: result)),
        ),
      );
      await pumpForAsyncSettle(tester);

      // 1 of 3 planned sessions this week → 33.3%, rounded to 33% for display.
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('1 of 3 planned sessions this week'), findsOneWidget);

      final mealPrepNudge = find.text('Keep going in Meal Prep');
      await tester.scrollUntilVisible(
        mealPrepNudge,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(mealPrepNudge, findsOneWidget);
      expect(find.text('View my progress'), findsOneWidget);
    },
  );
}
