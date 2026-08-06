import 'dart:async';

import 'outbox_entry.dart';
import 'outbox_store.dart';
import 'retry_policy.dart';
import 'sync_handler.dart';
import 'sync_status.dart';

/// Generic, feature-agnostic offline mutation queue: enqueue now, sync
/// later, replay safely no matter how many times a request actually reaches
/// the server. This is the Flutter-side half of the same idempotency
/// protocol the backend already implements
/// (`services/api/src/common/idempotency`) — every outbox row's id *is*
/// the idempotency key sent with the replayed request, so a duplicate send
/// (retry, duplicate enqueue, app restart mid-flight) can never create a
/// duplicate server-side record.
///
/// Feature modules register one [SyncHandler] per `entityType` via
/// [registerHandler] and otherwise never touch the outbox directly. Nothing
/// here is workout-specific — this is exactly the "Sync" shared domain
/// package the Nutrition feature is expected to reuse rather than building
/// its own queue/retry/idempotency mechanism from scratch.
class SyncEngine {
  SyncEngine({
    required OutboxStore store,
    RetryPolicy retryPolicy = const RetryPolicy(),
  }) : _store = store,
       _retryPolicy = retryPolicy;

  final OutboxStore _store;
  final RetryPolicy _retryPolicy;
  final Map<String, SyncHandler> _handlers = {};
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _status = const SyncStatus.idle();
  SyncStatus get status => _status;
  Stream<SyncStatus> get statusStream => _statusController.stream;

  bool _draining = false;
  Timer? _scheduledDrain;

  void registerHandler(String entityType, SyncHandler handler) {
    _handlers[entityType] = handler;
  }

  /// Persists the mutation locally (so it survives a crash/restart even if
  /// nothing below succeeds) and then immediately attempts to drain the
  /// queue once, for a snappy "usually syncs right away" feel when online.
  Future<void> enqueue({
    required String idempotencyKey,
    required String entityType,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    await _store.enqueue(
      idempotencyKey: idempotencyKey,
      entityType: entityType,
      operationType: operationType,
      payload: payload,
    );
    await refreshStatus();
    unawaited(drain());
  }

  /// Attempts every due entry once each. Safe to call repeatedly (e.g. on
  /// app start, on pull-to-refresh, after regaining connectivity) — a
  /// concurrent call while a drain is already running is a no-op rather
  /// than a second overlapping pass.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    _status = _status.copyWith(isSyncing: true);
    _statusController.add(_status);

    try {
      final due = await _store.dueEntries(DateTime.now());
      for (final entry in due) {
        await _processOne(entry);
      }
    } finally {
      _draining = false;
      await refreshStatus();
      _scheduleNextDrainIfNeeded();
    }
  }

  Future<void> _processOne(OutboxEntry entry) async {
    final handler = _handlers[entry.entityType];
    if (handler == null) {
      // No feature has registered a handler for this entityType yet (e.g.
      // an app version mismatch after a rollback) — nothing productive to
      // do but leave it for a later drain rather than lose it.
      return;
    }

    await _store.markProcessing(entry.id);

    try {
      final result = await handler.send(
        payload: entry.payload,
        idempotencyKey: entry.id,
      );
      await _store.markCompleted(entry.id, resultEntityId: result.entityId);
    } on SyncFailure catch (failure) {
      final retryable = isRetryableErrorCode(failure.code);
      final nextRetryCount = entry.retryCount + 1;
      final hasBudget =
          retryable && _retryPolicy.hasAttemptsRemaining(entry.retryCount);

      await _store.markFailed(
        entry.id,
        retryCount: nextRetryCount,
        errorMessage: failure.message,
        errorCode: failure.code,
        retryAt: hasBudget
            ? DateTime.now().add(_retryPolicy.delayFor(entry.retryCount))
            : null,
      );
    }
  }

  void _scheduleNextDrainIfNeeded() {
    _scheduledDrain?.cancel();
    if (_status.pendingCount == 0) return;
    // A conservative fixed re-check rather than tracking every entry's
    // individual nextAttemptAt — simple, and still never a tight loop
    // since it only fires when there's known outstanding work.
    _scheduledDrain = Timer(const Duration(seconds: 30), () {
      unawaited(drain());
    });
  }

  Future<void> refreshStatus() async {
    final pending = await _store.pendingCount();
    final failed = await _store.failedCount();
    _status = SyncStatus(
      isSyncing: _draining,
      pendingCount: pending,
      failedCount: failed,
    );
    _statusController.add(_status);
  }

  Future<void> retryNow(String entryId) async {
    await _store.resetForManualRetry(entryId);
    await refreshStatus();
    unawaited(drain());
  }

  Future<void> discard(String entryId) async {
    await _store.discard(entryId);
    await refreshStatus();
  }

  /// The sync status indicator's "Retry all" action — resets every failed
  /// entry back to pending and drains once.
  Future<void> retryAllFailed() async {
    final entries = await _store.watchAll().first;
    for (final entry in entries) {
      if (entry.status == OutboxStatus.failed) {
        await _store.resetForManualRetry(entry.id);
      }
    }
    await refreshStatus();
    unawaited(drain());
  }

  Stream<List<OutboxEntry>> watchEntries() => _store.watchAll();

  void dispose() {
    _scheduledDrain?.cancel();
    unawaited(_statusController.close());
  }
}

/// Thrown by a [SyncHandler] to report a failed replay attempt. `code`
/// should be one of the backend's error codes (`NETWORK_ERROR`,
/// `VALIDATION_ERROR`, ...) when available, so the engine's retry policy
/// can tell a transient failure from a permanent one.
class SyncFailure implements Exception {
  const SyncFailure({required this.message, this.code});

  final String message;
  final String? code;
}
