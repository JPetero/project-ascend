import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/gallery/domain/gallery_album.dart';
import 'package:mobile/features/gallery/domain/gallery_media.dart';
import 'package:mobile/features/vision/presentation/providers/progress_comparison_controller.dart';

import '../../helpers/fake_gallery_repository.dart';

GalleryMedia _mediaAt({
  required String id,
  required String albumId,
  required DateTime createdAt,
}) {
  return GalleryMedia(
    id: id,
    albumId: albumId,
    mediaAssetId: '$id-asset',
    url: 'https://media.example/$id.jpg',
    createdAt: createdAt,
  );
}

void main() {
  test('loads PROGRESS-category album media, sorted oldest first', () async {
    final repository = FakeGalleryRepository(
      albums: [
        sampleGalleryAlbum(id: 'progress-1', category: GalleryCategory.progress),
        sampleGalleryAlbum(id: 'private-1', category: GalleryCategory.private_),
      ],
    );
    repository.mediaByAlbum['progress-1'] = [
      _mediaAt(id: 'newer', albumId: 'progress-1', createdAt: DateTime.utc(2026, 2)),
      _mediaAt(id: 'older', albumId: 'progress-1', createdAt: DateTime.utc(2026, 1)),
    ];
    repository.mediaByAlbum['private-1'] = [
      _mediaAt(id: 'ignored', albumId: 'private-1', createdAt: DateTime.utc(2026, 3)),
    ];

    final controller = ProgressComparisonController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.error, isNull);
    expect(controller.state.photos.map((m) => m.id).toList(), ['older', 'newer']);
  });

  test('selecting before/after tracks both selections independently', () async {
    final repository = FakeGalleryRepository(
      albums: [sampleGalleryAlbum(category: GalleryCategory.progress)],
    );
    repository.mediaByAlbum['album-1'] = [
      _mediaAt(id: 'a', albumId: 'album-1', createdAt: DateTime.utc(2026, 1)),
      _mediaAt(id: 'b', albumId: 'album-1', createdAt: DateTime.utc(2026, 2)),
    ];
    final controller = ProgressComparisonController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final photoA = controller.state.photos.firstWhere((m) => m.id == 'a');
    final photoB = controller.state.photos.firstWhere((m) => m.id == 'b');

    controller.selectBefore(photoA);
    controller.selectAfter(photoB);

    expect(controller.state.before, photoA);
    expect(controller.state.after, photoB);
    expect(controller.state.hasBothSelected, isTrue);

    controller.clearBefore();
    expect(controller.state.before, isNull);
    expect(controller.state.hasBothSelected, isFalse);
  });

  test('surfaces a repository error honestly instead of an empty list', () async {
    final repository = _ThrowingGalleryRepository();
    final controller = ProgressComparisonController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.error, isNotNull);
    expect(controller.state.photos, isEmpty);
  });
}

class _ThrowingGalleryRepository extends FakeGalleryRepository {
  @override
  Future<List<GalleryAlbum>> listAlbums() async {
    throw Exception('network down');
  }
}
