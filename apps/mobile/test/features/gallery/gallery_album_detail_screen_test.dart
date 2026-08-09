import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/gallery/presentation/screens/gallery_album_detail_screen.dart';
import 'package:mobile/features/sharing/presentation/screens/share_content_screen.dart';

import '../../helpers/fake_gallery_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'a photo has a working share action (Build Session 10 Parts 20-21 — '
    'progressMedia existed since Build Session 9 Part 3 but the gallery '
    'had no share action at all)',
    (tester) async {
      final repository = FakeGalleryRepository(
        albums: [sampleGalleryAlbum(id: 'album-1', name: 'Progress')],
      );
      repository.mediaByAlbum['album-1'] = [
        sampleGalleryMedia(id: 'media-1', albumId: 'album-1'),
      ];
      final container = await createTestContainer(
        signedIn: true,
        galleryRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: GalleryAlbumDetailScreen(albumId: 'album-1'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.byType(Image));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);

      await tester.tap(find.text('Share'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(ShareContentScreen), findsOneWidget);
    },
  );

  testWidgets('a photo grid tile carries a semantic label a screen reader can '
      'announce instead of just "image, button" (Build Session 10 Parts '
      '27-29)', (tester) async {
    final repository = FakeGalleryRepository(
      albums: [sampleGalleryAlbum(id: 'album-1', name: 'Progress')],
    );
    repository.mediaByAlbum['album-1'] = [
      sampleGalleryMedia(id: 'media-1', albumId: 'album-1'),
    ];
    final container = await createTestContainer(
      signedIn: true,
      galleryRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GalleryAlbumDetailScreen(albumId: 'album-1'),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    final semantics = tester.getSemantics(find.byType(Image));
    expect(semantics.label, contains('Photo'));
    expect(semantics.label, contains('opens actions'));
  });
}
