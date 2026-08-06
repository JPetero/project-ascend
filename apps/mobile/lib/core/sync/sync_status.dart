/// Aggregate, UI-facing view of the outbox — enough for a generic sync
/// status indicator ("3 pending", "1 needs attention", "all caught up")
/// without any widget needing to know about individual entries.
class SyncStatus {
  const SyncStatus({
    required this.isSyncing,
    required this.pendingCount,
    required this.failedCount,
  });

  const SyncStatus.idle() : this(isSyncing: false, pendingCount: 0, failedCount: 0);

  final bool isSyncing;
  final int pendingCount;
  final int failedCount;

  bool get hasWork => pendingCount > 0 || failedCount > 0;

  SyncStatus copyWith({bool? isSyncing, int? pendingCount, int? failedCount}) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }
}
