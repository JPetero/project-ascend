enum CardioActivityType { walk, run, cycle, other }

CardioActivityType cardioActivityTypeFromJson(String value) =>
    CardioActivityType.values.firstWhere(
      (t) => t.name.toUpperCase() == value,
      orElse: () => CardioActivityType.other,
    );

String cardioActivityTypeToJson(CardioActivityType type) =>
    type.name.toUpperCase();

String cardioActivityTypeLabel(CardioActivityType type) => switch (type) {
  CardioActivityType.walk => 'Walk',
  CardioActivityType.run => 'Run',
  CardioActivityType.cycle => 'Cycle',
  CardioActivityType.other => 'Other',
};

/// A manually-logged cardio session — summary data only (duration,
/// distance, elevation, an estimated-and-labelled calorie figure), never
/// live route/GPS tracking. See
/// services/api/prisma/schema.prisma's CardioSession comment and
/// packages/docs/product/user-scenario-bible.md Scenario 12 for why.
/// Route/location fields are stored private-by-default and are honored
/// even though there's no route data to actually expose yet.
class CardioSession {
  const CardioSession({
    required this.id,
    required this.activityType,
    required this.startedAt,
    required this.durationSeconds,
    this.distanceMeters,
    this.elevationGainMeters,
    this.estimatedCalories,
    this.regionLabel,
    required this.hideRoute,
    required this.hideStartLocation,
    required this.hideEndLocation,
    this.notes,
  });

  final String id;
  final CardioActivityType activityType;
  final DateTime startedAt;
  final int durationSeconds;
  final double? distanceMeters;
  final double? elevationGainMeters;
  final double? estimatedCalories;
  final String? regionLabel;
  final bool hideRoute;
  final bool hideStartLocation;
  final bool hideEndLocation;
  final String? notes;

  factory CardioSession.fromJson(Map<String, dynamic> json) {
    return CardioSession(
      id: json['id'] as String,
      activityType: cardioActivityTypeFromJson(json['activityType'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      elevationGainMeters: (json['elevationGainMeters'] as num?)?.toDouble(),
      estimatedCalories: (json['estimatedCalories'] as num?)?.toDouble(),
      regionLabel: json['regionLabel'] as String?,
      hideRoute: json['hideRoute'] as bool,
      hideStartLocation: json['hideStartLocation'] as bool,
      hideEndLocation: json['hideEndLocation'] as bool,
      notes: json['notes'] as String?,
    );
  }
}
