import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/permissions/device_permissions_service.dart';
import 'package:mobile/features/permissions/presentation/providers/permission_center_controller.dart';
import 'package:mobile/features/wearables/data/health_adapter.dart';
import 'package:mobile/features/wearables/domain/health_metric.dart';

import '../../helpers/fake_device_permissions_service.dart';
import '../../helpers/fake_health_adapter.dart';

void main() {
  test(
    'loads every OS permission status plus health on construction',
    () async {
      final permissions = FakeDevicePermissionsService(
        statuses: {
          AppPermission.camera: DevicePermissionStatus.granted,
          AppPermission.location: DevicePermissionStatus.denied,
        },
      );
      final health = FakeHealthAdapter(
        permissionResult: HealthPermissionStatus.granted,
      );
      final controller = PermissionCenterController(
        permissions: permissions,
        healthAdapter: health,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(
        controller.state.statuses[AppPermission.camera],
        DevicePermissionStatus.granted,
      );
      expect(
        controller.state.statuses[AppPermission.location],
        DevicePermissionStatus.denied,
      );
      expect(controller.state.healthStatus, HealthPermissionStatus.granted);
    },
  );

  test('request() grants the permission and refreshes state', () async {
    final permissions = FakeDevicePermissionsService(
      statuses: {AppPermission.camera: DevicePermissionStatus.denied},
    );
    final controller = PermissionCenterController(
      permissions: permissions,
      healthAdapter: FakeHealthAdapter(),
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.request(AppPermission.camera);

    expect(
      controller.state.statuses[AppPermission.camera],
      DevicePermissionStatus.granted,
    );
  });

  test(
    'a health-check failure falls back to unavailable rather than throwing',
    () async {
      final controller = PermissionCenterController(
        permissions: FakeDevicePermissionsService(),
        healthAdapter: _ThrowingHealthAdapter(),
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.healthStatus, HealthPermissionStatus.unavailable);
    },
  );

  test('openSettings() delegates to the permissions service', () async {
    final permissions = FakeDevicePermissionsService();
    final controller = PermissionCenterController(
      permissions: permissions,
      healthAdapter: FakeHealthAdapter(),
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.openSettings();

    expect(permissions.openSettingsCallCount, 1);
  });
}

class _ThrowingHealthAdapter extends FakeHealthAdapter {
  @override
  Future<HealthPermissionStatus> checkPermissions(
    List<HealthMetric> metrics,
  ) async => throw Exception('unavailable');
}
