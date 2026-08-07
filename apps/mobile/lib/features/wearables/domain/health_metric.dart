/// Normalized health-data types every adapter maps its platform-specific
/// data into — mirrors services/api/prisma/schema.prisma's HealthMetric
/// enum exactly. See packages/docs/wearables.md.
enum HealthMetric {
  steps,
  heartRate,
  restingHeartRate,
  exerciseSession,
  activeCalories,
  distance,
  sleep,
  cyclingDistance,
}

HealthMetric healthMetricFromJson(String value) => HealthMetric.values
    .firstWhere((m) => _toJson(m) == value, orElse: () => HealthMetric.steps);

String healthMetricToJson(HealthMetric metric) => _toJson(metric);

String _toJson(HealthMetric metric) => switch (metric) {
  HealthMetric.steps => 'STEPS',
  HealthMetric.heartRate => 'HEART_RATE',
  HealthMetric.restingHeartRate => 'RESTING_HEART_RATE',
  HealthMetric.exerciseSession => 'EXERCISE_SESSION',
  HealthMetric.activeCalories => 'ACTIVE_CALORIES',
  HealthMetric.distance => 'DISTANCE',
  HealthMetric.sleep => 'SLEEP',
  HealthMetric.cyclingDistance => 'CYCLING_DISTANCE',
};

String healthMetricLabel(HealthMetric metric) => switch (metric) {
  HealthMetric.steps => 'Steps',
  HealthMetric.heartRate => 'Heart rate',
  HealthMetric.restingHeartRate => 'Resting heart rate',
  HealthMetric.exerciseSession => 'Exercise sessions',
  HealthMetric.activeCalories => 'Active calories',
  HealthMetric.distance => 'Distance',
  HealthMetric.sleep => 'Sleep',
  HealthMetric.cyclingDistance => 'Cycling distance',
};

/// The normalized unit every sample of this metric is stored in — always
/// this, regardless of which platform/unit the source reported (e.g.
/// HealthKit may report distance in miles; it's converted to meters
/// before ever reaching a [HealthSample]).
String healthMetricUnit(HealthMetric metric) => switch (metric) {
  HealthMetric.steps => 'count',
  HealthMetric.heartRate => 'bpm',
  HealthMetric.restingHeartRate => 'bpm',
  HealthMetric.exerciseSession => 'minutes',
  HealthMetric.activeCalories => 'kcal',
  HealthMetric.distance => 'meters',
  HealthMetric.sleep => 'minutes',
  HealthMetric.cyclingDistance => 'meters',
};
