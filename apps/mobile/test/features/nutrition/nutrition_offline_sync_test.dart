import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/core/sync/outbox_entry.dart';
import 'package:mobile/core/sync/outbox_store.dart';
import 'package:mobile/core/sync/sync_engine.dart';
import 'package:mobile/features/achievements/domain/achievement.dart';
import 'package:mobile/features/achievements/presentation/providers/achievement_celebration_controller.dart';
import 'package:mobile/features/nutrition/data/food_repository.dart'
    show CustomFoodInput;
import 'package:mobile/features/nutrition/data/water_repository.dart';
import 'package:mobile/features/nutrition/domain/food.dart';
import 'package:mobile/features/nutrition/domain/meal_entry.dart';
import 'package:mobile/features/nutrition/domain/meal_type.dart';
import 'package:mobile/features/nutrition/domain/water_entry.dart';
import 'package:mobile/features/nutrition/presentation/providers/food_controller.dart';
import 'package:mobile/features/nutrition/presentation/providers/meal_entry_controller.dart';
import 'package:mobile/features/nutrition/presentation/providers/water_controller.dart';
import 'package:path/path.dart' as p;

import '../../helpers/fake_nutrition_repositories.dart';

/// A [WaterRepository] whose calls fail with a network error until
/// [isOnline] is flipped — used to simulate "offline now, connectivity
/// returns later" without touching the real network stack.
class _FlakyWaterRepository implements WaterRepository {
  bool isOnline = false;
  int addEntryCalls = 0;
  final List<WaterEntry> _entries = [];

  @override
  Future<WaterEntry> addEntry({
    required DateTime date,
    required int amountMl,
    String? idempotencyKey,
  }) async {
    addEntryCalls++;
    if (!isOnline) throw AppException.network();
    final entry = WaterEntry(
      id: 'server-water-${_entries.length}',
      date: date,
      amountMl: amountMl,
      loggedAt: DateTime.now(),
    );
    _entries.add(entry);
    return entry;
  }

  @override
  Future<WaterEntry> updateEntry(String id, {required int amountMl}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEntry(String id) async {
    if (!isOnline) throw AppException.network();
  }

  @override
  Future<DailyWater> getDaily(DateTime date) async {
    if (!isOnline) throw AppException.network();
    return DailyWater(
      totalMl: _entries.fold(0, (sum, e) => sum + e.amountMl),
      entries: _entries,
    );
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ascend-nutrition-test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('offline meal creation', () {
    test(
      'writes to Drift and updates state immediately while offline',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final repository = FakeMealEntryRepository();
        final syncEngine = SyncEngine(store: OutboxStore(database));

        final controller = MealEntryController(
          repository: repository,
          database: database,
          syncEngine: syncEngine,
          userId: 'user-1',
          celebrationController: AchievementCelebrationController(
            database: database,
            userId: 'user-1',
          ),
        );
        addTearDown(controller.dispose);

        await controller.addEntry(
          food: sampleFood,
          mealType: MealType.breakfast,
          quantity: 2,
        );

        final state = controller.state;
        expect(state.value, hasLength(1));
        expect(state.value!.single.food.name, sampleFood.name);
        expect(state.value!.single.calories, sampleFood.caloriesPerServing * 2);

        final row = (await database.readMealEntriesOnce(
          'user-1',
          _todayIso(),
        )).single;
        expect(row.syncStatus, 'pendingCreate');
      },
    );
  });

  group('offline water logging', () {
    test('logs locally while offline, then syncs once back online', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = _FlakyWaterRepository();
      final syncEngine = SyncEngine(store: OutboxStore(database));

      final controller = WaterController(
        repository: repository,
        database: database,
        syncEngine: syncEngine,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await controller.addEntry(250);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.state.value!.totalMl, 250);
      expect(repository.addEntryCalls, greaterThanOrEqualTo(1));
      final rowsWhileOffline = await database.readWaterEntriesOnce(
        'user-1',
        _todayIso(),
      );
      expect(rowsWhileOffline.single.syncStatus, 'pendingCreate');

      // The automatic post-enqueue drain already failed once (offline) and
      // backed off — connectivity returning doesn't make it due again on
      // its own until that backoff elapses, so this uses the same manual
      // "Retry" the sync status indicator offers rather than waiting.
      repository.isOnline = true;
      await syncEngine.retryAllFailed();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final rowsAfterSync = await database.readWaterEntriesOnce(
        'user-1',
        _todayIso(),
      );
      expect(rowsAfterSync.single.syncStatus, 'synced');
      expect(rowsAfterSync.single.serverId, isNotNull);
    });
  });

  group('restart before sync', () {
    test(
      'a pending write survives closing and reopening the database',
      () async {
        final dbFile = File(p.join(tempDir.path, 'ascend.sqlite'));
        final firstDatabase = AppDatabase(NativeDatabase(dbFile));
        final repository = _FlakyWaterRepository(); // stays offline
        final firstSyncEngine = SyncEngine(store: OutboxStore(firstDatabase));

        final firstController = WaterController(
          repository: repository,
          database: firstDatabase,
          syncEngine: firstSyncEngine,
          userId: 'user-1',
        );
        await firstController.addEntry(500);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        firstController.dispose();
        await firstDatabase.close();

        // Simulate an app restart: a brand new AppDatabase/SyncEngine/
        // controller instance, reopening the same on-disk file. The new
        // controller's constructor re-registers the handler the engine needs
        // to actually replay the queued entry — exactly what happens when
        // the app process restarts and providers are rebuilt from scratch.
        final secondDatabase = AppDatabase(NativeDatabase(dbFile));
        addTearDown(secondDatabase.close);
        final secondSyncEngine = SyncEngine(store: OutboxStore(secondDatabase));
        final secondController = WaterController(
          repository: repository,
          database: secondDatabase,
          syncEngine: secondSyncEngine,
          userId: 'user-1',
        );
        addTearDown(secondController.dispose);

        final rows = await secondDatabase.readWaterEntriesOnce(
          'user-1',
          _todayIso(),
        );
        expect(rows, hasLength(1));
        expect(rows.single.syncStatus, 'pendingCreate');

        // The pre-restart automatic drain attempt failed offline (a
        // retryable NETWORK_ERROR) and backed off — still durably queued,
        // just in `failed` (awaiting its next due time or a manual retry)
        // rather than `pending`. Either way, nothing was lost across restart.
        final outboxEntries = await secondSyncEngine.watchEntries().first;
        expect(outboxEntries, hasLength(1));
        expect(outboxEntries.single.status, OutboxStatus.failed);

        // And it's still resumable after restart: connectivity returns, a
        // manual retry lands it.
        repository.isOnline = true;
        await secondSyncEngine.retryAllFailed();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final rowsAfterRetry = await secondDatabase.readWaterEntriesOnce(
          'user-1',
          _todayIso(),
        );
        expect(rowsAfterRetry.single.syncStatus, 'synced');
      },
    );
  });

  group('timeout then retry', () {
    test('a failed sync is retried and eventually completes', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = _FlakyWaterRepository();
      final syncEngine = SyncEngine(store: OutboxStore(database));

      final controller = WaterController(
        repository: repository,
        database: database,
        syncEngine: syncEngine,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await controller.addEntry(250);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repository.addEntryCalls, 1);

      // First manual retry attempt still offline — fails again, not a
      // duplicate create, and the row stays pending.
      final entries = await syncEngine.watchEntries().first;
      await syncEngine.retryNow(entries.single.id);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repository.addEntryCalls, 2);
      expect(
        (await database.readWaterEntriesOnce(
          'user-1',
          _todayIso(),
        )).single.syncStatus,
        'pendingCreate',
      );

      // Connectivity returns — the next retry succeeds.
      repository.isOnline = true;
      final entriesAgain = await syncEngine.watchEntries().first;
      await syncEngine.retryNow(entriesAgain.single.id);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.addEntryCalls, 3);
      expect(
        (await database.readWaterEntriesOnce(
          'user-1',
          _todayIso(),
        )).single.syncStatus,
        'synced',
      );
    });
  });

  group('duplicate batch delivery', () {
    test(
      'draining an already-completed entry never replays its handler',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final repository = FakeMealEntryRepository();
        final syncEngine = SyncEngine(store: OutboxStore(database));

        final controller = MealEntryController(
          repository: repository,
          database: database,
          syncEngine: syncEngine,
          userId: 'user-1',
          celebrationController: AchievementCelebrationController(
            database: database,
            userId: 'user-1',
          ),
        );
        addTearDown(controller.dispose);

        await controller.addEntry(
          food: sampleFood,
          mealType: MealType.breakfast,
          quantity: 1,
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final entriesAfterFirstSync = await database.readMealEntriesOnce(
          'user-1',
          _todayIso(),
        );
        expect(entriesAfterFirstSync.single.syncStatus, 'synced');
        final countAfterFirstSync = (await repository.listForDate(
          DateTime.now(),
        )).length;
        expect(countAfterFirstSync, 1);

        // A second drain pass (e.g. triggered again after a duplicate
        // "you're back online" signal) must not re-run a completed handler.
        await syncEngine.drain();
        await syncEngine.drain();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final countAfterExtraDrains = (await repository.listForDate(
          DateTime.now(),
        )).length;
        expect(countAfterExtraDrains, 1);
      },
    );
  });

  group('delete while offline', () {
    test(
      'deleting a never-synced entry discards it locally with no network call',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final repository = _AlwaysOfflineMealEntryRepository();
        final syncEngine = SyncEngine(store: OutboxStore(database));

        final controller = MealEntryController(
          repository: repository,
          database: database,
          syncEngine: syncEngine,
          userId: 'user-1',
          celebrationController: AchievementCelebrationController(
            database: database,
            userId: 'user-1',
          ),
        );
        addTearDown(controller.dispose);

        await controller.addEntry(
          food: sampleFood,
          mealType: MealType.breakfast,
          quantity: 1,
        );
        final localId = controller.state.value!.single.id;

        await controller.deleteEntry(localId);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(controller.state.value, isEmpty);
        expect(repository.deleteEntryCalls, 0);
        final outboxEntries = await syncEngine.watchEntries().first;
        expect(outboxEntries, isEmpty);
      },
    );
  });

  group('logout with pending operations', () {
    test(
      'clearAll wipes pending outbox entries and cached nutrition rows',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final repository = _AlwaysOfflineMealEntryRepository();
        final syncEngine = SyncEngine(store: OutboxStore(database));

        final controller = MealEntryController(
          repository: repository,
          database: database,
          syncEngine: syncEngine,
          userId: 'user-1',
          celebrationController: AchievementCelebrationController(
            database: database,
            userId: 'user-1',
          ),
        );
        addTearDown(controller.dispose);

        await controller.addEntry(
          food: sampleFood,
          mealType: MealType.breakfast,
          quantity: 1,
        );

        expect(await syncEngine.watchEntries().first, isNotEmpty);
        expect(
          await database.readMealEntriesOnce('user-1', _todayIso()),
          isNotEmpty,
        );

        await database.clearAll();

        expect(await syncEngine.watchEntries().first, isEmpty);
        expect(
          await database.readMealEntriesOnce('user-1', _todayIso()),
          isEmpty,
        );
      },
    );
  });

  group('switching accounts', () {
    test('one user never sees another user\'s cached nutrition rows', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repositoryA = FakeMealEntryRepository();
      final syncEngineA = SyncEngine(store: OutboxStore(database));
      final controllerA = MealEntryController(
        repository: repositoryA,
        database: database,
        syncEngine: syncEngineA,
        userId: 'user-a',
        celebrationController: AchievementCelebrationController(
          database: database,
          userId: 'user-a',
        ),
      );
      addTearDown(controllerA.dispose);

      await controllerA.addEntry(
        food: sampleFood,
        mealType: MealType.breakfast,
        quantity: 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final repositoryB = FakeMealEntryRepository();
      final syncEngineB = SyncEngine(store: OutboxStore(database));
      final controllerB = MealEntryController(
        repository: repositoryB,
        database: database,
        syncEngine: syncEngineB,
        userId: 'user-b',
        celebrationController: AchievementCelebrationController(
          database: database,
          userId: 'user-b',
        ),
      );
      addTearDown(controllerB.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controllerB.state.value, isEmpty);
      expect(
        await database.readMealEntriesOnce('user-b', _todayIso()),
        isEmpty,
      );
      expect(
        await database.readMealEntriesOnce('user-a', _todayIso()),
        isNotEmpty,
      );
    });
  });

  group('local-to-server ID reconciliation', () {
    test(
      'a food created offline reconciles to its server id, and a meal entry logged against it afterwards uses that id',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final foodRepository = FakeFoodRepository(seedFoods: []);
        // A mutable list the fake repository holds by reference, so it can
        // be extended once the food's server id is known below.
        final availableFoods = <Food>[];
        final mealEntryRepository = FakeMealEntryRepository(
          availableFoods: availableFoods,
        );
        final syncEngine = SyncEngine(store: OutboxStore(database));

        final foodController = CustomFoodController(
          repository: foodRepository,
          database: database,
          syncEngine: syncEngine,
          userId: 'user-1',
        );
        final mealEntryController = MealEntryController(
          repository: mealEntryRepository,
          database: database,
          syncEngine: syncEngine,
          userId: 'user-1',
          celebrationController: AchievementCelebrationController(
            database: database,
            userId: 'user-1',
          ),
        );
        addTearDown(mealEntryController.dispose);

        final localFood = await foodController.create(
          const CustomFoodInput(
            name: 'Homemade Soup',
            servingDescription: '1 bowl',
            caloriesPerServing: 220,
            proteinGramsPerServing: 12,
            carbGramsPerServing: 20,
            fatGramsPerServing: 8,
          ),
        );
        expect(localFood.id, startsWith('food-'));

        // Let the food's create sync (FakeFoodRepository assigns it a
        // different, server-style id — the same shape of change the real
        // backend makes when it accepts an offline-created custom food).
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final cachedFoods = await database.readCachedFoodsOnce('user-1');
        final reconciledFood = cachedFoods.single;
        expect(reconciledFood.id, isNot(localFood.id));
        expect(reconciledFood.syncStatus, 'synced');

        final reconciledFoodDomain = Food(
          id: reconciledFood.id,
          name: reconciledFood.name,
          isOwnedByCurrentUser: true,
          servingDescription: reconciledFood.servingDescription,
          caloriesPerServing: reconciledFood.caloriesPerServing,
          proteinGramsPerServing: reconciledFood.proteinGramsPerServing,
          carbGramsPerServing: reconciledFood.carbGramsPerServing,
          fatGramsPerServing: reconciledFood.fatGramsPerServing,
          isEstimated: true,
        );
        availableFoods.add(reconciledFoodDomain);

        await mealEntryController.addEntry(
          food: reconciledFoodDomain,
          mealType: MealType.lunch,
          quantity: 1,
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final mealRow = (await database.readMealEntriesOnce(
          'user-1',
          _todayIso(),
        )).single;
        expect(mealRow.foodId, reconciledFood.id);
      },
    );

    test(
      'reconcileFoodId rewrites an already-created meal entry that referenced the local id',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        await database.upsertCachedFood(
          const CachedFoodsCompanion(
            id: Value('local-food-1'),
            userId: Value('user-1'),
            name: Value('Homemade Soup'),
            sourceType: Value('USER'),
            servingDescription: Value('1 bowl'),
            caloriesPerServing: Value(220),
            proteinGramsPerServing: Value(12),
            carbGramsPerServing: Value(20),
            fatGramsPerServing: Value(8),
            syncStatus: Value('pendingCreate'),
          ).copyWith(updatedAt: Value(DateTime.now())),
        );
        await database.upsertMealEntry(
          CachedMealEntriesCompanion.insert(
            id: 'meal-1',
            userId: 'user-1',
            foodId: 'local-food-1',
            foodName: 'Homemade Soup',
            mealType: 'LUNCH',
            date: _todayIso(),
            quantity: 1,
            calories: 220,
            proteinGrams: 12,
            carbGrams: 20,
            fatGrams: 8,
            syncStatus: 'synced',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await database.reconcileFoodId('local-food-1', 'server-food-1');

        final mealRow = (await database.readMealEntriesOnce(
          'user-1',
          _todayIso(),
        )).single;
        expect(mealRow.foodId, 'server-food-1');
      },
    );
  });
}

String _todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

class _AlwaysOfflineMealEntryRepository extends FakeMealEntryRepository {
  int deleteEntryCalls = 0;

  @override
  Future<({MealEntry entry, List<Achievement> newAchievements})> addEntry({
    required String foodId,
    String? foodServingId,
    required MealType mealType,
    required DateTime date,
    required double quantity,
    String? idempotencyKey,
  }) async {
    throw AppException.network();
  }

  @override
  Future<void> deleteEntry(String id) async {
    deleteEntryCalls++;
    throw AppException.network();
  }
}
