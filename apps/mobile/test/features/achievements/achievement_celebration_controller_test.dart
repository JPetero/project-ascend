import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/features/achievements/domain/achievement.dart';
import 'package:mobile/features/achievements/presentation/providers/achievement_celebration_controller.dart';

Achievement _achievement(String id, {int targetSteps = 1}) => Achievement(
  id: id,
  key: id,
  title: 'Title $id',
  description: 'Description $id',
  iconAsset: 'medal',
  category: AchievementCategory.workout,
  targetSteps: targetSteps,
  progress: targetSteps,
  earnedAt: DateTime.utc(2026, 8, 6),
);

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'immediate online award — enqueuing surfaces the achievement in state right away',
    () async {
      final controller = AchievementCelebrationController(
        database: db,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      expect(controller.state, isEmpty);

      await controller.enqueue([_achievement('ach-1')]);
      // The queue is backed by a Drift stream — pump the microtask queue so
      // the watcher's first emission lands before asserting.
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.map((a) => a.id), ['ach-1']);
    },
  );

  test(
    'delayed offline award — a celebration queued before the controller existed is picked up on construction',
    () async {
      // Simulates completing a workout/meal/cardio session while offline:
      // the row lands in Drift with no controller alive to react to it yet.
      await db.enqueueCelebration(
        PendingCelebrationsCompanion.insert(
          id: 'user-1:ach-offline',
          userId: 'user-1',
          achievementId: 'ach-offline',
          achievementKey: 'ach-offline',
          title: 'Offline Title',
          description: 'Offline Description',
          iconAsset: 'medal',
          category: AchievementCategory.workout.name,
          targetSteps: 1,
          earnedAt: DateTime.utc(2026, 8, 6),
          createdAt: DateTime.utc(2026, 8, 6),
        ),
      );

      final controller = AchievementCelebrationController(
        database: db,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.map((a) => a.id), ['ach-offline']);
    },
  );

  test(
    'multiple simultaneous achievements — all are queued and preserved in order',
    () async {
      final controller = AchievementCelebrationController(
        database: db,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await controller.enqueue([
        _achievement('ach-1'),
        _achievement('ach-2'),
        _achievement('ach-3'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.map((a) => a.id), ['ach-1', 'ach-2', 'ach-3']);
    },
  );

  test(
    'no duplicate celebration — re-enqueuing the same achievement id does not add a second entry',
    () async {
      final controller = AchievementCelebrationController(
        database: db,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await controller.enqueue([_achievement('ach-1')]);
      await controller.enqueue([_achievement('ach-1')]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.map((a) => a.id), ['ach-1']);

      await controller.markShown('ach-1');
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, isEmpty);
    },
  );

  test(
    'restart before viewing — a celebration not yet shown survives across controller instances, and stops reappearing once shown',
    () async {
      final before = AchievementCelebrationController(
        database: db,
        userId: 'user-1',
      );
      await before.enqueue([_achievement('ach-1')]);
      await Future<void>.delayed(Duration.zero);
      expect(before.state.map((a) => a.id), ['ach-1']);
      // No markShown call — simulates the app being killed before the
      // celebration was ever presented.
      before.dispose();

      final afterRestart = AchievementCelebrationController(
        database: db,
        userId: 'user-1',
      );
      addTearDown(afterRestart.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(
        afterRestart.state.map((a) => a.id),
        ['ach-1'],
        reason: 'a celebration earned before restart must still appear once',
      );

      // Now it is actually shown and dismissed.
      await afterRestart.markShown('ach-1');
      await Future<void>.delayed(Duration.zero);
      expect(afterRestart.state, isEmpty);

      // A second restart after being shown must not replay it.
      final afterSecondRestart = AchievementCelebrationController(
        database: db,
        userId: 'user-1',
      );
      addTearDown(afterSecondRestart.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(afterSecondRestart.state, isEmpty);
    },
  );

  test(
    'enqueue is a no-op for an empty list or an unauthenticated (empty) user id',
    () async {
      final controller = AchievementCelebrationController(
        database: db,
        userId: '',
      );
      addTearDown(controller.dispose);

      await controller.enqueue([_achievement('ach-1')]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, isEmpty);
    },
  );
}
