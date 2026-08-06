import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/workout/domain/workout_session.dart';
import 'package:mobile/features/workout/presentation/providers/workout_session_controller.dart';

import '../../helpers/fake_workout_repositories.dart';
import '../../helpers/test_provider_scope.dart';
import '../../helpers/workout_fixtures.dart';

/// No widget is mounted in these tests, so `pumpAndSettle()` would return
/// immediately instead of waiting out the async provider chain (auth
/// bootstrap, Drift reads/writes). See device_controller_scope_test.dart
/// for the same pattern.
Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 40; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 25));
  }
}

void main() {
  testWidgets(
    'workout flow: start, log sets, and finish syncs to the backend and reports new personal records',
    (tester) async {
      final repository = FakeWorkoutSessionRepository()
        ..nextPersonalRecords = [samplePersonalRecord];
      final container = await createTestContainer(
        signedIn: true,
        workoutSessionRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpUntil(
        tester,
        () =>
            container.read(authControllerProvider).status != AuthStatus.unknown,
      );

      final controller = container.read(
        workoutSessionControllerProvider.notifier,
      );
      await controller.start(
        workoutPlanId: 'plan-1',
        workoutPlanName: 'Full Body Strength',
      );

      final started = container.read(workoutSessionControllerProvider);
      expect(started, isNotNull);
      expect(started!.status, WorkoutSessionStatus.inProgress);
      expect(started.syncStatus, SessionSyncStatus.synced);
      expect(repository.startedSessionIds, hasLength(1));

      await controller.logSet(
        exerciseId: 'exercise-bench-press',
        exerciseName: 'Bench Press',
        reps: 8,
        weightKg: 62.5,
      );

      final withSet = container.read(workoutSessionControllerProvider);
      expect(withSet!.sets, hasLength(1));
      expect(withSet.sets.single.isSynced, isTrue);
      expect(repository.loggedSets, hasLength(1));

      final result = await controller.finish();

      expect(result.synced, isTrue);
      expect(result.newPersonalRecords, [samplePersonalRecord]);
      expect(result.session.status, WorkoutSessionStatus.completed);
      // A finished, synced session no longer needs to linger as the
      // "active" session shown on the Workout tab.
      expect(container.read(workoutSessionControllerProvider), isNull);
    },
  );

  testWidgets(
    'offline: a workout started without a connection is saved locally and marked pending',
    (tester) async {
      final repository = FakeWorkoutSessionRepository()..failNetwork = true;
      final container = await createTestContainer(
        signedIn: true,
        workoutSessionRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpUntil(
        tester,
        () =>
            container.read(authControllerProvider).status != AuthStatus.unknown,
      );

      final controller = container.read(
        workoutSessionControllerProvider.notifier,
      );
      await controller.start(
        workoutPlanId: 'plan-1',
        workoutPlanName: 'Full Body Strength',
      );

      final session = container.read(workoutSessionControllerProvider);
      expect(session, isNotNull);
      expect(session!.serverId, isNull);
      expect(session.syncStatus, SessionSyncStatus.pending);
      expect(repository.startedSessionIds, isEmpty);

      // Logging still works entirely offline: the set is appended to local
      // state even though there is no serverId to push it to yet.
      await controller.logSet(
        exerciseId: 'exercise-bench-press',
        exerciseName: 'Bench Press',
        reps: 8,
        weightKg: 60,
      );
      final withSet = container.read(workoutSessionControllerProvider);
      expect(withSet!.sets, hasLength(1));
      expect(withSet.sets.single.isSynced, isFalse);
      expect(repository.loggedSets, isEmpty);
    },
  );

  testWidgets(
    'offline: finishing while offline keeps the session locally with a failed sync status, and retrying once online replays it',
    (tester) async {
      final repository = FakeWorkoutSessionRepository()..failNetwork = true;
      final container = await createTestContainer(
        signedIn: true,
        workoutSessionRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpUntil(
        tester,
        () =>
            container.read(authControllerProvider).status != AuthStatus.unknown,
      );

      final controller = container.read(
        workoutSessionControllerProvider.notifier,
      );
      await controller.start(
        workoutPlanId: 'plan-1',
        workoutPlanName: 'Full Body Strength',
      );
      await controller.logSet(
        exerciseId: 'exercise-bench-press',
        exerciseName: 'Bench Press',
        reps: 8,
        weightKg: 60,
      );

      final finishResult = await controller.finish();
      expect(finishResult.synced, isFalse);
      expect(finishResult.session.syncStatus, SessionSyncStatus.failed);
      // The unsynced session must still be visible (e.g. for the Summary
      // screen's retry banner) rather than silently discarded.
      expect(container.read(workoutSessionControllerProvider), isNotNull);

      repository.failNetwork = false;
      repository.nextPersonalRecords = [samplePersonalRecord];
      final retryResult = await controller.retrySync(finishResult.session);

      expect(retryResult.synced, isTrue);
      expect(retryResult.newPersonalRecords, [samplePersonalRecord]);
      // The replay path: since the session never got a serverId while
      // offline, retrying must create it now and push the pending set.
      expect(repository.startedSessionIds, hasLength(1));
      expect(repository.loggedSets, hasLength(1));
      expect(container.read(workoutSessionControllerProvider), isNull);
    },
  );

  testWidgets(
    'starting a second workout while one is already active is rejected',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      await _pumpUntil(
        tester,
        () =>
            container.read(authControllerProvider).status != AuthStatus.unknown,
      );

      final controller = container.read(
        workoutSessionControllerProvider.notifier,
      );
      await controller.start(
        workoutPlanId: 'plan-1',
        workoutPlanName: 'Full Body Strength',
      );

      await expectLater(
        controller.start(workoutPlanId: 'plan-1'),
        throwsA(isA<Exception>()),
      );
    },
  );
}
