import 'package:drift/drift.dart';

/// A single-row cache of the current workout session — whatever is
/// in-progress, paused, or finished-but-not-yet-synced. Only one session
/// can be active at a time (mirrors the backend's one-active-session-per-
/// user rule), so a singleton row is enough; it's cleared once the session
/// is confirmed fully synced. This is what makes workout logging keep
/// working with no network at all: the player only ever reads/writes this
/// table directly, never blocking on the backend.
class CachedWorkoutSessionRows extends Table {
  TextColumn get id => text()();
  TextColumn get sessionJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
