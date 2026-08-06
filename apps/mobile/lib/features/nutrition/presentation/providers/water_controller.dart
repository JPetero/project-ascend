import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/sync/idempotency_key.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/sync/sync_handler.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/meal_entry_repository.dart' show formatDateOnly;
import '../../data/water_repository.dart';
import '../../domain/water_entry.dart';

const _createEntityType = 'nutrition.water_entry.create';
const _updateEntityType = 'nutrition.water_entry.update';
const _deleteEntityType = 'nutrition.water_entry.delete';

String _todayKey() {
  final now = DateTime.now();
  return formatDateOnly(DateTime(now.year, now.month, now.day));
}

WaterEntry _fromRow(CachedWaterEntry row) => WaterEntry(
  id: row.id,
  date: DateTime.parse(row.date),
  amountMl: row.amountMl,
  loggedAt: row.loggedAt,
);

/// Offline-first, mirroring [MealEntryController] — see
/// packages/docs/build-session-5.md.
class WaterController extends StateNotifier<AsyncValue<DailyWater>> {
  WaterController({
    required WaterRepository repository,
    required AppDatabase database,
    required SyncEngine syncEngine,
    required String userId,
  }) : _repository = repository,
       _database = database,
       _syncEngine = syncEngine,
       _userId = userId,
       super(const AsyncValue.loading()) {
    _registerHandlers();
    _subscription = _database.watchWaterEntries(_userId, _todayKey()).listen((
      rows,
    ) {
      final entries = rows.map(_fromRow).toList();
      final totalMl = entries.fold<int>(0, (sum, e) => sum + e.amountMl);
      state = AsyncValue.data(DailyWater(totalMl: totalMl, entries: entries));
    });
    unawaited(_refreshFromServer());
  }

  final WaterRepository _repository;
  final AppDatabase _database;
  final SyncEngine _syncEngine;
  final String _userId;
  StreamSubscription<List<CachedWaterEntry>>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> refresh() => _refreshFromServer();

  Future<void> _refreshFromServer() async {
    try {
      final daily = await _repository.getDaily(DateTime.now());
      final localRows = await _database.readWaterEntriesOnce(
        _userId,
        _todayKey(),
      );
      final serverIds = daily.entries.map((e) => e.id).toSet();

      for (final entry in daily.entries) {
        CachedWaterEntry? existing;
        for (final row in localRows) {
          if (row.serverId == entry.id || row.id == entry.id) {
            existing = row;
            break;
          }
        }
        if (existing != null && existing.syncStatus != 'synced') continue;
        await _database.upsertWaterEntry(
          _syncedCompanion(existing?.id ?? entry.id, entry),
        );
      }
      for (final row in localRows) {
        if (row.syncStatus == 'synced' &&
            row.serverId != null &&
            !serverIds.contains(row.serverId)) {
          await _database.deleteWaterEntryRow(row.id);
        }
      }
    } on AppException {
      // Offline, or the server errored — the cache already emitted via the
      // watch stream is what the UI shows.
    }
  }

  CachedWaterEntriesCompanion _syncedCompanion(
    String localId,
    WaterEntry entry,
  ) {
    return CachedWaterEntriesCompanion.insert(
      id: localId,
      serverId: Value(entry.id),
      userId: _userId,
      date: formatDateOnly(entry.date),
      amountMl: entry.amountMl,
      loggedAt: entry.loggedAt,
      syncStatus: 'synced',
      updatedAt: DateTime.now(),
    );
  }

  void _registerHandlers() {
    _syncEngine.registerHandler(
      _createEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final result = await _repository.addEntry(
            date: DateTime.parse(payload['date'] as String),
            amountMl: payload['amountMl'] as int,
            idempotencyKey: idempotencyKey,
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertWaterEntry(
            _syncedCompanion(localRowId, result),
          );
          return SyncHandlerResult(entityId: result.id, response: const {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );

    _syncEngine.registerHandler(
      _updateEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final result = await _repository.updateEntry(
            payload['id'] as String,
            amountMl: payload['amountMl'] as int,
          );
          final localRowId = payload['localRowId'] as String;
          await _database.upsertWaterEntry(
            _syncedCompanion(localRowId, result),
          );
          return SyncHandlerResult(entityId: result.id, response: const {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );

    _syncEngine.registerHandler(
      _deleteEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        final localRowId = payload['localRowId'] as String;
        try {
          await _repository.deleteEntry(payload['id'] as String);
        } on AppException catch (error) {
          if (error.code != 'NOT_FOUND') {
            throw SyncFailure(message: error.message, code: error.code);
          }
        }
        await _database.deleteWaterEntryRow(localRowId);
        return const SyncHandlerResult(entityId: null, response: {});
      }),
    );
  }

  Future<void> addEntry(int amountMl) async {
    final localId = generateIdempotencyKey('water-entry');
    final now = DateTime.now();
    final date = _todayKey();

    await _database.upsertWaterEntry(
      CachedWaterEntriesCompanion.insert(
        id: localId,
        userId: _userId,
        date: date,
        amountMl: amountMl,
        loggedAt: now,
        syncStatus: 'pendingCreate',
        updatedAt: now,
      ),
    );

    await _syncEngine.enqueue(
      idempotencyKey: localId,
      entityType: _createEntityType,
      operationType: 'CREATE',
      payload: {'date': date, 'amountMl': amountMl, 'localRowId': localId},
    );
  }

  Future<void> updateEntry(String id, {required int amountMl}) async {
    final row = await _database.readWaterEntry(id);
    if (row == null) return;

    await _database.upsertWaterEntry(
      CachedWaterEntriesCompanion(
        id: Value(id),
        amountMl: Value(amountMl),
        syncStatus: Value(
          row.syncStatus == 'pendingCreate' ? 'pendingCreate' : 'pendingUpdate',
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (row.syncStatus == 'pendingCreate') {
      await _syncEngine.enqueue(
        idempotencyKey: id,
        entityType: _createEntityType,
        operationType: 'CREATE',
        payload: {'date': row.date, 'amountMl': amountMl, 'localRowId': id},
      );
      return;
    }

    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('water-entry-update'),
      entityType: _updateEntityType,
      operationType: 'UPDATE',
      payload: {'id': row.serverId, 'localRowId': id, 'amountMl': amountMl},
    );
  }

  Future<void> deleteEntry(String id) async {
    final row = await _database.readWaterEntry(id);
    if (row == null) return;

    if (row.serverId == null) {
      await _database.deleteWaterEntryRow(id);
      await _syncEngine.discard(id);
      return;
    }

    await _database.upsertWaterEntry(
      CachedWaterEntriesCompanion(
        id: Value(id),
        syncStatus: const Value('pendingDelete'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('water-entry-delete'),
      entityType: _deleteEntityType,
      operationType: 'DELETE',
      payload: {'id': row.serverId, 'localRowId': id},
    );
  }
}

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository(apiClient: ref.watch(apiClientProvider));
});

/// Today's logged water, offline-first — see [WaterController]. Not
/// `.autoDispose` — see the doc comment on `todaysMealEntriesProvider`.
final todaysWaterProvider =
    StateNotifierProvider<WaterController, AsyncValue<DailyWater>>((ref) {
      final userId = ref.watch(
        authControllerProvider.select((s) => s.user?.id),
      );
      return WaterController(
        repository: ref.watch(waterRepositoryProvider),
        database: ref.watch(appDatabaseProvider),
        syncEngine: ref.watch(syncEngineProvider),
        userId: userId ?? '',
      );
    });
