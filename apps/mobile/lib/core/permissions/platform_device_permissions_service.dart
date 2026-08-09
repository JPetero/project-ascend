import 'package:permission_handler/permission_handler.dart' as ph;

import 'device_permissions_service.dart';

/// Real `permission_handler` implementation of [DevicePermissionsService].
class PlatformDevicePermissionsService implements DevicePermissionsService {
  const PlatformDevicePermissionsService();

  ph.Permission _mapPermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return ph.Permission.camera;
      case AppPermission.location:
        return ph.Permission.locationWhenInUse;
      case AppPermission.microphone:
        return ph.Permission.microphone;
      case AppPermission.notifications:
        return ph.Permission.notification;
    }
  }

  DevicePermissionStatus _mapStatus(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return DevicePermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return DevicePermissionStatus.permanentlyDenied;
    }
    if (status.isDenied || status.isRestricted) {
      return DevicePermissionStatus.denied;
    }
    return DevicePermissionStatus.unavailable;
  }

  @override
  Future<DevicePermissionStatus> status(AppPermission permission) async {
    final status = await _mapPermission(permission).status;
    return _mapStatus(status);
  }

  @override
  Future<DevicePermissionStatus> request(AppPermission permission) async {
    final status = await _mapPermission(permission).request();
    return _mapStatus(status);
  }

  @override
  Future<void> openSettings() async {
    await ph.openAppSettings();
  }
}
