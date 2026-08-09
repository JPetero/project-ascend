import 'package:mobile/core/permissions/device_permissions_service.dart';

/// In-memory stand-in for [DevicePermissionsService].
class FakeDevicePermissionsService implements DevicePermissionsService {
  FakeDevicePermissionsService({
    Map<AppPermission, DevicePermissionStatus>? statuses,
  }) : statuses = statuses ?? {};

  final Map<AppPermission, DevicePermissionStatus> statuses;
  int openSettingsCallCount = 0;

  @override
  Future<DevicePermissionStatus> status(AppPermission permission) async {
    return statuses[permission] ?? DevicePermissionStatus.denied;
  }

  @override
  Future<DevicePermissionStatus> request(AppPermission permission) async {
    statuses[permission] = DevicePermissionStatus.granted;
    return DevicePermissionStatus.granted;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCallCount++;
  }
}
