import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/exercise_repository.dart';
import '../../domain/exercise.dart';
import '../../domain/progression_suggestion.dart';

class ExerciseLibraryController
    extends StateNotifier<AsyncValue<List<Exercise>>> {
  ExerciseLibraryController({required ExerciseRepository repository})
    : _repository = repository,
      super(const AsyncValue.loading()) {
    load();
  }

  final ExerciseRepository _repository;
  String? _categorySlug;
  String? _search;

  String? get categorySlug => _categorySlug;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final exercises = await _repository.list(
        categorySlug: _categorySlug,
        search: _search,
      );
      state = AsyncValue.data(exercises);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> filterByCategory(String? categorySlug) async {
    _categorySlug = categorySlug;
    await load();
  }

  Future<void> search(String query) async {
    _search = query.trim().isEmpty ? null : query.trim();
    await load();
  }
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(apiClient: ref.watch(apiClientProvider));
});

final exerciseLibraryControllerProvider =
    StateNotifierProvider.autoDispose<
      ExerciseLibraryController,
      AsyncValue<List<Exercise>>
    >((ref) {
      return ExerciseLibraryController(
        repository: ref.watch(exerciseRepositoryProvider),
      );
    });

final exerciseDetailProvider = FutureProvider.autoDispose
    .family<Exercise, String>((ref, id) {
      return ref.watch(exerciseRepositoryProvider).getById(id);
    });

final exerciseProgressionProvider = FutureProvider.autoDispose
    .family<ProgressionSuggestion, String>((ref, exerciseId) {
      return ref.watch(exerciseRepositoryProvider).getProgression(exerciseId);
    });
