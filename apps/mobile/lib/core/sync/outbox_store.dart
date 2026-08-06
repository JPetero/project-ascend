import 'dart:convert';

import 'package:drift/drift.dart';

import '../storage/app_database.dart';
import 'outbox_entry.dart';

/// Drift-backed CRUD for the outbox table. Deliberately the only file in
/// `core/sync/` that imports Drift directly — [SyncEngine] and every
/// feature-side [SyncHandler] work with plain [OutboxEntry] values instead.
class OutboxStore {
  OutboxStore(this._db);

  final AppDatabase _db;

  static final DateTime _farFuture = DateTime.utc(9999);

  Future<void> enqueue({
    required String idempotencyKey,
    required String entityType,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.outboxEntryRows)
        .insertOnConflictUpdate(
          OutboxEntryRowsCompanion.insert(
            id: idempotencyKey,
            entityType: entityType,
            operationType: operationType,
            payloadJson: jsonEncode(payload),
            status: 'pending',
            createdAt: now,
            nextAttemptAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Entries ready to (re)attempt right now, oldest first — never returns
  /// an entry whose `nextAttemptAt` is still in the future, which is what
  /// keeps retries spaced out instead of hammering the API in a tight loop.
  Future<List<OutboxEntry>> dueEntries(DateTime now) async {
    final rows =
        await (_db.select(_db.outboxEntryRows)
              ..where(
                (t) =>
                    t.status.isIn(['pending', 'failed']) &
                    t.nextAttemptAt.isSmallerOrEqualValue(now),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(OutboxEntry.fromRow).toList();
  }

  Stream<List<OutboxEntry>> watchAll() {
    return (_db.select(_db.outboxEntryRows)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(OutboxEntry.fromRow).toList());
  }

  Future<void> markProcessing(String id) => _updateStatus(id, 'processing');

  Future<void> markCompleted(String id, {String? resultEntityId}) async {
    await (_db.update(
      _db.outboxEntryRows,
    )..where((t) => t.id.equals(id))).write(
      OutboxEntryRowsCompanion(
        status: const Value('completed'),
        resultEntityId: Value(resultEntityId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// `retryAt` null means "exhausted its retry budget, or a permanent
  /// error" — `nextAttemptAt` is pushed far into the future so [dueEntries]
  /// never picks the row back up on its own. The row stays `failed` until
  /// a human explicitly retries (resetting `nextAttemptAt` to now) or
  /// discards it — never an automatic infinite retry loop.
  Future<void> markFailed(
    String id, {
    required int retryCount,
    required String? errorMessage,
    required String? errorCode,
    DateTime? retryAt,
  }) async {
    await (_db.update(
      _db.outboxEntryRows,
    )..where((t) => t.id.equals(id))).write(
      OutboxEntryRowsCompanion(
        status: const Value('failed'),
        retryCount: Value(retryCount),
        lastErrorMessage: Value(errorMessage),
        lastErrorCode: Value(errorCode),
        nextAttemptAt: Value(retryAt ?? _farFuture),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Resets a `failed` entry back to `pending` with an immediate
  /// `nextAttemptAt` — the "manual retry" action in the sync status UI.
  Future<void> resetForManualRetry(String id) async {
    await (_db.update(
      _db.outboxEntryRows,
    )..where((t) => t.id.equals(id))).write(
      OutboxEntryRowsCompanion(
        status: const Value('pending'),
        nextAttemptAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> discard(String id) async {
    await (_db.delete(_db.outboxEntryRows)..where((t) => t.id.equals(id))).go();
  }

  Future<int> pendingCount() async {
    final rows = await (_db.select(
      _db.outboxEntryRows,
    )..where((t) => t.status.equals('pending'))).get();
    return rows.length;
  }

  Future<int> failedCount() async {
    final rows = await (_db.select(
      _db.outboxEntryRows,
    )..where((t) => t.status.equals('failed'))).get();
    return rows.length;
  }

  Future<void> _updateStatus(String id, String status) async {
    await (_db.update(
      _db.outboxEntryRows,
    )..where((t) => t.id.equals(id))).write(
      OutboxEntryRowsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
