import 'package:drift/drift.dart';

/// A single-row-per-user cache of the last dashboard payload (or, in
/// Sprint 1, the development sample-data fixture) so the home screen has
/// something to render immediately while a fresh fetch is in flight.
class CachedDashboardFixtures extends Table {
  TextColumn get userId => text()();
  TextColumn get dashboardJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
