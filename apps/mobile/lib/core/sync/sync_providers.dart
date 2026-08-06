import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import 'outbox_store.dart';
import 'sync_engine.dart';
import 'sync_status.dart';

final outboxStoreProvider = Provider<OutboxStore>((ref) {
  return OutboxStore(ref.watch(appDatabaseProvider));
});

/// One [SyncEngine] per app session. Feature modules that need to enqueue
/// mutations depend on this rather than constructing their own — handler
/// registration happens the first time each feature's provider tree is
/// read (see e.g. `workout_sync_handlers.dart`), so the set of registered
/// handlers grows as features are used but the engine itself is a
/// singleton for the whole app.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(store: ref.watch(outboxStoreProvider));
  ref.onDispose(engine.dispose);
  return engine;
});

final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.statusStream;
});

/// Convenience for widgets that just want the latest known status without
/// unwrapping an `AsyncValue` — defaults to idle before the first event and
/// on any stream error, since a sync status indicator failing open (shows
/// nothing) is far better than it crashing the screen it's embedded in.
final syncStatusProvider = Provider<SyncStatus>((ref) {
  return ref.watch(syncStatusStreamProvider).valueOrNull ??
      const SyncStatus.idle();
});
