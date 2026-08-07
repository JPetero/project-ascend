import 'package:drift/drift.dart';

/// A single-row cache of the current live-GPS cardio session — whatever
/// is tracking, paused, or finished-but-not-yet-synced. Mirrors
/// `CachedWorkoutSessionRows` exactly: only one live cardio session can
/// be active at a time, a singleton row is enough, and it's what makes
/// interrupted-session recovery possible — if the app is killed mid-run,
/// relaunching reads this row back instead of losing the in-progress
/// route. Cleared once the session is confirmed synced (or discarded).
class CachedCardioSessionRows extends Table {
  TextColumn get id => text()();
  TextColumn get sessionJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
