enum CardioActivityType {
  walk,
  jog,
  run,
  sprint,
  cycle,
  hike,
  wheelchair,
  other,
}

CardioActivityType cardioActivityTypeFromJson(String value) =>
    CardioActivityType.values.firstWhere(
      (t) => t.name.toUpperCase() == value,
      orElse: () => CardioActivityType.other,
    );

String cardioActivityTypeToJson(CardioActivityType type) =>
    type.name.toUpperCase();

String cardioActivityTypeLabel(CardioActivityType type) => switch (type) {
  CardioActivityType.walk => 'Walk',
  CardioActivityType.jog => 'Jog',
  CardioActivityType.run => 'Run',
  CardioActivityType.sprint => 'Sprint',
  CardioActivityType.cycle => 'Cycle',
  CardioActivityType.hike => 'Hike',
  CardioActivityType.wheelchair => 'Wheelchair',
  CardioActivityType.other => 'Other',
};

/// How a session's summary numbers were produced — see
/// services/api/prisma/schema.prisma's CardioSessionSource comment.
enum CardioSessionSource { manual, liveGps, wearable }

CardioSessionSource cardioSessionSourceFromJson(String value) =>
    CardioSessionSource.values.firstWhere(
      (s) => s.name.toUpperCase() == value.replaceAll('_', ''),
      orElse: () => CardioSessionSource.manual,
    );

String cardioSessionSourceToJson(CardioSessionSource source) =>
    switch (source) {
      CardioSessionSource.manual => 'MANUAL',
      CardioSessionSource.liveGps => 'LIVE_GPS',
      CardioSessionSource.wearable => 'WEARABLE',
    };

/// A manually-logged or live-GPS-tracked cardio session. See
/// services/api/prisma/schema.prisma's CardioSession comment and
/// packages/docs/product/user-scenario-bible.md Scenario 12. Route/
/// location fields are stored private-by-default; `encodedRoute` and
/// `routePointCount` are only ever present in the JSON this was parsed
/// from when the session's owner hasn't hidden the route (see
/// `CardioService.serialize` on the backend) — `hasRoute` is always
/// present so the UI can show "this session has a route" without ever
/// needing the coordinates themselves.
class CardioSession {
  const CardioSession({
    required this.id,
    required this.activityType,
    required this.source,
    required this.startedAt,
    required this.durationSeconds,
    this.distanceMeters,
    this.elevationGainMeters,
    this.estimatedCalories,
    this.regionLabel,
    required this.hideRoute,
    required this.hideStartLocation,
    required this.hideEndLocation,
    required this.hasRoute,
    this.encodedRoute,
    this.routePointCount,
    this.notes,
  });

  final String id;
  final CardioActivityType activityType;
  final CardioSessionSource source;
  final DateTime startedAt;
  final int durationSeconds;
  final double? distanceMeters;
  final double? elevationGainMeters;
  final double? estimatedCalories;
  final String? regionLabel;
  final bool hideRoute;
  final bool hideStartLocation;
  final bool hideEndLocation;
  final bool hasRoute;
  final String? encodedRoute;
  final int? routePointCount;
  final String? notes;

  /// Average pace, in seconds per kilometer — null when there's no
  /// distance to derive one from. Purely a display convenience; the
  /// server never stores a derived pace value.
  double? get averagePaceSecondsPerKm {
    final distance = distanceMeters;
    if (distance == null || distance <= 0) return null;
    return durationSeconds / (distance / 1000);
  }

  factory CardioSession.fromJson(Map<String, dynamic> json) {
    return CardioSession(
      id: json['id'] as String,
      activityType: cardioActivityTypeFromJson(json['activityType'] as String),
      source: cardioSessionSourceFromJson(
        json['source'] as String? ?? 'MANUAL',
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      elevationGainMeters: (json['elevationGainMeters'] as num?)?.toDouble(),
      estimatedCalories: (json['estimatedCalories'] as num?)?.toDouble(),
      regionLabel: json['regionLabel'] as String?,
      hideRoute: json['hideRoute'] as bool,
      hideStartLocation: json['hideStartLocation'] as bool,
      hideEndLocation: json['hideEndLocation'] as bool,
      hasRoute: json['hasRoute'] as bool? ?? false,
      encodedRoute: json['encodedRoute'] as String?,
      routePointCount: json['routePointCount'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

/// One recorded point of a live-tracked route — the wire shape matches
/// `RoutePointDto` on the backend exactly (`lat`, `lng`, `t` = elapsed
/// seconds since the session started). GPS-accuracy filtering has
/// already happened by the time a point reaches this class — see
/// `LiveLocationService`.
class RoutePoint {
  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.elapsedSeconds,
  });

  final double latitude;
  final double longitude;
  final int elapsedSeconds;

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    't': elapsedSeconds,
  };

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lng'] as num).toDouble(),
    elapsedSeconds: json['t'] as int,
  );
}
