import 'package:mobile/features/wearables/data/health_metrics_repository.dart';
import 'package:mobile/features/wearables/domain/health_sample.dart';

class FakeHealthMetricsRepository implements HealthMetricsRepository {
  final List<({String provider, List<HealthSample> samples})> syncCalls = [];
  List<HealthSyncCursorInfo> cursorsToReturn = const [];

  @override
  Future<HealthSyncResult> sync({
    required String provider,
    required List<HealthSample> samples,
  }) async {
    syncCalls.add((provider: provider, samples: samples));
    return HealthSyncResult(samplesAdded: samples.length, samplesSkipped: 0);
  }

  @override
  Future<List<HealthSyncCursorInfo>> syncStatus() async => cursorsToReturn;
}
