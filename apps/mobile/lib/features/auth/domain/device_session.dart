/// One signed-in device/session (Build Session 10 Part 11's "Your
/// devices"). Mirrors exactly the safe fields the server exposes from
/// `GET /auth/sessions` — never a token, hash, or secret.
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.createdAt,
    required this.lastUsedAt,
    required this.current,
  });

  /// The RefreshToken family id — stable across token rotation, so it
  /// identifies this device's session even though the underlying refresh
  /// token itself changes every time it's used.
  final String id;
  final String? deviceName;
  final String? platform;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final bool current;

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'] as String,
      deviceName: json['deviceName'] as String?,
      platform: json['platform'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      current: json['current'] as bool,
    );
  }
}
