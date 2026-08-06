import 'package:drift/drift.dart';

/// A durable, generic queue of not-yet-confirmed mutations — the local half
/// of the backend's idempotency protocol (`SyncOperation` /
/// `IdempotencyService`, see `services/api/src/common/idempotency`).
///
/// Deliberately feature-agnostic: `entityType` is a free-form string (e.g.
/// `'workout.substitution'`, `'workout.plan.create'`, and eventually
/// `'nutrition.mealEntry'`) that the [SyncEngine]'s handler registry uses to
/// route a row to the code that knows how to replay it — nothing in this
/// table or the engine that drains it is workout-specific. An entry is only
/// ever deleted after the server has confirmed success; a crash or restart
/// mid-flight just leaves it `pending`/`processing` for the next drain pass
/// to pick back up.
///
/// Named `OutboxEntryRows` (not `OutboxEntries`) so Drift's generated
/// singular row data class comes out as `OutboxEntryRow` rather than
/// `OutboxEntry` — the latter would collide with this package's own
/// hand-written [OutboxEntry] domain model.
class OutboxEntryRows extends Table {
  /// The idempotency key itself — also the primary key, so enqueueing twice
  /// with the same key (e.g. a UI double-submit) can never create two rows.
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get operationType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status =>
      text()(); // pending | processing | completed | failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorMessage => text().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get resultEntityId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
