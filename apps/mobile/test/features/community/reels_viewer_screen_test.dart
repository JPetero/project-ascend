import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_post.dart';
import 'package:mobile/features/community/presentation/screens/post_detail_screen.dart';
import 'package:mobile/features/community/presentation/screens/reels_viewer_screen.dart';
import 'package:mobile/features/sharing/presentation/screens/share_content_screen.dart';

import '../../helpers/fake_community_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows a clean empty state when there are no Reels', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ReelsViewerScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('No Reels yet'), findsOneWidget);
  });

  testWidgets(
    'renders only VIDEO posts, driven by the same reelsOnly feed as every '
    'other Community surface (Build Session 10 Part 22)',
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [
          samplePost(
            id: 'reel-1',
            mediaType: CommunityPostMediaType.video,
            caption: 'Reel caption',
            likeCount: 5,
            commentCount: 2,
            saveCount: 1,
          ),
          samplePost(id: 'text-1', caption: 'A text post'),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ReelsViewerScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Reel caption'), findsOneWidget);
      expect(find.text('A text post'), findsNothing);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    },
  );

  testWidgets(
    'every icon-only control has a tooltip a screen reader can announce '
    '(Build Session 10 Parts 27-29)',
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [
          samplePost(
            id: 'reel-1',
            mediaType: CommunityPostMediaType.video,
            isLikedByViewer: false,
            isSavedByViewer: false,
          ),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ReelsViewerScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.byTooltip('Like'), findsOneWidget);
      expect(find.byTooltip('Comments'), findsOneWidget);
      expect(find.byTooltip('Save'), findsOneWidget);
      expect(find.byTooltip('Share'), findsOneWidget);
    },
  );

  testWidgets('tapping like toggles the icon', (tester) async {
    final repository = FakeCommunityRepository(
      posts: [
        samplePost(
          id: 'reel-1',
          mediaType: CommunityPostMediaType.video,
          likeCount: 0,
          isLikedByViewer: false,
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ReelsViewerScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('tapping save toggles the bookmark icon', (tester) async {
    final repository = FakeCommunityRepository(
      posts: [
        samplePost(
          id: 'reel-1',
          mediaType: CommunityPostMediaType.video,
          isSavedByViewer: false,
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ReelsViewerScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await pumpForAsyncSettle(tester);

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets(
    'tapping the comment action opens the existing post detail screen '
    'rather than duplicating comment UI',
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [
          samplePost(id: 'reel-1', mediaType: CommunityPostMediaType.video),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ReelsViewerScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await tester.tap(find.byIcon(Icons.mode_comment_outlined));
      await pumpForAsyncSettle(tester);

      expect(find.byType(PostDetailScreen), findsOneWidget);
    },
  );

  testWidgets('tapping the share action opens the share screen', (
    tester,
  ) async {
    final repository = FakeCommunityRepository(
      posts: [
        samplePost(id: 'reel-1', mediaType: CommunityPostMediaType.video),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ReelsViewerScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byIcon(Icons.ios_share_outlined));
    await pumpForAsyncSettle(tester);

    expect(find.byType(ShareContentScreen), findsOneWidget);
  });

  testWidgets('the close button pops the viewer off the navigation stack', (
    tester,
  ) async {
    final repository = FakeCommunityRepository(
      posts: [
        samplePost(id: 'reel-1', mediaType: CommunityPostMediaType.video),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReelsViewerScreen(),
                    ),
                  ),
                  child: const Text('Open Reels'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Reels'));
    await pumpForAsyncSettle(tester);
    expect(find.byType(ReelsViewerScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await pumpForAsyncSettle(tester);

    expect(find.byType(ReelsViewerScreen), findsNothing);
    expect(find.text('Open Reels'), findsOneWidget);
  });

  testWidgets(
    'initialPostId positions the viewer on that post instead of always '
    'opening at the top of the feed (regression test: the positioning '
    'check used to run against the empty first-frame post list and mark '
    'itself done before the feed ever loaded)',
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [
          samplePost(
            id: 'reel-1',
            mediaType: CommunityPostMediaType.video,
            caption: 'First reel',
          ),
          samplePost(
            id: 'reel-2',
            mediaType: CommunityPostMediaType.video,
            caption: 'Second reel',
          ),
          samplePost(
            id: 'reel-3',
            mediaType: CommunityPostMediaType.video,
            caption: 'Third reel',
          ),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ReelsViewerScreen(initialPostId: 'reel-3'),
          ),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Third reel'), findsOneWidget);
      expect(find.text('First reel'), findsNothing);
    },
  );
}
