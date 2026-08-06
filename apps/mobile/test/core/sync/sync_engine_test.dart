import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/app_database.dart';
import 'package:mobile/core/sync/outbox_entry.dart';
import 'package:mobile/core/sync/outbox_store.dart';
import 'package:mobile/core/sync/retry_policy.dart';
import 'package:mobile/core/sync/sync_engine.dart';
import 'package:mobile/core/sync/sync_handler.dart';

class _RecordingHandler implements SyncHandler {
  final List<String> receivedKeys = [];
  final List<Map<String, dynamic>> receivedPayloads = [];
  int callCount = 0;

  /// Set to control the outcome of the *next* call — a queue of
  /// results/failures consumed in order, defaulting to success once
  /// exhausted.
  final List<Object> outcomes = [];

  @override
  Future<SyncHandlerResult> send({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    callCount++;
    receivedKeys.add(idempotencyKey);
    receivedPayloads.add(payload);

    if (outcomes.isNotEmpty) {
      final outcome = outcomes.removeAt(0);
      if (outcome is SyncFailure) throw outcome;
    }
    return SyncHandlerResult(entityId: 'server-id', response: const {});
  }
}

void main() {
  late AppDatabase db;
  late OutboxStore store;
  late SyncEngine engine;
  late _RecordingHandler handler;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = OutboxStore(db);
    engine = SyncEngine(
      store: store,
      retryPolicy: const RetryPolicy(
        baseDelay: Duration(milliseconds: 1),
        maxDelay: Duration(milliseconds: 5),
        maxAttempts: 2,
      ),
    );
    handler = _RecordingHandler();
    engine.registerHandler('test.entity', handler);
  });

  tearDown(() async {
    await db.close();
  });

  test('drain replays a pending entry through its registered handler and marks it completed', () async {
    // Enqueued directly on the store (not via engine.enqueue(), which
    // fires an un-awaited background drain) so this test controls exactly
    // when draining happens.
    await store.enqueue(
      idempotencyKey: 'key-1',
      entityType: 'test.entity',
      operationType: 'CREATE',
      payload: {'foo': 'bar'},
    );
    await engine.drain();

    expect(handler.callCount, 1);
    expect(handler.receivedKeys, ['key-1']);
    expect(handler.receivedPayloads.single, {'foo': 'bar'});

    final entries = await store.watchAll().first;
    expect(entries.single.status, OutboxStatus.completed);

    final status = await _refreshedStatus(engine);
    expect(status.pendingCount, 0);
    expect(status.failedCount, 0);
  });

  test('a transient failure schedules a retry rather than exhausting immediately', () async {
    handler.outcomes.add(const SyncFailure(message: 'offline', code: 'NETWORK_ERROR'));

    await store.enqueue(
      idempotencyKey: 'key-2',
      entityType: 'test.entity',
      operationType: 'CREATE',
      payload: {},
    );
    await engine.drain();

    final entries = await store.watchAll().first;
    expect(entries.single.status, OutboxStatus.failed);
    expect(entries.single.retryCount, 1);
    // Still due again shortly (baseDelay is 1ms in this test's policy).
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await engine.drain();

    expect(handler.callCount, 2);
    final afterRetry = await store.watchAll().first;
    expect(afterRetry.single.status, OutboxStatus.completed);
  });

  test('a permanent error does not get silently retried in a loop', () async {
    handler.outcomes.add(
      const SyncFailure(message: 'bad request', code: 'VALIDATION_ERROR'),
    );

    await store.enqueue(
      idempotencyKey: 'key-3',
      entityType: 'test.entity',
      operationType: 'CREATE',
      payload: {},
    );
    await engine.drain();
    expect(handler.callCount, 1);

    // A second drain pass must NOT retry a permanently-failed entry on its
    // own — this is the guard against a tight automatic retry loop.
    await engine.drain();
    expect(handler.callCount, 1);

    final status = await _refreshedStatus(engine);
    expect(status.failedCount, 1);
  });

  test('manual retry resets a failed entry and it is picked up on the next drain', () async {
    handler.outcomes.add(
      const SyncFailure(message: 'bad request', code: 'VALIDATION_ERROR'),
    );
    await store.enqueue(
      idempotencyKey: 'key-4',
      entityType: 'test.entity',
      operationType: 'CREATE',
      payload: {},
    );
    await engine.drain();
    expect(handler.callCount, 1);

    // Exercises the same store operation retryNow() wraps, but awaited
    // deterministically — retryNow() itself fires its drain
    // un-awaited (matching enqueue()'s snappy, non-blocking design),
    // which this test isn't trying to race.
    await store.resetForManualRetry('key-4');
    await engine.drain();
    expect(handler.callCount, 2);

    final entries = await store.watchAll().first;
    expect(entries.single.status, OutboxStatus.completed);
  });

  test('the same idempotency key is reused as the outbox entry id, preventing duplicate enqueues', () async {
    // Exercised directly on the store — the engine's own enqueue() also
    // fires a background drain, which is orthogonal to this test's actual
    // claim: that enqueuing twice with the same key never creates two rows.
    await store.enqueue(
      idempotencyKey: 'same-key',
      entityType: 'test.entity',
      operationType: 'CREATE',
      payload: {'attempt': 1},
    );
    await store.enqueue(
      idempotencyKey: 'same-key',
      entityType: 'test.entity',
      operationType: 'CREATE',
      payload: {'attempt': 2},
    );

    final entries = await store.watchAll().first;
    expect(entries, hasLength(1));
    expect(entries.single.payload, {'attempt': 2});
  });
}

Future<dynamic> _refreshedStatus(SyncEngine engine) async {
  await engine.refreshStatus();
  return engine.status;
}
