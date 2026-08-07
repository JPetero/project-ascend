import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/gallery/domain/gallery_album.dart';
import 'package:mobile/features/gallery/presentation/providers/gallery_controller.dart';

import '../../helpers/fake_gallery_repository.dart';

void main() {
  group('GalleryAlbumsController', () {
    test('loads existing albums on creation', () async {
      final repository = FakeGalleryRepository(
        albums: [sampleGalleryAlbum(id: 'album-1', name: 'Progress')],
      );
      final controller = GalleryAlbumsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.albums, hasLength(1));
      expect(controller.state.albums.single.name, 'Progress');
    });

    test('createAlbum adds a new private-by-default album', () async {
      final repository = FakeGalleryRepository();
      final controller = GalleryAlbumsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      final success = await controller.createAlbum(name: 'Workouts');

      expect(success, isTrue);
      expect(controller.state.albums, hasLength(1));
      expect(
        controller.state.albums.single.visibility,
        GalleryVisibility.private_,
      );
    });

    test('deleteAlbum removes it from the list', () async {
      final repository = FakeGalleryRepository(
        albums: [sampleGalleryAlbum(id: 'album-1')],
      );
      final controller = GalleryAlbumsController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.deleteAlbum('album-1');

      expect(controller.state.albums, isEmpty);
    });
  });
}
