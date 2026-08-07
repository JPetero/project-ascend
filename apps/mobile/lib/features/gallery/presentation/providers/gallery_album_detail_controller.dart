import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gallery_repository.dart';
import '../../domain/gallery_media.dart';
import 'gallery_controller.dart';

class GalleryAlbumDetailState {
  const GalleryAlbumDetailState({
    this.album,
    this.isLoading = true,
    this.isMutating = false,
    this.error,
  });

  final GalleryAlbumDetail? album;
  final bool isLoading;
  final bool isMutating;
  final String? error;

  GalleryAlbumDetailState copyWith({
    GalleryAlbumDetail? album,
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
  }) {
    return GalleryAlbumDetailState(
      album: album ?? this.album,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// One album's media — add/remove items, set an item as the caller's
/// Community profile avatar or cover. Deleting an item never silently
/// deletes the underlying MediaAsset if something else still uses it —
/// see gallery.service.ts's `safeDeleteAssetIfUnused` on the backend;
/// this controller just reflects whatever the server actually did.
class GalleryAlbumDetailController
    extends StateNotifier<GalleryAlbumDetailState> {
  GalleryAlbumDetailController({
    required GalleryRepository repository,
    required this.albumId,
  }) : _repository = repository,
       super(const GalleryAlbumDetailState()) {
    load();
  }

  final GalleryRepository _repository;
  final String albumId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final album = await _repository.getAlbum(albumId);
      state = state.copyWith(album: album, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> addMedia({
    required String mediaAssetId,
    String? note,
    GalleryPoseTag? poseTag,
    String? weightNote,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _repository.addMedia(
        albumId,
        mediaAssetId: mediaAssetId,
        note: note,
        poseTag: poseTag,
        weightNote: weightNote,
      );
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(isMutating: false, error: error.toString());
      return false;
    }
  }

  Future<void> removeMedia(String mediaId) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _repository.removeMedia(mediaId);
      await load();
    } catch (error) {
      state = state.copyWith(isMutating: false, error: error.toString());
    }
  }

  Future<bool> setAsAvatar(String mediaId) async {
    try {
      await _repository.setAsAvatar(mediaId);
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  Future<bool> setAsCover(String mediaId) async {
    try {
      await _repository.setAsCover(mediaId);
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }
}

final galleryAlbumDetailControllerProvider = StateNotifierProvider.family
    .autoDispose<GalleryAlbumDetailController, GalleryAlbumDetailState, String>(
      (ref, albumId) {
        return GalleryAlbumDetailController(
          repository: ref.watch(galleryRepositoryProvider),
          albumId: albumId,
        );
      },
    );
