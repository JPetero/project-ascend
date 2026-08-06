import 'dart:io' show Platform;

import 'package:health/health.dart' as health;

import '../domain/health_metric.dart';
import '../domain/health_sample.dart';

/// Provider identifiers — must match `wearableProviderCatalog`'s existing
/// ids exactly, since `DeviceConnection.provider` (and therefore
/// `HealthSyncCursor.provider`, cleared together on disconnect — see
/// DevicesService.remove on the backend) already uses these strings.
const androidHealthConnectProviderId = 'ANDROID_HEALTH_CONNECT';
const appleHealthProviderId = 'APPLE_HEALTH';

enum HealthPermissionStatus { granted, denied, unavailable }

/// Everything the app needs from a connected health platform — an
/// interface (not just a class) so `WearableSyncController` is
/// unit-testable against a fake instead of a real platform plugin. See
/// packages/docs/wearables.md's "Planned architecture for real
/// integrations" (`WearableAdapter`), now implemented for Health
/// Connect/HealthKit via `PlatformHealthAdapter`.
abstract class HealthAdapter {
  /// Stable id matching `DeviceConnection.provider` /
  /// `HealthSyncCursor.provider`.
  String get providerId;

  /// The metrics this platform can, in principle, supply — used for the
  /// Connected Health screen's supported/unsupported split. Not the same
  /// as *permission granted*; see [checkPermissions].
  List<HealthMetric> get supportedMetrics;

  List<HealthMetric> get unsupportedMetrics =>
      HealthMetric.values.where((m) => !supportedMetrics.contains(m)).toList();

  /// Availability detection — e.g. whether the Health Connect app is
  /// installed on this Android device, or (trivially, on iOS) whether
  /// HealthKit exists on this hardware at all.
  Future<bool> isAvailable();

  Future<HealthPermissionStatus> checkPermissions(List<HealthMetric> metrics);

  Future<HealthPermissionStatus> requestPermissions(List<HealthMetric> metrics);

  /// Permission revocation — see packages/docs/wearables.md's requirement
  /// that disconnecting must invalidate access, not just stop syncing.
  Future<void> revokePermissions();

  /// Reads every sample recorded since [since] (exclusive) up to now, for
  /// every metric in [metrics] — the incremental-sync read. [since] is
  /// this platform's own sync cursor for that metric (see
  /// `WearableSyncController`), or a bounded lookback window on first
  /// sync.
  Future<List<HealthSample>> readSamples({
    required List<HealthMetric> metrics,
    required DateTime since,
  });
}

/// The real Health Connect (Android) / HealthKit (iOS) implementation,
/// backed by `package:health` — which already wraps both platforms'
/// native SDKs behind one Dart API, so "matching architecture" for both
/// (Founder Scenario 3's requirement) falls out naturally rather than
/// needing two separately-hand-rolled platform channels.
///
/// **Unverified at runtime** — see packages/docs/build-session-7.md's
/// Platform Limitations: this environment has no Android SDK, emulator,
/// or iOS toolchain, so the actual OS permission prompt and a real data
/// read have not been exercised on a device. The interfaces, platform
/// manifest/entitlement configuration, and this implementation are real
/// code, not a claim of a verified working sync.
class PlatformHealthAdapter extends HealthAdapter {
  PlatformHealthAdapter() : _health = health.Health();

  final health.Health _health;

  @override
  String get providerId => Platform.isAndroid
      ? androidHealthConnectProviderId
      : appleHealthProviderId;

  static const _typeByMetric = {
    HealthMetric.steps: health.HealthDataType.STEPS,
    HealthMetric.heartRate: health.HealthDataType.HEART_RATE,
    HealthMetric.restingHeartRate: health.HealthDataType.RESTING_HEART_RATE,
    HealthMetric.exerciseSession: health.HealthDataType.WORKOUT,
    HealthMetric.activeCalories: health.HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthMetric.distance: health.HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthMetric.sleep: health.HealthDataType.SLEEP_ASLEEP,
    HealthMetric.cyclingDistance: health.HealthDataType.DISTANCE_CYCLING,
  };

  @override
  List<HealthMetric> get supportedMetrics => _typeByMetric.keys.toList();

  @override
  Future<bool> isAvailable() async {
    if (Platform.isAndroid) {
      return _health.isHealthConnectAvailable();
    }
    // HealthKit exists on every iOS device Ascend supports — "available"
    // here means the platform, not whether permission has been granted.
    return Platform.isIOS;
  }

  List<health.HealthDataType> _types(List<HealthMetric> metrics) => metrics
      .map((m) => _typeByMetric[m])
      .whereType<health.HealthDataType>()
      .toList();

  @override
  Future<HealthPermissionStatus> checkPermissions(
    List<HealthMetric> metrics,
  ) async {
    final types = _types(metrics);
    if (types.isEmpty) return HealthPermissionStatus.unavailable;
    final granted = await _health.hasPermissions(types);
    return granted == true
        ? HealthPermissionStatus.granted
        : HealthPermissionStatus.denied;
  }

  @override
  Future<HealthPermissionStatus> requestPermissions(
    List<HealthMetric> metrics,
  ) async {
    final types = _types(metrics);
    if (types.isEmpty) return HealthPermissionStatus.unavailable;
    final granted = await _health.requestAuthorization(types);
    return granted
        ? HealthPermissionStatus.granted
        : HealthPermissionStatus.denied;
  }

  @override
  Future<void> revokePermissions() => _health.revokePermissions();

  @override
  Future<List<HealthSample>> readSamples({
    required List<HealthMetric> metrics,
    required DateTime since,
  }) async {
    final types = _types(metrics);
    if (types.isEmpty) return const [];

    final points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: since,
      endTime: DateTime.now(),
    );

    return points
        .map(_toSample)
        .whereType<HealthSample>()
        // De-duplication of overlapping platform-reported ranges happens
        // server-side (see HealthMetricsService.sync's unique
        // constraint) — the adapter's job is an honest read, not
        // client-side dedup logic that could disagree with the source
        // of truth.
        .toList();
  }

  HealthSample? _toSample(health.HealthDataPoint point) {
    final metric = _metricForType(point.type);
    if (metric == null) return null;
    final value = point.value;
    if (value is! health.NumericHealthValue) return null;

    return HealthSample(
      metric: metric,
      value: value.numericValue.toDouble(),
      recordedAt: point.dateFrom,
      recordedTimezone: DateTime.now().timeZoneName,
      sourceDeviceId: point.sourceName.isEmpty ? null : point.sourceName,
      externalId: point.uuid.isEmpty ? null : point.uuid,
    );
  }

  HealthMetric? _metricForType(health.HealthDataType type) {
    for (final entry in _typeByMetric.entries) {
      if (entry.value == type) return entry.key;
    }
    return null;
  }
}
