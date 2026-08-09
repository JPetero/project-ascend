import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/permissions/device_permissions_service.dart';
import '../../../../core/permissions/platform_device_permissions_service.dart';
import '../../../wearables/data/health_adapter.dart';
import '../../../wearables/presentation/providers/wearable_sync_controller.dart';

final devicePermissionsServiceProvider = Provider<DevicePermissionsService>((
  ref,
) {
  return const PlatformDevicePermissionsService();
});

class PermissionCenterState {
  const PermissionCenterState({
    this.statuses = const {},
    this.healthStatus = HealthPermissionStatus.unavailable,
    this.isLoading = true,
  });

  final Map<AppPermission, DevicePermissionStatus> statuses;
  final HealthPermissionStatus healthStatus;
  final bool isLoading;

  PermissionCenterState copyWith({
    Map<AppPermission, DevicePermissionStatus>? statuses,
    HealthPermissionStatus? healthStatus,
    bool? isLoading,
  }) {
    return PermissionCenterState(
      statuses: statuses ?? this.statuses,
      healthStatus: healthStatus ?? this.healthStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Backs the Permission Center screen (Build Session 12 Part 12-14) — a
/// single place to see every OS permission this app can request and its
/// current status, instead of only discovering a missing grant the hard
/// way from inside whichever feature happens to need it.
class PermissionCenterController extends StateNotifier<PermissionCenterState> {
  PermissionCenterController({
    required DevicePermissionsService permissions,
    required HealthAdapter healthAdapter,
  }) : _permissions = permissions,
       _healthAdapter = healthAdapter,
       super(const PermissionCenterState()) {
    refresh();
  }

  final DevicePermissionsService _permissions;
  final HealthAdapter _healthAdapter;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    final statuses = <AppPermission, DevicePermissionStatus>{};
    for (final permission in AppPermission.values) {
      statuses[permission] = await _permissions.status(permission);
    }
    HealthPermissionStatus healthStatus;
    try {
      healthStatus = await _healthAdapter.checkPermissions(
        _healthAdapter.supportedMetrics,
      );
    } catch (_) {
      healthStatus = HealthPermissionStatus.unavailable;
    }
    state = PermissionCenterState(
      statuses: statuses,
      healthStatus: healthStatus,
      isLoading: false,
    );
  }

  Future<void> request(AppPermission permission) async {
    await _permissions.request(permission);
    await refresh();
  }

  Future<void> requestHealth() async {
    await _healthAdapter.requestPermissions(_healthAdapter.supportedMetrics);
    await refresh();
  }

  Future<void> openSettings() => _permissions.openSettings();
}

final permissionCenterControllerProvider =
    StateNotifierProvider.autoDispose<
      PermissionCenterController,
      PermissionCenterState
    >((ref) {
      return PermissionCenterController(
        permissions: ref.watch(devicePermissionsServiceProvider),
        healthAdapter: ref.watch(healthAdapterProvider),
      );
    });
