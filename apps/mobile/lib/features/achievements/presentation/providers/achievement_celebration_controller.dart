import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/achievement.dart';

Achievement _fromRow(PendingCelebration row) => Achievement(
  id: row.achievementId,
  key: row.achievementKey,
  title: row.title,
  description: row.description,
  iconAsset: row.iconAsset,
  category: achievementCategoryFromJson(row.category.toUpperCase()),
  targetSteps: row.targetSteps,
  progress: row.targetSteps,
  earnedAt: row.earnedAt,
);

/// Owns the durable, offline-first queue of newly earned achievements
/// waiting to be celebrated — see
/// `core/storage/tables/achievement_celebration_table.dart` and
/// packages/docs/build-session-5.md. Every trigger point (workout finish,
/// meal logging, cardio completion) calls [enqueue] with whatever the
/// backend reported as newly earned; [AchievementCelebrationOverlay] is
/// the sole consumer of [state], presenting one celebration at a time and
/// calling [markShown] once the user has seen it.
///
/// Deliberately not `.autoDispose` — see `todaysMealEntriesProvider`'s doc
/// comment in `meal_entry_controller.dart` for why a controller owning a
/// live Drift subscription needs to persist for the app session.
class AchievementCelebrationController
    extends StateNotifier<List<Achievement>> {
  AchievementCelebrationController({
    required AppDatabase database,
    required String userId,
  }) : _database = database,
       _userId = userId,
       super(const []) {
    _subscription = _database.watchPendingCelebrations(_userId).listen((rows) {
      state = rows.map(_fromRow).toList();
    });
  }

  final AppDatabase _database;
  final String _userId;
  StreamSubscription<List<PendingCelebration>>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  /// Durably queues every newly earned achievement. Safe to call with an
  /// empty list (the common case — most mutations earn nothing) or with
  /// achievements already queued (the row is a no-op upsert keyed by
  /// `userId:achievementId`, since an achievement can only ever be earned
  /// once — see `AchievementAward`'s `@@unique([userId, achievementId])`
  /// on the backend).
  Future<void> enqueue(List<Achievement> achievements) async {
    if (achievements.isEmpty || _userId.isEmpty) return;
    final now = DateTime.now();
    for (final achievement in achievements) {
      await _database.enqueueCelebration(
        PendingCelebrationsCompanion.insert(
          id: '$_userId:${achievement.id}',
          userId: _userId,
          achievementId: achievement.id,
          achievementKey: achievement.key,
          title: achievement.title,
          description: achievement.description,
          iconAsset: achievement.iconAsset,
          category: achievement.category.name,
          targetSteps: achievement.targetSteps,
          earnedAt: achievement.earnedAt ?? now,
          createdAt: now,
        ),
      );
    }
  }

  /// Removes a celebration from the queue once it's been shown (or
  /// explicitly dismissed) — deleting the row, not just flagging it, is
  /// what guarantees "appears once, even after restart."
  Future<void> markShown(String achievementId) async {
    await _database.markCelebrationShown('$_userId:$achievementId');
  }
}

final achievementCelebrationControllerProvider =
    StateNotifierProvider<AchievementCelebrationController, List<Achievement>>((
      ref,
    ) {
      final userId = ref.watch(
        authControllerProvider.select((s) => s.user?.id),
      );
      return AchievementCelebrationController(
        database: ref.watch(appDatabaseProvider),
        userId: userId ?? '',
      );
    });
