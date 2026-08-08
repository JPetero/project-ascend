import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gallery/data/gallery_repository.dart';
import '../../../gallery/domain/gallery_album.dart';
import '../../../gallery/domain/gallery_media.dart';
import '../../../gallery/presentation/providers/gallery_controller.dart';

class ProgressComparisonState {
  const ProgressComparisonState({
    this.isLoading = true,
    this.error,
    this.photos = const [],
    this.before,
    this.after,
  });

  final bool isLoading;
  final String? error;
  // Every PROGRESS-category album's media, flattened and sorted
  // oldest-first — these are photos the user already explicitly saved to
  // their gallery (Build Session 9 Part 2), never a fresh, unreviewed
  // Vision capture.
  final List<GalleryMedia> photos;
  final GalleryMedia? before;
  final GalleryMedia? after;

  bool get hasBothSelected => before != null && after != null;

  ProgressComparisonState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<GalleryMedia>? photos,
    GalleryMedia? before,
    bool clearBefore = false,
    GalleryMedia? after,
    bool clearAfter = false,
  }) {
    return ProgressComparisonState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      photos: photos ?? this.photos,
      before: clearBefore ? null : (before ?? this.before),
      after: clearAfter ? null : (after ?? this.after),
    );
  }
}

/// Progress Scan V1 (Build Session 9 Part 11-13) — a genuine, working
/// feature built entirely on top of the existing private gallery (Build
/// Session 9 Part 2), not a new capture/analysis pipeline: the user picks
/// two photos they already saved to a PROGRESS-category album and views
/// them side by side. No measurement, estimate, or inference of any kind
/// runs on either photo — see Scenario 17's hard safety requirements
/// (`packages/docs/product/user-scenario-bible.md`): never assign a
/// fabricated muscle-development percentage, never promise a reliable
/// body-fat estimate from a camera image.
class ProgressComparisonController extends StateNotifier<ProgressComparisonState> {
  ProgressComparisonController({required GalleryRepository repository})
    : _repository = repository,
      super(const ProgressComparisonState()) {
    load();
  }

  final GalleryRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final albums = await _repository.listAlbums();
      final progressAlbums = albums.where(
        (a) => a.category == GalleryCategory.progress,
      );
      final details = await Future.wait(
        progressAlbums.map((a) => _repository.getAlbum(a.id)),
      );
      final photos = details.expand((d) => d.media).toList()
        ..sort(
          (a, b) => (a.capturedAt ?? a.createdAt).compareTo(
            b.capturedAt ?? b.createdAt,
          ),
        );
      state = state.copyWith(photos: photos, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  void selectBefore(GalleryMedia media) => state = state.copyWith(before: media);

  void selectAfter(GalleryMedia media) => state = state.copyWith(after: media);

  void clearBefore() => state = state.copyWith(clearBefore: true);

  void clearAfter() => state = state.copyWith(clearAfter: true);
}

final progressComparisonControllerProvider = StateNotifierProvider.autoDispose<
  ProgressComparisonController,
  ProgressComparisonState
>((ref) {
  return ProgressComparisonController(
    repository: ref.watch(galleryRepositoryProvider),
  );
});
