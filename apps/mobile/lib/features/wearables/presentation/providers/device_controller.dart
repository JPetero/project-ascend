import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/device_repository.dart';
import '../../domain/device_connection.dart';

class DeviceController
    extends StateNotifier<AsyncValue<List<DeviceConnection>>> {
  DeviceController({
    required DeviceRepository repository,
    required String? userId,
  }) : _repository = repository,
       _userId = userId,
       super(const AsyncValue.loading()) {
    if (_userId == null) {
      state = const AsyncValue.data([]);
    } else {
      load();
    }
  }

  final DeviceRepository _repository;
  final String? _userId;

  Future<void> load() async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final devices = await _repository.list();
      state = AsyncValue.data(devices);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> connect({
    required String provider,
    required String displayName,
  }) async {
    await _repository.connect(provider: provider, displayName: displayName);
    await load();
  }

  Future<void> disconnect(String id) async {
    await _repository.disconnect(id);
    await load();
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(apiClient: ref.watch(apiClientProvider));
});

/// Rebuilt whenever the authenticated user changes (login, logout, or a
/// different account signing in), so a previous session's connected devices
/// can never linger in memory and be shown to the next user.
final deviceControllerProvider =
    StateNotifierProvider<DeviceController, AsyncValue<List<DeviceConnection>>>(
      (ref) {
        final user = ref.watch(
          authControllerProvider.select((state) => state.user),
        );
        return DeviceController(
          repository: ref.watch(deviceRepositoryProvider),
          userId: user?.id,
        );
      },
    );
