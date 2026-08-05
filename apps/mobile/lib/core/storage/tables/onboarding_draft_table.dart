import 'package:drift/drift.dart';

/// Preserves in-progress onboarding form state locally so a user who
/// backgrounds or force-quits the app mid-flow doesn't lose their answers.
class OnboardingDrafts extends Table {
  TextColumn get id => text()();
  IntColumn get step => integer()();
  TextColumn get draftJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
