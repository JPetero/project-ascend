import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_model.dart';

class ProfileController extends StateNotifier<AsyncValue<ProfileModel?>> {
  ProfileController({
    required ProfileRepository repository,
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

  final ProfileRepository _repository;
  final String? _userId;

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      final profile = await _repository.fetchProfile(userId);
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> patch) async {
    final userId = _userId;
    if (userId == null) return;
    final profile = await _repository.updateProfile(userId, patch);
    state = AsyncValue.data(profile);
  }

  Future<void> updateOnboarding(Map<String, dynamic> patch) async {
    final userId = _userId;
    if (userId == null) return;
    final profile = await _repository.updateOnboarding(userId, patch);
    state = AsyncValue.data(profile);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    apiClient: ref.watch(apiClientProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<ProfileModel?>>((ref) {
      final user = ref.watch(
        authControllerProvider.select((state) => state.user),
      );
      return ProfileController(
        repository: ref.watch(profileRepositoryProvider),
        userId: user?.id,
      );
    });
