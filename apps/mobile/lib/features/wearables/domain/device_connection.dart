enum DeviceConnectionStatus { connected, disconnected, pending, error }

DeviceConnectionStatus deviceStatusFromJson(String value) =>
    DeviceConnectionStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value,
      orElse: () => DeviceConnectionStatus.pending,
    );

class DeviceConnection {
  const DeviceConnection({
    required this.id,
    required this.provider,
    required this.displayName,
    required this.status,
    this.lastSyncedAt,
  });

  final String id;
  final String provider;
  final String displayName;
  final DeviceConnectionStatus status;
  final DateTime? lastSyncedAt;

  factory DeviceConnection.fromJson(Map<String, dynamic> json) {
    return DeviceConnection(
      id: json['id'] as String,
      provider: json['provider'] as String,
      displayName: json['displayName'] as String,
      status: deviceStatusFromJson(json['status'] as String? ?? 'PENDING'),
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
    );
  }
}
