import 'package:drift/drift.dart';

/// A single-row-per-user cache of the signed-in user's app preferences.
class CachedPreferencesTable extends Table {
  TextColumn get userId => text()();
  TextColumn get preferencesJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
