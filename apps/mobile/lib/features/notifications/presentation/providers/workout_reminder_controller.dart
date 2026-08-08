import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/flutter_local_notification_scheduling_service.dart';
import '../../../../core/notifications/local_notification_scheduling_service.dart';
import '../../../../core/notifications/weekday_abbreviation.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_preferences.dart';

/// Build Session 9 Part 9. The one reminder type with real backing data
/// to schedule against — `WorkoutSchedule.daysOfWeek` already has a real
/// editor (onboarding). Rest day/water/meal reminders stay toggle-only
/// this pass: there's no modeled time-of-day for them to schedule
/// against yet — see build-session-9.md.
const workoutReminderNotificationBaseId = 1000;

final localNotificationSchedulingServiceProvider =
    Provider<LocalNotificationSchedulingService>((ref) {
      return FlutterLocalNotificationSchedulingService();
    });

class WorkoutReminderState {
  const WorkoutReminderState({required this.time, this.permissionDenied = false});

  final TimeOfDay time;
  final bool permissionDenied;

  WorkoutReminderState copyWith({TimeOfDay? time, bool? permissionDenied}) {
    return WorkoutReminderState(
      time: time ?? this.time,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

class WorkoutReminderController extends StateNotifier<WorkoutReminderState> {
  WorkoutReminderController({
    required LocalNotificationSchedulingService schedulingService,
    required LocalPreferences localPreferences,
  }) : _schedulingService = schedulingService,
       _localPreferences = localPreferences,
       super(WorkoutReminderState(time: localPreferences.workoutReminderTime));

  final LocalNotificationSchedulingService _schedulingService;
  final LocalPreferences _localPreferences;

  Future<void> setReminderTime(
    TimeOfDay time, {
    required bool enabled,
    required List<String> daysOfWeek,
  }) async {
    await _localPreferences.setWorkoutReminderTime(time);
    state = state.copyWith(time: time);
    await sync(enabled: enabled, daysOfWeek: daysOfWeek);
  }

  /// Cancels the on-device schedule when reminders are off or no workout
  /// days are set; otherwise requests permission (never schedules
  /// without it) and (re)schedules for every configured day.
  Future<void> sync({required bool enabled, required List<String> daysOfWeek}) async {
    if (!enabled || daysOfWeek.isEmpty) {
      await _schedulingService.cancel(workoutReminderNotificationBaseId);
      state = state.copyWith(permissionDenied: false);
      return;
    }

    final granted = await _schedulingService.requestPermission();
    if (!granted) {
      state = state.copyWith(permissionDenied: true);
      await _schedulingService.cancel(workoutReminderNotificationBaseId);
      return;
    }

    state = state.copyWith(permissionDenied: false);
    await _schedulingService.scheduleWeekly(
      baseId: workoutReminderNotificationBaseId,
      title: 'Time to train',
      body: "Ready for today's workout?",
      time: state.time,
      weekdays: weekdaysFromAbbreviations(daysOfWeek),
    );
  }
}

final workoutReminderControllerProvider =
    StateNotifierProvider<WorkoutReminderController, WorkoutReminderState>((ref) {
      return WorkoutReminderController(
        schedulingService: ref.watch(localNotificationSchedulingServiceProvider),
        localPreferences: ref.watch(localPreferencesProvider),
      );
    });
