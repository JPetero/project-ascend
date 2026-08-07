import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/presentation/screens/notifications_inbox_screen.dart';

import '../../helpers/fake_notifications_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows the empty state when there are no events', (tester) async {
    final repository = FakeNotificationsRepository(events: []);
    final container = await createTestContainer(
      signedIn: true,
      notificationsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationsInboxScreen()),
      ),
    );
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationsInboxScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('New friend request'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('tapping an unread event marks it read and hides the badge', (
    tester,
  ) async {
    final repository = FakeNotificationsRepository(
      events: [sampleNotificationEvent(id: 'e1', title: 'New message')],
    );
    final container = await createTestContainer(
      signedIn: true,
      notificationsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationsInboxScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('New message'));
    await pumpForAsyncSettle(tester);

    expect(repository.events.single.isRead, isTrue);
    expect(find.text('Mark all read'), findsNothing);
  });

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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationsInboxScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Mark all read'));
    await pumpForAsyncSettle(tester);

    expect(repository.events.every((e) => e.isRead), isTrue);
    expect(find.text('Mark all read'), findsNothing);
  });
}
