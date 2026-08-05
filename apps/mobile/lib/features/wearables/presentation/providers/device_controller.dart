import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/device_repository.dart';
import '../../domain/device_connection.dart';

class DeviceController
    extends StateNotifier<AsyncValue<List<DeviceConnection>>> {
  DeviceController({required DeviceRepository repository})
    : _repository = repository,
      super(const AsyncValue.loading()) {
    load();
  }

  final DeviceRepository _repository;

  Future<void> load() async {
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

final deviceControllerProvider =
    StateNotifierProvider<DeviceController, AsyncValue<List<DeviceConnection>>>(
      (ref) =>
          DeviceController(repository: ref.watch(deviceRepositoryProvider)),
    );
