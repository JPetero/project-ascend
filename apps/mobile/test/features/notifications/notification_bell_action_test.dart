import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/routing/app_shell.dart';

import '../../helpers/fake_notifications_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows the unread badge when there are unread events', (
    tester,
  ) async {
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
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [NotificationBellAction()]),
          ),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('hides the badge when there are no unread events', (
    tester,
  ) async {
    final repository = FakeNotificationsRepository(
      events: [sampleNotificationEvent(id: 'e1', readAt: DateTime(2026, 1, 1))],
    );
    final container = await createTestContainer(
      signedIn: true,
      notificationsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [NotificationBellAction()]),
          ),
        ),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('0'), findsNothing);
  });
}
