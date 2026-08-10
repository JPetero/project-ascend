import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'local_notification_scheduling_service.dart';

const _channelId = 'ascend_reminders';
const _channelName = 'Reminders';
const _channelDescription = 'Workout and wellness reminders you turned on.';

/// The real, device-backed implementation — wraps
/// `flutter_local_notifications` with `flutter_timezone` resolving the
/// device's actual IANA timezone name (never assumes UTC), so a reminder
/// set for "6:00 PM" actually fires at 6:00 PM local time.
class FlutterLocalNotificationSchedulingService
    implements LocalNotificationSchedulingService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));
    } catch (_) {
      // Falls back to whatever `timezone` already defaults to (UTC) rather
      // than crashing scheduling entirely over a timezone lookup failure.
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  @override
  Future<void> scheduleWeekly({
    required int baseId,
    required String title,
    required String body,
    required TimeOfDay time,
    required Set<int> weekdays,
  }) async {
    await _ensureInitialized();
    await cancel(baseId);

    for (final weekday in weekdays) {
      await _plugin.zonedSchedule(
        _idFor(baseId, weekday),
        title,
        body,
        _nextInstanceOf(weekday, time),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  @override
  Future<void> cancel(int baseId) async {
    await _ensureInitialized();
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(_idFor(baseId, weekday));
    }
  }

  /// Distinct id space from [scheduleWeekly]'s `_idFor` (which only ever
  /// produces `baseId * 10 + weekday`, a small number for this app's
  /// handful of weekly reminder types) — a one-off reminder's [id] is
  /// caller-provided and expected to already be a full, unique
  /// notification id (see ScheduledSessionDetailController).
  @override
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    await _ensureInitialized();
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancelOneOff(int id) async {
    await _ensureInitialized();
    await _plugin.cancel(id);
  }

  /// One notification id per (baseId, weekday) pair, distinct enough for
  /// this app's small number of reminder types not to collide.
  int _idFor(int baseId, int weekday) => baseId * 10 + weekday;

  tz.TZDateTime _nextInstanceOf(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
