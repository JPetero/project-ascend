import '../../../core/networking/api_client.dart';
import '../domain/gallery_album.dart';
import '../domain/gallery_media.dart';

/// Thin client for services/api/src/modules/gallery — Build Session 9
/// Part 2's private-by-default personal gallery, built entirely on the
/// existing Media Platform (no upload logic lives here; see
/// core/media/presentation/providers/media_upload_controller.dart for
/// that shared pick/capture/upload flow).
class GalleryRepository {
  GalleryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<GalleryAlbum>> listAlbums() async {
    final envelope = await _apiClient.get(
      '/gallery/albums',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((a) => GalleryAlbum.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<GalleryAlbum> createAlbum({
    required String name,
    GalleryCategory category = GalleryCategory.private_,
    GalleryVisibility visibility = GalleryVisibility.private_,
  }) async {
    final envelope = await _apiClient.post(
      '/gallery/albums',
      (data) => data as Map<String, dynamic>,
      data: {
        'name': name,
        'category': galleryCategoryToJson(category),
        'visibility': galleryVisibilityToJson(visibility),
      },
    );
    return GalleryAlbum.fromJson(envelope.data!);
  }

  Future<GalleryAlbumDetail> getAlbum(String albumId) async {
    final envelope = await _apiClient.get(
      '/gallery/albums/$albumId',
      (data) => data as Map<String, dynamic>,
    );
    return GalleryAlbumDetail.fromJson(envelope.data!);
  }

  Future<void> renameAlbum(String albumId, String name) async {
    await _apiClient.patch(
      '/gallery/albums/$albumId',
      (_) => null,
      data: {'name': name},
    );
  }

  Future<void> deleteAlbum(String albumId) async {
    await _apiClient.delete('/gallery/albums/$albumId', (_) => null);
  }

  Future<GalleryMedia> addMedia(
    String albumId, {
    required String mediaAssetId,
    String? note,
    GalleryPoseTag? poseTag,
    String? weightNote,
    DateTime? capturedAt,
  }) async {
    final envelope = await _apiClient.post(
      '/gallery/albums/$albumId/media',
      (data) => data as Map<String, dynamic>,
      data: {
        'mediaAssetId': mediaAssetId,
        'note': ?note,
        'poseTag': poseTag != null ? galleryPoseTagToJson(poseTag) : null,
        'weightNote': ?weightNote,
        'capturedAt': ?capturedAt?.toIso8601String(),
      },
    );
    return GalleryMedia.fromJson(envelope.data!);
  }

  Future<void> removeMedia(String mediaId) async {
    await _apiClient.delete('/gallery/media/$mediaId', (_) => null);
  }

  Future<void> setAsAvatar(String mediaId) async {
    await _apiClient.post('/gallery/media/$mediaId/set-avatar', (_) => null);
  }

  Future<void> setAsCover(String mediaId) async {
    await _apiClient.post('/gallery/media/$mediaId/set-cover', (_) => null);
  }
}
