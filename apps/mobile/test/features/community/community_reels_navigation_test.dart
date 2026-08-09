import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routing/route_paths.dart';
import 'package:mobile/features/community/domain/community_post.dart';
import 'package:mobile/features/community/domain/community_profile.dart';
import 'package:mobile/features/community/presentation/screens/community_feed_screen.dart';
import 'package:mobile/features/community/presentation/screens/community_profile_screen.dart';
import 'package:mobile/features/community/presentation/screens/saved_posts_screen.dart';

import '../../helpers/fake_community_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

/// Confirms the three Community list surfaces (main feed, Saved posts,
/// and a member's profile) route a VIDEO post tap to the full-screen
/// Reels viewer instead of the ordinary post detail screen (Build
/// Session 10 Part 22) — a real, minimal `GoRouter` is needed here
/// because these screens navigate with `context.push`.
Future<void> _pumpWithRouter(
  WidgetTester tester,
  ProviderContainer container,
  Widget home,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: RoutePaths.reelsViewer,
        builder: (context, state) =>
            Scaffold(body: Text('Reels viewer ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: RoutePaths.communityPostDetail,
        builder: (context, state) =>
            Scaffold(body: Text('Post detail ${state.pathParameters['id']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets(
    'CommunityFeedScreen routes a VIDEO post tap to the Reels viewer',
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [
          samplePost(
            id: 'reel-1',
            mediaType: CommunityPostMediaType.video,
            caption: 'A Reel',
          ),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpWithRouter(tester, container, const CommunityFeedScreen());
      await pumpForAsyncSettle(tester);

      final target = find.text('A Reel');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await pumpForAsyncSettle(tester);

      expect(find.text('Reels viewer reel-1'), findsOneWidget);
    },
  );

  testWidgets('CommunityFeedScreen routes a TEXT post tap to the ordinary post '
      'detail screen', (tester) async {
    final repository = FakeCommunityRepository(
      posts: [samplePost(id: 'text-1', caption: 'A text post')],
    );
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await _pumpWithRouter(tester, container, const CommunityFeedScreen());
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('A text post'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Post detail text-1'), findsOneWidget);
  });

  testWidgets('SavedPostsScreen routes a VIDEO post tap to the Reels viewer', (
    tester,
  ) async {
    final repository = FakeCommunityRepository(
      posts: [
        samplePost(
          id: 'reel-1',
          mediaType: CommunityPostMediaType.video,
          caption: 'A saved Reel',
          isSavedByViewer: true,
        ),
      ],
    );
    repository.savedPostIds.add('reel-1');
    final container = await createTestContainer(
      signedIn: true,
      communityRepository: repository,
    );
    addTearDown(container.dispose);

    await _pumpWithRouter(tester, container, const SavedPostsScreen());
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('A saved Reel'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Reels viewer reel-1'), findsOneWidget);
  });

  testWidgets(
    'CommunityProfileScreen routes a VIDEO post tap to the Reels viewer',
    (tester) async {
      final repository = FakeCommunityRepository(
        posts: [
          samplePost(
            id: 'reel-1',
            authorId: 'author-1',
            mediaType: CommunityPostMediaType.video,
            caption: 'A profile Reel',
          ),
        ],
        profiles: [
          const CommunityProfile(userId: 'author-1', displayName: 'Ada'),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        communityRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpWithRouter(
        tester,
        container,
        const CommunityProfileScreen(userId: 'author-1'),
      );
      await pumpForAsyncSettle(tester);

      final target = find.text('A profile Reel');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await pumpForAsyncSettle(tester);

      expect(find.text('Reels viewer reel-1'), findsOneWidget);
    },
  );
}
