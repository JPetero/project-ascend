import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/presentation/screens/post_detail_screen.dart';
import 'package:mobile/features/sharing/presentation/screens/share_content_screen.dart';

import '../../helpers/fake_community_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'sharing from the post detail screen opens the share screen (Build '
    'Session 10 Parts 20-21 — this screen never wired onShare at all)',
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [samplePost(id: 'post-1', caption: 'New deadlift PR')],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PostDetailScreen(postId: 'post-1')),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);

      await tester.tap(find.text('Share'));
      await pumpForAsyncSettle(tester);

      expect(find.byType(ShareContentScreen), findsOneWidget);
    },
  );
}
