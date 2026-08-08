import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/gallery/domain/gallery_album.dart';
import 'package:mobile/features/gallery/domain/gallery_media.dart';
import 'package:mobile/features/gallery/presentation/providers/gallery_controller.dart';
import 'package:mobile/features/vision/presentation/screens/progress_comparison_screen.dart';

import '../../helpers/fake_gallery_repository.dart';
import '../../helpers/pump_helpers.dart';

GalleryMedia _mediaAt({required String id, required DateTime createdAt}) {
  return GalleryMedia(
    id: id,
    albumId: 'album-1',
    mediaAssetId: '$id-asset',
    url: 'https://media.example/$id.jpg',
    createdAt: createdAt,
  );
}

Widget _wrap(FakeGalleryRepository repository) {
  return ProviderScope(
    overrides: [galleryRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: ProgressComparisonScreen()),
  );
}

void main() {
  testWidgets('shows an honest empty state with no progress photos', (
    tester,
  ) async {
    final repository = FakeGalleryRepository();
    await tester.pumpWidget(_wrap(repository));
    await pumpForAsyncSettle(tester);

    expect(find.text('No progress photos yet'), findsOneWidget);
  });

  testWidgets('picking a before and after photo shows both slots filled', (
    tester,
  ) async {
    final repository = FakeGalleryRepository(
      albums: [sampleGalleryAlbum(category: GalleryCategory.progress)],
    );
    repository.mediaByAlbum['album-1'] = [
      _mediaAt(id: 'a', createdAt: DateTime.utc(2026, 1, 5)),
      _mediaAt(id: 'b', createdAt: DateTime.utc(2026, 2, 5)),
    ];

    await tester.pumpWidget(_wrap(repository));
    await pumpForAsyncSettle(tester);

    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);
    expect(find.text('Choose photo'), findsNWidgets(2));

    await tester.tap(find.text('Choose photo').first);
    await pumpForAsyncSettle(tester);
    await tester.tap(find.byType(Image).first);
    await pumpForAsyncSettle(tester);

    expect(find.text('Choose photo'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
  });
}
