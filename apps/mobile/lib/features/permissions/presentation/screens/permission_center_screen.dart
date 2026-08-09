import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/permissions/device_permissions_service.dart';
import '../../../wearables/data/health_adapter.dart';
import '../providers/permission_center_controller.dart';

String _permissionLabel(AppPermission permission) {
  switch (permission) {
    case AppPermission.camera:
      return 'Camera';
    case AppPermission.location:
      return 'Location';
    case AppPermission.microphone:
      return 'Microphone';
    case AppPermission.notifications:
      return 'Notifications';
  }
}

IconData _permissionIcon(AppPermission permission) {
  switch (permission) {
    case AppPermission.camera:
      return Icons.camera_alt_outlined;
    case AppPermission.location:
      return Icons.location_on_outlined;
    case AppPermission.microphone:
      return Icons.mic_none_outlined;
    case AppPermission.notifications:
      return Icons.notifications_outlined;
  }
}

String _statusLabel(DevicePermissionStatus status) {
  switch (status) {
    case DevicePermissionStatus.granted:
      return 'Granted';
    case DevicePermissionStatus.denied:
      return 'Not granted';
    case DevicePermissionStatus.permanentlyDenied:
      return 'Denied — change in Settings';
    case DevicePermissionStatus.unavailable:
      return 'Unavailable on this device';
  }
}

String _healthStatusLabel(HealthPermissionStatus status) {
  switch (status) {
    case HealthPermissionStatus.granted:
      return 'Granted';
    case HealthPermissionStatus.denied:
      return 'Not granted';
    case HealthPermissionStatus.unavailable:
      return 'Unavailable on this device';
  }
}

/// Permission Center (Build Session 12 Part 12-14) — every OS permission
/// this app can request, in one place, with its current status. Camera/
/// location/microphone/notifications route through
/// `DevicePermissionsService`; health data goes through the existing
/// `HealthAdapter` (Health Connect/HealthKit) instead, since it isn't a
/// `permission_handler` permission at all.
class PermissionCenterScreen extends ConsumerWidget {
  const PermissionCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionCenterControllerProvider);
    final controller = ref.read(permissionCenterControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Permission Center')),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    Text(
                      'What Ascend can access on this device, and why:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AscendSpacing.md),
                    for (final permission in AppPermission.values)
                      _PermissionRow(
                        icon: _permissionIcon(permission),
                        label: _permissionLabel(permission),
                        statusLabel: _statusLabel(
                          state.statuses[permission] ??
                              DevicePermissionStatus.unavailable,
                        ),
                        granted:
                            state.statuses[permission] ==
                            DevicePermissionStatus.granted,
                        onTap: () =>
                            (state.statuses[permission] ==
                                DevicePermissionStatus.permanentlyDenied)
                            ? controller.openSettings()
                            : controller.request(permission),
                      ),
                    _PermissionRow(
                      icon: Icons.favorite_border,
                      label: 'Health data',
                      statusLabel: _healthStatusLabel(state.healthStatus),
                      granted:
                          state.healthStatus == HealthPermissionStatus.granted,
                      onTap: controller.requestHealth,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.statusLabel,
    required this.granted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String statusLabel;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
      child: AscendCard(
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: AscendSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: granted
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!granted)
              TextButton(onPressed: onTap, child: const Text('Allow')),
          ],
        ),
      ),
    );
  }
}
