import 'package:mobile/features/wearables/data/health_adapter.dart';
import 'package:mobile/features/wearables/domain/health_metric.dart';
import 'package:mobile/features/wearables/domain/health_sample.dart';

/// In-memory stand-in for [HealthAdapter] — tests seed [samplesToReturn]
/// and control [available]/[permissionResult] instead of needing a real
/// platform health plugin.
class FakeHealthAdapter extends HealthAdapter {
  FakeHealthAdapter({
    this.available = true,
    this.permissionResult = HealthPermissionStatus.granted,
    List<HealthMetric>? supported,
  }) : supportedMetrics =
           supported ?? [HealthMetric.steps, HealthMetric.heartRate];

  bool available;
  HealthPermissionStatus permissionResult;
  List<HealthSample> samplesToReturn = const [];
  int revokeCallCount = 0;
  final List<DateTime> readSamplesSinceCalls = [];

  @override
  final List<HealthMetric> supportedMetrics;

  @override
  String get providerId => androidHealthConnectProviderId;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<HealthPermissionStatus> checkPermissions(
    List<HealthMetric> metrics,
  ) async => permissionResult;

  @override
  Future<HealthPermissionStatus> requestPermissions(
    List<HealthMetric> metrics,
  ) async => permissionResult;

  @override
  Future<void> revokePermissions() async {
    revokeCallCount++;
  }

  @override
  Future<List<HealthSample>> readSamples({
    required List<HealthMetric> metrics,
    required DateTime since,
  }) async {
    readSamplesSinceCalls.add(since);
    return samplesToReturn.where((s) => metrics.contains(s.metric)).toList();
  }
}
