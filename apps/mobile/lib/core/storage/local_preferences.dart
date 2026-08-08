import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local settings only (theme choice, reduced-motion flag,
/// last-seen onboarding step). Never store tokens or health data here.
class LocalPreferences {
  LocalPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'ascend.theme_mode';
  static const _reducedMotionKey = 'ascend.reduced_motion';
  static const _onboardingCompletedKey = 'ascend.onboarding_completed';
  static const _workoutReminderTimeKey = 'ascend.workout_reminder_time';
  static const _defaultWorkoutReminderTime = TimeOfDay(hour: 18, minute: 0);

  String? get themeMode => _prefs.getString(_themeModeKey);
  Future<void> setThemeMode(String value) =>
      _prefs.setString(_themeModeKey, value);

  bool get reducedMotion => _prefs.getBool(_reducedMotionKey) ?? false;
  Future<void> setReducedMotion(bool value) =>
      _prefs.setBool(_reducedMotionKey, value);

  bool get onboardingCompleted =>
      _prefs.getBool(_onboardingCompletedKey) ?? false;
  Future<void> setOnboardingCompleted(bool value) =>
      _prefs.setBool(_onboardingCompletedKey, value);

  /// The on-device time workout reminders fire — purely local, since the
  /// backend's `WorkoutSchedule.preferredTime` field has no editor UI
  /// anywhere in the app yet (see build-session-9.md).
  TimeOfDay get workoutReminderTime {
    final raw = _prefs.getString(_workoutReminderTimeKey);
    if (raw == null) return _defaultWorkoutReminderTime;
    final parts = raw.split(':');
    if (parts.length != 2) return _defaultWorkoutReminderTime;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return _defaultWorkoutReminderTime;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setWorkoutReminderTime(TimeOfDay value) => _prefs.setString(
    _workoutReminderTimeKey,
    '${value.hour}:${value.minute}',
  );

  Future<void> clear() async {
    await _prefs.remove(_onboardingCompletedKey);
  }
}
