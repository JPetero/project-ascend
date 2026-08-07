import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/gallery/domain/gallery_media.dart';
import 'package:mobile/features/gallery/presentation/providers/gallery_album_detail_controller.dart';

import '../../helpers/fake_gallery_repository.dart';

void main() {
  group('GalleryAlbumDetailController', () {
    test('loads the album with its media', () async {
      final repository = FakeGalleryRepository(
        albums: [sampleGalleryAlbum(id: 'album-1', name: 'Progress')],
      );
      final controller = GalleryAlbumDetailController(
        repository: repository,
        albumId: 'album-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.album?.name, 'Progress');
      expect(controller.state.album?.media, isEmpty);
    });

    test('addMedia appends a new item and reloads the album', () async {
      final repository = FakeGalleryRepository(
        albums: [sampleGalleryAlbum(id: 'album-1')],
      );
      final controller = GalleryAlbumDetailController(
        repository: repository,
        albumId: 'album-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final success = await controller.addMedia(
        mediaAssetId: 'asset-1',
        poseTag: GalleryPoseTag.front,
      );

      expect(success, isTrue);
      expect(controller.state.album?.media, hasLength(1));
      expect(
        controller.state.album?.media.single.poseTag,
        GalleryPoseTag.front,
      );
    });

    test('removeMedia deletes the item from the album', () async {
      final repository = FakeGalleryRepository(
        albums: [sampleGalleryAlbum(id: 'album-1')],
      );
      repository.mediaByAlbum['album-1'] = [
        sampleGalleryMedia(id: 'media-1', albumId: 'album-1'),
      ];
      final controller = GalleryAlbumDetailController(
        repository: repository,
        albumId: 'album-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.album?.media, hasLength(1));

      await controller.removeMedia('media-1');

      expect(controller.state.album?.media, isEmpty);
    });

    test('setAsAvatar and setAsCover call through to the repository', () async {
      final repository = FakeGalleryRepository(
        albums: [sampleGalleryAlbum(id: 'album-1')],
      );
      repository.mediaByAlbum['album-1'] = [
        sampleGalleryMedia(id: 'media-1', albumId: 'album-1'),
      ];
      final controller = GalleryAlbumDetailController(
        repository: repository,
        albumId: 'album-1',
      );
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(await controller.setAsAvatar('media-1'), isTrue);
      expect(repository.lastAvatarMediaId, 'media-1');

      expect(await controller.setAsCover('media-1'), isTrue);
      expect(repository.lastCoverMediaId, 'media-1');
    });
  });
}
