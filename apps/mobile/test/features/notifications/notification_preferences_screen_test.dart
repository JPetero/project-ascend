import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_preferences_screen.dart';

import '../../helpers/fake_notifications_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows the six categories, each defaulting to on', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationPreferencesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Workout reminders'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();
    expect(switches, hasLength(6));
    expect(switches.every((s) => s.value), isTrue);
  });

  testWidgets('toggling a switch updates the repository', (tester) async {
    final repository = FakeNotificationsRepository();
    final container = await createTestContainer(
      signedIn: true,
      notificationsRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationPreferencesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Water reminders'));
    await pumpForAsyncSettle(tester);

    expect(repository.preferences.waterReminders, isFalse);
  });
}
