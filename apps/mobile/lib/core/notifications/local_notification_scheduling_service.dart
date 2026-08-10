import 'package:flutter/material.dart';

/// Build Session 9 Part 9 — a thin boundary over the device's own
/// notification scheduler, mirroring `LiveLocationService`'s
/// interface-over-plugin style so callers stay fake-able in tests. Local
/// notifications are OS-scheduled and delivered even if the app process
/// isn't running — no background service/isolate is involved, matching
/// this app's existing "never keep things running off-screen" stance
/// (see LiveCardioSessionController's foreground-only GPS tracking).
///
/// [weekdays] use `DateTime.monday`..`DateTime.sunday` (1..7). One
/// underlying OS notification is scheduled per weekday under
/// `baseId`-derived ids, so [cancel] must be able to remove all of them
/// together.
abstract class LocalNotificationSchedulingService {
  /// Requests the OS notification permission (Android 13+, iOS). Returns
  /// whether it was granted — callers must never schedule without this
  /// returning true first, and must show an honest "notifications are
  /// off" state rather than silently failing when it returns false.
  Future<bool> requestPermission();

  Future<void> scheduleWeekly({
    required int baseId,
    required String title,
    required String body,
    required TimeOfDay time,
    required Set<int> weekdays,
  });

  Future<void> cancel(int baseId);

  /// A single reminder at an exact date/time rather than a recurring
  /// weekly slot (Build Session 13 continuation Part B — trainer
  /// scheduled-session RSVP reminders). [dateTime] in the past never
  /// fires; callers don't need to check that themselves.
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  });

  Future<void> cancelOneOff(int id);
}
