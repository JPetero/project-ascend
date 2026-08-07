import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/presentation/screens/create_post_screen.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('Text posts show no media picker', (tester) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CreatePostScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Take photo'), findsNothing);
  });

  testWidgets('selecting Photo reveals the real capture/upload picker', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CreatePostScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Photo'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose photo'), findsOneWidget);
    expect(find.text('Record video'), findsNothing);
  });

  testWidgets('selecting Reel reveals video capture options too', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CreatePostScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Reel'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Record video'), findsOneWidget);
    expect(find.text('Choose video'), findsOneWidget);
  });

  testWidgets(
    'submitting a Reel post without an attachment is rejected honestly',
    (tester) async {
      final container = await createTestContainer(signedIn: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CreatePostScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Reel'));
      await pumpForAsyncSettle(tester);
      await tester.ensureVisible(find.text('Post Reel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post Reel'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Attach a photo or video first.'), findsOneWidget);
    },
  );
}
