import 'package:mobile/features/gallery/data/gallery_repository.dart';
import 'package:mobile/features/gallery/domain/gallery_album.dart';
import 'package:mobile/features/gallery/domain/gallery_media.dart';

GalleryAlbum sampleGalleryAlbum({
  String id = 'album-1',
  String name = 'Progress',
  GalleryCategory category = GalleryCategory.progress,
  GalleryVisibility visibility = GalleryVisibility.private_,
  int mediaCount = 0,
}) {
  return GalleryAlbum(
    id: id,
    name: name,
    category: category,
    visibility: visibility,
    mediaCount: mediaCount,
    createdAt: DateTime.utc(2026, 8, 7),
  );
}

GalleryMedia sampleGalleryMedia({
  String id = 'media-1',
  String albumId = 'album-1',
  String mediaAssetId = 'asset-1',
  String url = 'https://media.example/asset-1.jpg',
  GalleryPoseTag? poseTag,
}) {
  return GalleryMedia(
    id: id,
    albumId: albumId,
    mediaAssetId: mediaAssetId,
    url: url,
    poseTag: poseTag,
    createdAt: DateTime.utc(2026, 8, 7),
  );
}

/// In-memory stand-in for [GalleryRepository].
class FakeGalleryRepository implements GalleryRepository {
  FakeGalleryRepository({List<GalleryAlbum>? albums}) : albums = albums ?? [];

  final List<GalleryAlbum> albums;
  final Map<String, List<GalleryMedia>> mediaByAlbum = {};
  String? lastAvatarMediaId;
  String? lastCoverMediaId;

  @override
  Future<List<GalleryAlbum>> listAlbums() async => List.unmodifiable(albums);

  @override
  Future<GalleryAlbum> createAlbum({
    required String name,
    GalleryCategory category = GalleryCategory.private_,
    GalleryVisibility visibility = GalleryVisibility.private_,
  }) async {
    final album = sampleGalleryAlbum(
      id: 'album-${albums.length + 1}',
      name: name,
      category: category,
      visibility: visibility,
    );
    albums.add(album);
    return album;
  }

  @override
  Future<GalleryAlbumDetail> getAlbum(String albumId) async {
    final album = albums.firstWhere((a) => a.id == albumId);
    return GalleryAlbumDetail(
      id: album.id,
      name: album.name,
      category: galleryCategoryToJson(album.category),
      media: mediaByAlbum[albumId] ?? const [],
    );
  }

  @override
  Future<void> renameAlbum(String albumId, String name) async {}

  @override
  Future<void> deleteAlbum(String albumId) async {
    albums.removeWhere((a) => a.id == albumId);
    mediaByAlbum.remove(albumId);
  }

  @override
  Future<GalleryMedia> addMedia(
    String albumId, {
    required String mediaAssetId,
    String? note,
    GalleryPoseTag? poseTag,
    String? weightNote,
    DateTime? capturedAt,
  }) async {
    final media = sampleGalleryMedia(
      id: 'media-${mediaByAlbum[albumId]?.length ?? 0 + 1}',
      albumId: albumId,
      mediaAssetId: mediaAssetId,
      poseTag: poseTag,
    );
    mediaByAlbum.putIfAbsent(albumId, () => []).add(media);
    final index = albums.indexWhere((a) => a.id == albumId);
    if (index != -1) {
      albums[index] = sampleGalleryAlbum(
        id: albums[index].id,
        name: albums[index].name,
        category: albums[index].category,
        visibility: albums[index].visibility,
        mediaCount: mediaByAlbum[albumId]!.length,
      );
    }
    return media;
  }

  @override
  Future<void> removeMedia(String mediaId) async {
    for (final list in mediaByAlbum.values) {
      list.removeWhere((m) => m.id == mediaId);
    }
  }

  @override
  Future<void> setAsAvatar(String mediaId) async {
    lastAvatarMediaId = mediaId;
  }

  @override
  Future<void> setAsCover(String mediaId) async {
    lastCoverMediaId = mediaId;
  }
}
