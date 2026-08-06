/// What a successful replay of an outbox entry returns: the server's id
/// for whatever got created (a substitution, a plan, a set — anything),
/// plus the full response body in case a caller wants more than just the
/// id once sync completes.
class SyncHandlerResult {
  const SyncHandlerResult({required this.entityId, required this.response});

  final String? entityId;
  final Map<String, dynamic> response;
}

/// Replays one outbox entry's payload against the backend. Implemented
/// once per `entityType` by whichever feature module owns that mutation
/// (workout substitution, plan creation, a meal entry, ...) and registered
/// with the [SyncEngine] — the engine itself never knows what a payload
/// means, only how to route it and manage retry bookkeeping.
abstract class SyncHandler {
  /// `idempotencyKey` is the outbox row's own id — pass it straight through
  /// to the backend call so a re-sent request (this retry, or a duplicate
  /// enqueue) can never create a duplicate server-side record.
  Future<SyncHandlerResult> send({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  });
}

/// Adapts a plain function to [SyncHandler] — the common case, since most
/// handlers are just "call this one repository method."
class FunctionSyncHandler implements SyncHandler {
  FunctionSyncHandler(this._send);

  final Future<SyncHandlerResult> Function({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  })
  _send;

  @override
  Future<SyncHandlerResult> send({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) {
    return _send(payload: payload, idempotencyKey: idempotencyKey);
  }
}
