import 'package:flutter/material.dart';
import 'package:mobile/core/notifications/local_notification_scheduling_service.dart';

class FakeLocalNotificationSchedulingService
    implements LocalNotificationSchedulingService {
  FakeLocalNotificationSchedulingService({this.permissionGranted = true});

  bool permissionGranted;
  final Set<int> scheduledBaseIds = {};
  final Map<int, ({TimeOfDay time, Set<int> weekdays})> lastSchedule = {};
  int requestPermissionCallCount = 0;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCallCount++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleWeekly({
    required int baseId,
    required String title,
    required String body,
    required TimeOfDay time,
    required Set<int> weekdays,
  }) async {
    scheduledBaseIds.add(baseId);
    lastSchedule[baseId] = (time: time, weekdays: weekdays);
  }

  @override
  Future<void> cancel(int baseId) async {
    scheduledBaseIds.remove(baseId);
    lastSchedule.remove(baseId);
  }
}
