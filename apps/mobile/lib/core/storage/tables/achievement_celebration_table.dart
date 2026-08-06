import 'package:drift/drift.dart';

/// A durable queue of newly earned achievements waiting to be celebrated —
/// see packages/docs/build-session-5.md's Part 2 write-up. A row is
/// inserted the moment the backend reports an achievement as newly earned
/// (workout finish, meal logging, cardio completion), independent of
/// whether the app is online, foregrounded, or about to be killed, and is
/// only deleted once its celebration has actually been shown — so a
/// celebration earned right before a restart still appears exactly once,
/// never zero times and never twice.
///
/// The primary key is `userId:achievementId` rather than just
/// `achievementId` — an achievement's catalog id (`Achievement.id`) is
/// global/shared across every user, so scoping by user prevents one
/// account's pending celebration from ever being misattributed to another
/// on a shared device.
class PendingCelebrations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get achievementId => text()();
  TextColumn get achievementKey => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get iconAsset => text()();
  TextColumn get category => text()();
  IntColumn get targetSteps => integer()();
  DateTimeColumn get earnedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
