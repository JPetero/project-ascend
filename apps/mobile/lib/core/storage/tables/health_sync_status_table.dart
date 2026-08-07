import 'package:drift/drift.dart';

/// A local cache of "when did we last successfully sync this
/// (provider, metric) pair," keyed by `userId:provider:metric`. This is
/// what makes incremental sync actually incremental client-side: the
/// next sync reads samples from the platform starting at this
/// timestamp instead of re-reading the platform's entire history every
/// time. Independent of (and a client-side complement to) the backend's
/// own `HealthSyncCursor`, which is the source of truth for what's
/// actually been stored — this table only decides what to *ask the
/// platform for* next.
class CachedHealthSyncStatusRows extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get provider => text()();
  TextColumn get metric => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
