enum AppPermission { camera, location, microphone, notifications }

enum DevicePermissionStatus { granted, denied, permanentlyDenied, unavailable }

/// Build Session 12 Part 12-14 (Permission Center) — a thin boundary
/// over the OS permission system, mirroring `LocalNotificationSchedulingService`'s
/// interface-over-plugin style so `PermissionCenterController` stays
/// fake-able in tests rather than depending on `permission_handler`'s
/// platform channel directly.
abstract class DevicePermissionsService {
  Future<DevicePermissionStatus> status(AppPermission permission);

  Future<DevicePermissionStatus> request(AppPermission permission);

  /// Opens the OS's own app-settings screen — the only way forward once
  /// a permission is permanently denied, since requesting it again is a
  /// silent no-op at that point.
  Future<void> openSettings();
}
