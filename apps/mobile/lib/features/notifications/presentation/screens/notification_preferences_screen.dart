import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../providers/notifications_controller.dart';
import '../providers/workout_reminder_controller.dart';

/// Per-category reminder/notification toggles — Build Session 8 Part 12.
/// The global on/off switch lives on the Dashboard's Settings card
/// (`PreferencesModel.notificationsEnabled`); these six only matter
/// while that switch is on. Copy here is deliberately encouraging, never
/// guilt-based — see NotificationsService.notify's doc comment.
///
/// Build Session 9 Part 9 adds real, device-scheduled local
/// notifications for workout reminders — the one category with a real
/// day-of-week schedule to draw from (`WorkoutSchedule.daysOfWeek`).
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  List<String> get _daysOfWeek =>
      ref.read(profileControllerProvider).asData?.value?.workoutSchedule?.daysOfWeek ??
      const [];

  Future<void> _syncWorkoutReminders(bool enabled) async {
    await ref
        .read(workoutReminderControllerProvider.notifier)
        .sync(enabled: enabled, daysOfWeek: _daysOfWeek);
  }

  Future<void> _pickReminderTime(TimeOfDay current, bool enabled) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    await ref
        .read(workoutReminderControllerProvider.notifier)
        .setReminderTime(picked, enabled: enabled, daysOfWeek: _daysOfWeek);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationPreferencesControllerProvider);
    final controller = ref.read(notificationPreferencesControllerProvider.notifier);
    final reminderState = ref.watch(workoutReminderControllerProvider);

    // Resyncing the on-device schedule depends on two independently-async
    // providers: the "reminders on?" toggle (notificationPreferencesController)
    // and the workout days (profileController). Whichever settles second
    // is the one that actually has both values available, so both listen
    // for the other's already-resolved state rather than assuming a load
    // order.
    ref.listen<AsyncValue<dynamic>>(notificationPreferencesControllerProvider, (
      previous,
      next,
    ) {
      final enabled = next.asData?.value?.workoutReminders as bool?;
      if (enabled != null) _syncWorkoutReminders(enabled);
    });
    ref.listen<AsyncValue<dynamic>>(profileControllerProvider, (previous, next) {
      if (!next.hasValue) return;
      final enabled = ref
          .read(notificationPreferencesControllerProvider)
          .asData
          ?.value
          .workoutReminders;
      if (enabled != null) _syncWorkoutReminders(enabled);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Notification preferences')),
      body: SafeArea(
        child: state.when(
          loading: () => const AscendLoadingIndicator(),
          error: (error, _) => AscendEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load your preferences',
            message: error.toString(),
            actionLabel: 'Retry',
            onAction: controller.load,
          ),
          data: (preferences) => ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              AscendCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Workout reminders'),
                      subtitle: const Text("Ready for today's workout?"),
                      value: preferences.workoutReminders,
                      // Resyncing the on-device schedule happens via the
                      // ref.listen below, which fires for this change too
                      // (as well as the very first successful load) —
                      // one path, not a duplicate call here.
                      onChanged: (value) => controller.update({'workoutReminders': value}),
                    ),
                    if (preferences.workoutReminders) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_outlined),
                        title: const Text('Reminder time'),
                        subtitle: Text(
                          _daysOfWeek.isEmpty
                              ? 'Set your workout days in onboarding to enable this.'
                              : reminderState.time.format(context),
                        ),
                        onTap: _daysOfWeek.isEmpty
                            ? null
                            : () => _pickReminderTime(
                                reminderState.time,
                                preferences.workoutReminders,
                              ),
                      ),
                      if (reminderState.permissionDenied)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                          child: Text(
                            'Notifications are turned off for Ascend in your '
                            'device settings, so this reminder cannot be '
                            'scheduled yet.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Rest day reminders'),
                      subtitle: const Text('A nudge to recover well.'),
                      value: preferences.restDayReminders,
                      onChanged: (value) =>
                          controller.update({'restDayReminders': value}),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Water reminders'),
                      subtitle: const Text('Stay hydrated through the day.'),
                      value: preferences.waterReminders,
                      onChanged: (value) =>
                          controller.update({'waterReminders': value}),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Meal reminders'),
                      subtitle: const Text('Prompts to log your meals.'),
                      value: preferences.mealReminders,
                      onChanged: (value) =>
                          controller.update({'mealReminders': value}),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Achievements'),
                      subtitle: const Text('When you unlock something new.'),
                      value: preferences.achievementNotifications,
                      onChanged: (value) => controller.update({
                        'achievementNotifications': value,
                      }),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Social'),
                      subtitle: const Text(
                        'Friend requests, messages, joint workouts, sports '
                        'matches, and group invites.',
                      ),
                      value: preferences.socialNotifications,
                      onChanged: (value) =>
                          controller.update({'socialNotifications': value}),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
