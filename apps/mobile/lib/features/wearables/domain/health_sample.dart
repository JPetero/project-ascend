import 'health_metric.dart';

/// One normalized sample read from a connected health platform — the
/// wire shape matches `HealthSampleDto` on the backend exactly. Already
/// unit- and timezone-normalized by the adapter that produced it (see
/// `HealthAdapter`), so nothing downstream needs to know which platform
/// or vendor it came from.
class HealthSample {
  const HealthSample({
    required this.metric,
    required this.value,
    this.unit,
    required this.recordedAt,
    this.recordedTimezone,
    this.sourceDeviceId,
    this.externalId,
  });

  final HealthMetric metric;
  final double value;
  final String? unit;
  final DateTime recordedAt;
  final String? recordedTimezone;
  final String? sourceDeviceId;
  final String? externalId;

  Map<String, dynamic> toJson() => {
    'metric': healthMetricToJson(metric),
    'value': value,
    'unit': unit ?? healthMetricUnit(metric),
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    if (recordedTimezone != null) 'recordedTimezone': recordedTimezone,
    if (sourceDeviceId != null) 'sourceDeviceId': sourceDeviceId,
    if (externalId != null) 'externalId': externalId,
  };
}

/// A provider+metric incremental-sync bookmark, as returned by
/// `GET /health-metrics/sync-status` — mirrors `HealthSyncCursor` on the
/// backend. Powers the Connected Health screen's per-metric sync state.
class HealthSyncCursorInfo {
  const HealthSyncCursorInfo({
    required this.provider,
    required this.metric,
    required this.cursor,
    required this.lastSyncedAt,
  });

  final String provider;
  final HealthMetric metric;
  final String cursor;
  final DateTime lastSyncedAt;

  factory HealthSyncCursorInfo.fromJson(Map<String, dynamic> json) =>
      HealthSyncCursorInfo(
        provider: json['provider'] as String,
        metric: healthMetricFromJson(json['metric'] as String),
        cursor: json['cursor'] as String,
        lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
      );
}

class HealthSyncResult {
  const HealthSyncResult({
    required this.samplesAdded,
    required this.samplesSkipped,
  });

  final int samplesAdded;
  final int samplesSkipped;

  factory HealthSyncResult.fromJson(Map<String, dynamic> json) =>
      HealthSyncResult(
        samplesAdded: json['samplesAdded'] as int,
        samplesSkipped: json['samplesSkipped'] as int,
      );
}
