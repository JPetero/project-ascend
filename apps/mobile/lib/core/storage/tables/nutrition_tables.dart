import 'package:drift/drift.dart';

/// Offline-first Nutrition cache — see
/// packages/docs/build-session-5.md for the design writeup. Every table
/// below plays the same "local-first" role `CachedWorkoutSessionRows` plays
/// for Workout: the UI reads and writes here first, and the [SyncEngine]
/// (shared, unmodified — see core/sync/) reconciles with the backend in the
/// background using these rows' `id` as the outbox idempotency key.
///
/// `syncStatus` is one of `'synced' | 'pendingCreate' | 'pendingUpdate' |
/// 'pendingDelete'` on every row that can be locally mutated.
/// `'pendingDelete'` rows are tombstones: hidden from reads, kept until the
/// server confirms the delete, then removed for real.
///
/// Every table carries `userId` so switching accounts (even without an
/// explicit sign-out that would run `AppDatabase.clearAll()`) can never
/// surface another user's cached nutrition data — the same defense-in-depth
/// precedent `WorkoutSessionController._restore()` already applies to the
/// cached workout session.
class CachedFoods extends Table {
  /// Local id (an idempotency key) until synced, then the server id —
  /// reconciled in place by [reconcileFoodId] so anything referencing this
  /// row by id (a meal entry, a saved-meal item) can be updated too.
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get alternateName => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get sourceType => text()(); // SEED | USER
  BoolColumn get isOwnedByCurrentUser =>
      boolean().withDefault(const Constant(false))();
  TextColumn get servingDescription => text()();
  RealColumn get servingGrams => real().nullable()();
  RealColumn get caloriesPerServing => real()();
  RealColumn get proteinGramsPerServing => real()();
  RealColumn get carbGramsPerServing => real()();
  RealColumn get fatGramsPerServing => real()();
  RealColumn get fiberGramsPerServing => real().nullable()();
  RealColumn get sodiumMgPerServing => real().nullable()();
  BoolColumn get isEstimated => boolean().withDefault(const Constant(true))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedFoodServings extends Table {
  TextColumn get id => text()();
  TextColumn get foodId => text()();
  TextColumn get label => text()();
  RealColumn get grams => real().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedMealEntries extends Table {
  /// Local id until synced; [serverId] holds the authoritative id once the
  /// create has landed. Kept distinct (rather than overwriting [id]) so a
  /// delete enqueued against a not-yet-synced row can still find its own
  /// outbox entry (same id) to discard outright instead of sending a
  /// network call for something the server has never heard of.
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get foodId => text()();
  TextColumn get foodName => text()();
  TextColumn get foodBrand => text().nullable()();
  BoolColumn get foodIsEstimated =>
      boolean().withDefault(const Constant(true))();
  TextColumn get foodServingId => text().nullable()();
  TextColumn get foodServingLabel => text().nullable()();
  TextColumn get mealType => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  RealColumn get quantity => real()();
  RealColumn get calories => real()();
  RealColumn get proteinGrams => real()();
  RealColumn get carbGrams => real()();
  RealColumn get fatGrams => real()();
  RealColumn get fiberGrams => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedSavedMeals extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get name => text()();

  /// Encoded `List<Map>` of `{id, foodId, foodName, foodBrand,
  /// foodIsEstimated, foodServingId, foodServingLabel, quantity}` — items
  /// are only ever read/written as a whole, so a nested table would add
  /// join complexity with no real benefit here.
  TextColumn get itemsJson => text()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedWaterEntries extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  IntColumn get amountMl => integer()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per user — mirrors the backend's `MacroTarget` 1:1-with-user
/// shape, so there's never an ambiguity about which row is "current."
class CachedMacroTargets extends Table {
  TextColumn get userId => text()();
  IntColumn get calorieTarget => integer()();
  IntColumn get proteinGramsTarget => integer()();
  IntColumn get carbGramsTarget => integer()();
  IntColumn get fatGramsTarget => integer()();
  IntColumn get fiberGramsTarget => integer().nullable()();
  BoolColumn get isEstimatedDefault =>
      boolean().withDefault(const Constant(false))();
  TextColumn get disclaimer => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
