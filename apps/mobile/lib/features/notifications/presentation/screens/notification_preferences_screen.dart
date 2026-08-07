import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/notifications_controller.dart';

/// Per-category reminder/notification toggles — Build Session 8 Part 12.
/// The global on/off switch lives on the Dashboard's Settings card
/// (`PreferencesModel.notificationsEnabled`); these six only matter
/// while that switch is on. Copy here is deliberately encouraging, never
/// guilt-based — see NotificationsService.notify's doc comment.
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationPreferencesControllerProvider);
    final controller = ref.read(
      notificationPreferencesControllerProvider.notifier,
    );

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
                      onChanged: (value) =>
                          controller.update({'workoutReminders': value}),
                    ),
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
