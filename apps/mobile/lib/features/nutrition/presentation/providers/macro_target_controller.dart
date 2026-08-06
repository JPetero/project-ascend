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
import '../../data/macro_target_repository.dart';
import '../../domain/macro_target.dart';

const _upsertEntityType = 'nutrition.macro_target.upsert';

const _defaultDisclaimer =
    'These targets are a general estimate, not personalized or medical '
    'advice — talk to a qualified professional for guidance specific to '
    'you.';

MacroTarget _fromRow(CachedMacroTarget row) => MacroTarget(
  calorieTarget: row.calorieTarget,
  proteinGramsTarget: row.proteinGramsTarget,
  carbGramsTarget: row.carbGramsTarget,
  fatGramsTarget: row.fatGramsTarget,
  fiberGramsTarget: row.fiberGramsTarget,
  isEstimatedDefault: row.isEstimatedDefault,
  disclaimer: row.disclaimer,
  updatedAt: row.updatedAt,
);

/// Offline-first, mirroring [MealEntryController] — a single row per user,
/// so there's never an ambiguity about which target is "current" the way
/// there is for a list. If this device has never successfully fetched a
/// target (first launch, offline), there's nothing to show yet — the
/// safe-default estimate is computed server-side from profile data, and
/// this app never fabricates that number locally.
class MacroTargetController extends StateNotifier<AsyncValue<MacroTarget>> {
  MacroTargetController({
    required MacroTargetRepository repository,
    required AppDatabase database,
    required SyncEngine syncEngine,
    required String userId,
  }) : _repository = repository,
       _database = database,
       _syncEngine = syncEngine,
       _userId = userId,
       super(const AsyncValue.loading()) {
    _registerHandlers();
    _subscription = _database.watchMacroTarget(_userId).listen((row) {
      if (row != null) {
        state = AsyncValue.data(_fromRow(row));
      }
    });
    unawaited(_refreshFromServer());
  }

  final MacroTargetRepository _repository;
  final AppDatabase _database;
  final SyncEngine _syncEngine;
  final String _userId;
  StreamSubscription<CachedMacroTarget?>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _refreshFromServer() async {
    try {
      final target = await _repository.get();
      final existing = await _database.readMacroTargetOnce(_userId);
      if (existing != null && existing.syncStatus != 'synced') return;
      await _database.upsertMacroTarget(_syncedCompanion(target));
    } on AppException catch (error) {
      if (await _database.readMacroTargetOnce(_userId) == null) {
        state = AsyncValue.error(error, StackTrace.current);
      }
    }
  }

  CachedMacroTargetsCompanion _syncedCompanion(MacroTarget target) {
    return CachedMacroTargetsCompanion.insert(
      userId: _userId,
      calorieTarget: target.calorieTarget,
      proteinGramsTarget: target.proteinGramsTarget,
      carbGramsTarget: target.carbGramsTarget,
      fatGramsTarget: target.fatGramsTarget,
      fiberGramsTarget: Value(target.fiberGramsTarget),
      isEstimatedDefault: Value(target.isEstimatedDefault),
      disclaimer: target.disclaimer,
      syncStatus: const Value('synced'),
      updatedAt: DateTime.now(),
    );
  }

  void _registerHandlers() {
    _syncEngine.registerHandler(
      _upsertEntityType,
      FunctionSyncHandler(({required payload, required idempotencyKey}) async {
        try {
          final result = await _repository.upsert(
            MacroTargetInput(
              calorieTarget: payload['calorieTarget'] as int,
              proteinGramsTarget: payload['proteinGramsTarget'] as int,
              carbGramsTarget: payload['carbGramsTarget'] as int,
              fatGramsTarget: payload['fatGramsTarget'] as int,
              fiberGramsTarget: payload['fiberGramsTarget'] as int?,
            ),
          );
          await _database.upsertMacroTarget(_syncedCompanion(result));
          return const SyncHandlerResult(entityId: null, response: {});
        } on AppException catch (error) {
          throw SyncFailure(message: error.message, code: error.code);
        }
      }),
    );
  }

  Future<void> upsert(MacroTargetInput input) async {
    final existing = await _database.readMacroTargetOnce(_userId);
    await _database.upsertMacroTarget(
      CachedMacroTargetsCompanion.insert(
        userId: _userId,
        calorieTarget: input.calorieTarget,
        proteinGramsTarget: input.proteinGramsTarget,
        carbGramsTarget: input.carbGramsTarget,
        fatGramsTarget: input.fatGramsTarget,
        fiberGramsTarget: Value(input.fiberGramsTarget),
        isEstimatedDefault: const Value(false),
        disclaimer: existing?.disclaimer ?? _defaultDisclaimer,
        syncStatus: const Value('pendingUpdate'),
        updatedAt: DateTime.now(),
      ),
    );

    await _syncEngine.enqueue(
      idempotencyKey: generateIdempotencyKey('macro-target-upsert'),
      entityType: _upsertEntityType,
      operationType: 'UPDATE',
      payload: input.toJson(),
    );
  }
}

final macroTargetRepositoryProvider = Provider<MacroTargetRepository>((ref) {
  return MacroTargetRepository(apiClient: ref.watch(apiClientProvider));
});

/// The user's current macro targets, offline-first — see
/// [MacroTargetController]. Not `.autoDispose` — see the doc comment on
/// `todaysMealEntriesProvider`.
final macroTargetProvider =
    StateNotifierProvider<MacroTargetController, AsyncValue<MacroTarget>>((
      ref,
    ) {
      final userId = ref.watch(
        authControllerProvider.select((s) => s.user?.id),
      );
      return MacroTargetController(
        repository: ref.watch(macroTargetRepositoryProvider),
        database: ref.watch(appDatabaseProvider),
        syncEngine: ref.watch(syncEngineProvider),
        userId: userId ?? '',
      );
    });
