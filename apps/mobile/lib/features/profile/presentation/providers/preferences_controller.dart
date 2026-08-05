import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/preferences_repository.dart';
import '../../domain/preferences_model.dart';

class PreferencesController
    extends StateNotifier<AsyncValue<PreferencesModel?>> {
  PreferencesController({
    required PreferencesRepository repository,
    required String? userId,
  }) : _repository = repository,
       _userId = userId,
       super(const AsyncValue.loading()) {
    if (_userId == null) {
      state = const AsyncValue.data(null);
    } else {
      load();
    }
  }

  final PreferencesRepository _repository;
  final String? _userId;

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      final preferences = await _repository.fetchPreferences(userId);
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> update(Map<String, dynamic> patch) async {
    final userId = _userId;
    if (userId == null) return;
    final preferences = await _repository.updatePreferences(userId, patch);
    state = AsyncValue.data(preferences);
  }
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepository(
    apiClient: ref.watch(apiClientProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final preferencesControllerProvider =
    StateNotifierProvider<PreferencesController, AsyncValue<PreferencesModel?>>(
      (ref) {
        final user = ref.watch(
          authControllerProvider.select((state) => state.user),
        );
        return PreferencesController(
          repository: ref.watch(preferencesRepositoryProvider),
          userId: user?.id,
        );
      },
    );
