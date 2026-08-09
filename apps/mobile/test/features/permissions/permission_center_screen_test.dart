import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/permissions/device_permissions_service.dart';
import 'package:mobile/features/permissions/presentation/providers/permission_center_controller.dart';
import 'package:mobile/features/permissions/presentation/screens/permission_center_screen.dart';
import 'package:mobile/features/wearables/presentation/providers/wearable_sync_controller.dart';

import '../../helpers/fake_device_permissions_service.dart';
import '../../helpers/fake_health_adapter.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  testWidgets('shows a status row for every permission plus health', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        devicePermissionsServiceProvider.overrideWithValue(
          FakeDevicePermissionsService(
            statuses: {
              AppPermission.camera: DevicePermissionStatus.granted,
              AppPermission.location: DevicePermissionStatus.denied,
            },
          ),
        ),
        healthAdapterProvider.overrideWithValue(FakeHealthAdapter()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PermissionCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Health data'), findsOneWidget);
    expect(find.text('Granted'), findsWidgets);
  });

  testWidgets('tapping Allow on a denied permission requests it', (
    tester,
  ) async {
    final permissions = FakeDevicePermissionsService(
      statuses: {AppPermission.camera: DevicePermissionStatus.denied},
    );
    final container = ProviderContainer(
      overrides: [
        devicePermissionsServiceProvider.overrideWithValue(permissions),
        healthAdapterProvider.overrideWithValue(FakeHealthAdapter()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PermissionCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Allow').first);
    await pumpForAsyncSettle(tester);

    expect(
      permissions.statuses[AppPermission.camera],
      DevicePermissionStatus.granted,
    );
  });
}
