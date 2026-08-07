import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/gallery/presentation/screens/gallery_screen.dart';

import '../../helpers/fake_gallery_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows an honest empty state with no albums', (tester) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No albums yet'), findsOneWidget);
  });

  testWidgets('lists an existing private album', (tester) async {
    final container = await createTestContainer(
      galleryRepository: FakeGalleryRepository(
        albums: [
          sampleGalleryAlbum(id: 'album-1', name: 'My progress', mediaCount: 3),
        ],
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('My progress'), findsOneWidget);
    expect(find.textContaining('3 items'), findsOneWidget);
  });

  testWidgets('creating an album calls through to the repository', (
    tester,
  ) async {
    final repository = FakeGalleryRepository();
    final container = await createTestContainer(galleryRepository: repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byIcon(Icons.add));
    await pumpForAsyncSettle(tester);

    await tester.enterText(find.byType(TextFormField), 'My workouts');
    await tester.tap(find.text('Create album'));
    await pumpForAsyncSettle(tester);

    expect(repository.albums, hasLength(1));
    expect(repository.albums.single.name, 'My workouts');
  });
}
