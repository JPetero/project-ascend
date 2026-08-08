import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/local_preferences.dart';
import 'package:mobile/features/notifications/presentation/providers/workout_reminder_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_local_notification_scheduling_service.dart';

void main() {
  late FakeLocalNotificationSchedulingService schedulingService;
  late LocalPreferences localPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    schedulingService = FakeLocalNotificationSchedulingService();
    localPreferences = LocalPreferences(await SharedPreferences.getInstance());
  });

  WorkoutReminderController buildController() {
    return WorkoutReminderController(
      schedulingService: schedulingService,
      localPreferences: localPreferences,
    );
  }

  test('defaults to the stored (or default) reminder time, unscheduled', () {
    final controller = buildController();
    expect(controller.state.time, const TimeOfDay(hour: 18, minute: 0));
    expect(controller.state.permissionDenied, isFalse);
    expect(schedulingService.scheduledBaseIds, isEmpty);
  });

  test('sync cancels rather than schedules when disabled', () async {
    final controller = buildController();
    await controller.sync(enabled: false, daysOfWeek: ['MON', 'WED']);

    expect(schedulingService.requestPermissionCallCount, 0);
    expect(schedulingService.scheduledBaseIds, isEmpty);
  });

  test('sync cancels rather than schedules when no days are set', () async {
    final controller = buildController();
    await controller.sync(enabled: true, daysOfWeek: []);

    expect(schedulingService.requestPermissionCallCount, 0);
    expect(schedulingService.scheduledBaseIds, isEmpty);
  });

  test('sync requests permission and schedules for each configured day', () async {
    final controller = buildController();
    await controller.sync(enabled: true, daysOfWeek: ['MON', 'WED', 'FRI']);

    expect(schedulingService.requestPermissionCallCount, 1);
    expect(
      schedulingService.scheduledBaseIds,
      contains(workoutReminderNotificationBaseId),
    );
    final scheduled = schedulingService.lastSchedule[workoutReminderNotificationBaseId]!;
    expect(scheduled.weekdays, {DateTime.monday, DateTime.wednesday, DateTime.friday});
    expect(controller.state.permissionDenied, isFalse);
  });

  test('sync marks permissionDenied and cancels when permission is refused', () async {
    schedulingService.permissionGranted = false;
    final controller = buildController();
    await controller.sync(enabled: true, daysOfWeek: ['MON']);

    expect(controller.state.permissionDenied, isTrue);
    expect(schedulingService.scheduledBaseIds, isEmpty);
  });

  test('setReminderTime persists the new time and resyncs', () async {
    final controller = buildController();
    const newTime = TimeOfDay(hour: 7, minute: 30);

    await controller.setReminderTime(newTime, enabled: true, daysOfWeek: ['TUE']);

    expect(controller.state.time, newTime);
    expect(localPreferences.workoutReminderTime, newTime);
    final scheduled = schedulingService.lastSchedule[workoutReminderNotificationBaseId]!;
    expect(scheduled.time, newTime);
    expect(scheduled.weekdays, {DateTime.tuesday});
  });
}
