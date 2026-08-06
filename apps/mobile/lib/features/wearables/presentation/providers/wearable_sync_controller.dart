import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/health_adapter.dart';
import '../../data/health_metrics_repository.dart';
import '../../domain/health_metric.dart';
import '../../domain/health_sample.dart';

/// A first sync (no local bookmark yet) reads this far back rather than
/// a platform's entire history — bounded, predictable, and enough to
/// populate the dashboard/history without an enormous initial payload.
const _initialSyncLookback = Duration(days: 30);

enum HealthAvailability { available, unavailable, permissionDenied }

class WearableSyncState {
  const WearableSyncState({
    this.availability,
    this.isSyncing = false,
    this.lastSyncedAt,
    this.lastError,
  });

  final HealthAvailability? availability;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? lastError;

  WearableSyncState copyWith({
    HealthAvailability? availability,
    bool? isSyncing,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return WearableSyncState(
      availability: availability ?? this.availability,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Orchestrates a Health Connect/HealthKit sync: availability detection,
/// permission check/request, incremental read (using the local
/// per-metric bookmark), upload, and updating both the local bookmark
/// and the UI's sync state — see packages/docs/wearables.md.
class WearableSyncController extends StateNotifier<WearableSyncState> {
  WearableSyncController({
    required HealthAdapter adapter,
    required HealthMetricsRepository repository,
    required AppDatabase database,
    required Ref ref,
  }) : _adapter = adapter,
       _repository = repository,
       _database = database,
       _ref = ref,
       super(const WearableSyncState());

  final HealthAdapter _adapter;
  final HealthMetricsRepository _repository;
  final AppDatabase _database;
  final Ref _ref;

  // Read lazily rather than captured at construction: this controller must
  // survive `authControllerProvider`'s async bootstrap resolving from
  // unauthenticated to authenticated without being torn down and losing
  // in-flight availability/sync state (it is not watched — see the
  // provider below).
  String get _userId => _ref.read(authControllerProvider).user?.id ?? '';

  Future<HealthAvailability> checkAvailability() async {
    if (!await _adapter.isAvailable()) {
      if (mounted) {
        state = state.copyWith(availability: HealthAvailability.unavailable);
      }
      return HealthAvailability.unavailable;
    }
    final permission = await _adapter.checkPermissions(
      _adapter.supportedMetrics,
    );
    final availability = permission == HealthPermissionStatus.granted
        ? HealthAvailability.available
        : HealthAvailability.permissionDenied;
    if (mounted) state = state.copyWith(availability: availability);
    return availability;
  }

  Future<bool> requestPermissionsAndSync() async {
    final permission = await _adapter.requestPermissions(
      _adapter.supportedMetrics,
    );
    if (permission != HealthPermissionStatus.granted) {
      if (mounted) {
        state = state.copyWith(
          availability: HealthAvailability.permissionDenied,
        );
      }
      return false;
    }
    if (mounted) {
      state = state.copyWith(availability: HealthAvailability.available);
    }
    await sync();
    return true;
  }

  Future<void> sync() async {
    if (state.isSyncing || _userId.isEmpty) return;
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final allSamples = <HealthSample>[];
      final now = DateTime.now();
      final userId = _userId;

      for (final metric in _adapter.supportedMetrics) {
        final since = await _database.readHealthSyncStatus(
          userId: userId,
          provider: _adapter.providerId,
          metric: healthMetricToJson(metric),
        );
        final samples = await _adapter.readSamples(
          metrics: [metric],
          since: since ?? now.subtract(_initialSyncLookback),
        );
        allSamples.addAll(samples);
      }

      if (allSamples.isNotEmpty) {
        await _repository.sync(
          provider: _adapter.providerId,
          samples: allSamples,
        );
      }

      for (final metric in _adapter.supportedMetrics) {
        await _database.setHealthSyncStatus(
          userId: userId,
          provider: _adapter.providerId,
          metric: healthMetricToJson(metric),
          lastSyncedAt: now,
        );
      }

      if (mounted) {
        state = state.copyWith(isSyncing: false, lastSyncedAt: now);
      }
    } catch (error) {
      if (mounted) {
        state = state.copyWith(isSyncing: false, lastError: error.toString());
      }
    }
  }

  /// Called when the user disconnects this provider from the Wearables
  /// screen — revokes the platform permission and discards the local
  /// sync bookmark. The backend's own cursor is cleared separately by
  /// `DevicesService.remove` when the `DeviceConnection` is deleted.
  Future<void> disconnect() async {
    await _adapter.revokePermissions();
    await _database.clearHealthSyncStatus(_userId);
    if (mounted) state = const WearableSyncState();
  }
}

final healthAdapterProvider = Provider<HealthAdapter>((ref) {
  return PlatformHealthAdapter();
});

final healthMetricsRepositoryProvider = Provider<HealthMetricsRepository>((
  ref,
) {
  return HealthMetricsRepository(apiClient: ref.watch(apiClientProvider));
});

final wearableSyncControllerProvider =
    StateNotifierProvider<WearableSyncController, WearableSyncState>((ref) {
      return WearableSyncController(
        adapter: ref.watch(healthAdapterProvider),
        repository: ref.watch(healthMetricsRepositoryProvider),
        database: ref.watch(appDatabaseProvider),
        ref: ref,
      );
    });
