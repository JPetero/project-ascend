import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_preferences_screen.dart';
import 'package:mobile/features/profile/domain/profile_model.dart';
import 'package:mobile/features/profile/domain/workout_schedule.dart';

import '../../helpers/fake_local_notification_scheduling_service.dart';
import '../../helpers/fake_notifications_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

const _profileWithSchedule = ProfileModel(
  firstName: 'Ada',
  languageCode: 'en',
  timezone: 'UTC',
  unitSystem: UnitSystem.metric,
  sexForCalculations: SexForCalculations.unspecified,
  onboardingCompleted: true,
  onboardingStep: 0,
  workoutSchedule: WorkoutSchedule(
    durationMinutes: 45,
    daysOfWeek: ['MON', 'WED', 'FRI'],
  ),
);

void main() {
  testWidgets(
    'shows the six always-on-by-default categories plus the opt-in come-back reminder',
    (tester) async {
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
      expect(find.text('Come-back reminders'), findsOneWidget);
      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches, hasLength(7));
      // S14 Part 8 — every category defaults to on except the last one
      // (come-back reminders), which is opt-in.
      expect(switches.take(6).every((s) => s.value), isTrue);
      expect(switches.last.value, isFalse);
    },
  );

  testWidgets('opting in to come-back reminders updates the repository', (
    tester,
  ) async {
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

    expect(repository.preferences.reEngagementReminders, isFalse);

    final comeBackSwitch = find.widgetWithText(
      SwitchListTile,
      'Come-back reminders',
    );
    await tester.scrollUntilVisible(
      comeBackSwitch,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpForAsyncSettle(tester);
    await tester.tap(comeBackSwitch);
    await pumpForAsyncSettle(tester);

    expect(repository.preferences.reEngagementReminders, isTrue);
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

  testWidgets(
    'shows no reminder-time row without a workout schedule, and schedules '
    'nothing on-device',
    (tester) async {
      final schedulingService = FakeLocalNotificationSchedulingService();
      final container = await createTestContainer(
        signedIn: true,
        localNotificationSchedulingService: schedulingService,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NotificationPreferencesScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(
        find.text('Set your workout days in onboarding to enable this.'),
        findsOneWidget,
      );
      expect(schedulingService.scheduledBaseIds, isEmpty);
    },
  );

  testWidgets(
    'with a workout schedule, syncs the on-device reminder once reminders '
    'are on',
    (tester) async {
      final schedulingService = FakeLocalNotificationSchedulingService();
      final container = await createTestContainer(
        signedIn: true,
        initialProfile: _profileWithSchedule,
        localNotificationSchedulingService: schedulingService,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NotificationPreferencesScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      expect(find.text('Reminder time'), findsOneWidget);
      expect(schedulingService.scheduledBaseIds, contains(1000));
    },
  );

  testWidgets('shows a permission-denied banner when the OS refuses', (
    tester,
  ) async {
    final schedulingService = FakeLocalNotificationSchedulingService(
      permissionGranted: false,
    );
    final container = await createTestContainer(
      signedIn: true,
      initialProfile: _profileWithSchedule,
      localNotificationSchedulingService: schedulingService,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationPreferencesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(
      find.textContaining('Notifications are turned off for Ascend'),
      findsOneWidget,
    );
    expect(schedulingService.scheduledBaseIds, isEmpty);
  });

  testWidgets('picking a reminder time reschedules with the new time', (
    tester,
  ) async {
    final schedulingService = FakeLocalNotificationSchedulingService();
    final container = await createTestContainer(
      signedIn: true,
      initialProfile: _profileWithSchedule,
      localNotificationSchedulingService: schedulingService,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotificationPreferencesScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.widgetWithText(ListTile, 'Reminder time'));
    await pumpForAsyncSettle(tester);

    // The Material time picker defaults to entry mode with an OK button.
    final okButton = find.text('OK');
    expect(okButton, findsOneWidget);
    await tester.tap(okButton);
    await pumpForAsyncSettle(tester);

    expect(schedulingService.scheduledBaseIds, contains(1000));
  });
}
