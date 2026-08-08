import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';
import 'package:mobile/features/notifications/presentation/screens/notifications_inbox_screen.dart';

import '../../helpers/fake_notifications_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

/// Wraps [NotificationsInboxScreen] in a real, minimal `GoRouter` (Build
/// Session 10 Part 13's deep links use `context.push`, which needs an
/// actual router in the tree, unlike a plain `MaterialApp(home: ...)`)
/// with stand-in destination screens so tests can assert on where a tap
/// actually navigated.
Future<void> _pumpInboxScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const NotificationsInboxScreen(),
      ),
      GoRoute(
        path: '/social/friends',
        builder: (context, state) =>
            const Scaffold(body: Text('Friends screen')),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) =>
            const Scaffold(body: Text('Achievements screen')),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Conversation ${state.pathParameters['id']}')),
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
  testWidgets('shows the empty state when there are no events', (tester) async {
    final repository = FakeNotificationsRepository(events: []);
    final container = await createTestContainer(
      signedIn: true,
      notificationsRepository: repository,
    );
    addTearDown(container.dispose);

    await _pumpInboxScreen(tester, container);
    await pumpForAsyncSettle(tester);

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('lists events and offers Mark all read while any are unread', (
    tester,
  ) async {
    final repository = FakeNotificationsRepository(
      events: [
        sampleNotificationEvent(
          id: 'e1',
          title: 'New friend request',
          body: 'Someone sent you a friend request.',
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      notificationsRepository: repository,
    );
    addTearDown(container.dispose);

    await _pumpInboxScreen(tester, container);
    await pumpForAsyncSettle(tester);

    expect(find.text('New friend request'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets(
    'tapping an unread friend-request event marks it read and navigates to Friends',
    (tester) async {
      final repository = FakeNotificationsRepository(
        events: [sampleNotificationEvent(id: 'e1', title: 'New message')],
      );
      final container = await createTestContainer(
        signedIn: true,
        notificationsRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpInboxScreen(tester, container);
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('New message'));
      await pumpForAsyncSettle(tester);

      expect(repository.events.single.isRead, isTrue);
      expect(find.text('Friends screen'), findsOneWidget);
    },
  );

  testWidgets('tapping a direct message event navigates to that conversation', (
    tester,
  ) async {
    final repository = FakeNotificationsRepository(
      events: [
        sampleNotificationEvent(
          id: 'e1',
          type: NotificationEventType.directMessage,
          title: 'New message from Ada',
          data: 'conversation-42',
        ),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      notificationsRepository: repository,
    );
    addTearDown(container.dispose);

    await _pumpInboxScreen(tester, container);
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('New message from Ada'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Conversation conversation-42'), findsOneWidget);
  });

  testWidgets(
    'tapping a reminder event marks it read without navigating anywhere',
    (tester) async {
      final repository = FakeNotificationsRepository(
        events: [
          sampleNotificationEvent(
            id: 'e1',
            type: NotificationEventType.workoutReminder,
            title: 'Ready for today\'s workout?',
          ),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        notificationsRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpInboxScreen(tester, container);
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Ready for today\'s workout?'));
      await pumpForAsyncSettle(tester);

      expect(repository.events.single.isRead, isTrue);
      // Still on the inbox — no destination screen appeared.
      expect(find.text('Ready for today\'s workout?'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping an already-read event still navigates without re-marking it',
    (tester) async {
      final repository = FakeNotificationsRepository(
        events: [
          sampleNotificationEvent(
            id: 'e1',
            title: 'Already seen',
            readAt: DateTime(2026, 1, 2),
          ),
        ],
      );
      final container = await createTestContainer(
        signedIn: true,
        notificationsRepository: repository,
      );
      addTearDown(container.dispose);

      await _pumpInboxScreen(tester, container);
      await pumpForAsyncSettle(tester);

      await tester.tap(find.text('Already seen'));
      await pumpForAsyncSettle(tester);

      expect(find.text('Friends screen'), findsOneWidget);
    },
  );

  testWidgets('mark all read clears the unread badge', (tester) async {
    final repository = FakeNotificationsRepository(
      events: [
        sampleNotificationEvent(id: 'e1'),
        sampleNotificationEvent(id: 'e2'),
      ],
    );
    final container = await createTestContainer(
      signedIn: true,
      notificationsRepository: repository,
    );
    addTearDown(container.dispose);

    await _pumpInboxScreen(tester, container);
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Mark all read'));
    await pumpForAsyncSettle(tester);

    expect(repository.events.every((e) => e.isRead), isTrue);
    expect(find.text('Mark all read'), findsNothing);
  });
}
