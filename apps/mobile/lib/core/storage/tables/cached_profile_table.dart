import 'package:drift/drift.dart';

/// A single-row-per-user cache of the signed-in user's profile, stored as
/// JSON so the offline layer doesn't need to track every backend field.
class CachedProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get profileJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
