import 'package:flutter/material.dart';
import 'package:mobile/core/notifications/local_notification_scheduling_service.dart';

class FakeLocalNotificationSchedulingService
    implements LocalNotificationSchedulingService {
  FakeLocalNotificationSchedulingService({this.permissionGranted = true});

  bool permissionGranted;
  final Set<int> scheduledBaseIds = {};
  final Map<int, ({TimeOfDay time, Set<int> weekdays})> lastSchedule = {};
  int requestPermissionCallCount = 0;
  final Set<int> scheduledOneOffIds = {};
  final Map<int, ({String title, String body, DateTime dateTime})>
  lastOneOffSchedule = {};

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

  @override
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!dateTime.isAfter(DateTime.now())) return;
    scheduledOneOffIds.add(id);
    lastOneOffSchedule[id] = (title: title, body: body, dateTime: dateTime);
  }

  @override
  Future<void> cancelOneOff(int id) async {
    scheduledOneOffIds.remove(id);
    lastOneOffSchedule.remove(id);
  }
}
