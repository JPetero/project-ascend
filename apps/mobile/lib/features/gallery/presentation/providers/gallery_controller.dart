import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/gallery_repository.dart';
import '../../domain/gallery_album.dart';

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository(apiClient: ref.watch(apiClientProvider));
});

class GalleryAlbumsState {
  const GalleryAlbumsState({
    this.albums = const [],
    this.isLoading = true,
    this.error,
  });

  final List<GalleryAlbum> albums;
  final bool isLoading;
  final String? error;

  GalleryAlbumsState copyWith({
    List<GalleryAlbum>? albums,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GalleryAlbumsState(
      albums: albums ?? this.albums,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// The gallery's own album list — Build Session 9 Part 2. Every album is
/// private by default; nothing here is ever shown to another user
/// unless its own [GalleryAlbum.visibility] is explicitly SHARED.
class GalleryAlbumsController extends StateNotifier<GalleryAlbumsState> {
  GalleryAlbumsController({required GalleryRepository repository})
    : _repository = repository,
      super(const GalleryAlbumsState()) {
    refresh();
  }

  final GalleryRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final albums = await _repository.listAlbums();
      state = state.copyWith(albums: albums, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> createAlbum({
    required String name,
    GalleryCategory category = GalleryCategory.private_,
    GalleryVisibility visibility = GalleryVisibility.private_,
  }) async {
    try {
      await _repository.createAlbum(
        name: name,
        category: category,
        visibility: visibility,
      );
      await refresh();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      await _repository.deleteAlbum(albumId);
      await refresh();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }
}

final galleryAlbumsControllerProvider =
    StateNotifierProvider<GalleryAlbumsController, GalleryAlbumsState>((ref) {
      return GalleryAlbumsController(
        repository: ref.watch(galleryRepositoryProvider),
      );
    });
