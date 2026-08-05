import 'package:drift/drift.dart';

/// A single-row table exposing the offline layer's last-known sync state
/// to the UI (e.g. an "updated 2 minutes ago" indicator).
///
/// Named `SyncStatusRows` (not `SyncStatuses`) so Drift's generated
/// singular row class comes out as the clean `SyncStatusRow` rather than
/// the awkward `SyncStatuse`.
class SyncStatusRows extends Table {
  TextColumn get id => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isSyncing => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
