import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/notification_deep_link.dart';
import '../../domain/notification_models.dart';
import '../providers/notifications_controller.dart';

IconData _iconFor(NotificationEventType type) {
  switch (type) {
    case NotificationEventType.workoutReminder:
      return Icons.fitness_center_outlined;
    case NotificationEventType.restDayReminder:
      return Icons.bedtime_outlined;
    case NotificationEventType.waterReminder:
      return Icons.water_drop_outlined;
    case NotificationEventType.mealReminder:
      return Icons.restaurant_outlined;
    case NotificationEventType.achievementUnlocked:
      return Icons.emoji_events_outlined;
    case NotificationEventType.friendRequest:
      return Icons.person_add_alt_outlined;
    case NotificationEventType.directMessage:
      return Icons.chat_bubble_outline;
    case NotificationEventType.groupInvite:
      return Icons.groups_2_outlined;
    case NotificationEventType.challenge:
      return Icons.flag_outlined;
    case NotificationEventType.jointWorkout:
      return Icons.group_work_outlined;
    case NotificationEventType.sportsMatch:
      return Icons.sports_tennis_outlined;
    case NotificationEventType.supportReply:
    case NotificationEventType.supportStatusChanged:
      return Icons.support_agent_outlined;
    case NotificationEventType.moderationDecision:
    case NotificationEventType.moderationAppealUpdate:
      return Icons.shield_outlined;
    case NotificationEventType.promoteReview:
      return Icons.campaign_outlined;
    case NotificationEventType.trainerVerificationUpdate:
      return Icons.verified_outlined;
    case NotificationEventType.eligibilityVerificationUpdate:
      return Icons.workspace_premium_outlined;
    case NotificationEventType.unknown:
      return Icons.notifications_outlined;
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// The caller's notification inbox — Build Session 8 Part 12. Reachable
/// from the bell icon on every primary tab's app bar
/// ([NotificationBellAction]).
class NotificationsInboxScreen extends ConsumerWidget {
  const NotificationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsInboxControllerProvider);
    final controller = ref.read(notificationsInboxControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification preferences',
            onPressed: () => context.push(RoutePaths.notificationPreferences),
          ),
          if (state.unreadCount > 0)
            TextButton(
              onPressed: controller.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : state.error != null
            ? AscendEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load your notifications',
                message: state.error.toString(),
                actionLabel: 'Retry',
                onAction: controller.refresh,
              )
            : state.events.isEmpty
            ? const AscendEmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                message:
                    "Friend requests, messages, and reminders you've "
                    'opted into will show up here.',
              )
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  itemCount: state.events.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AscendSpacing.sm),
                  itemBuilder: (context, index) {
                    final event = state.events[index];
                    return AscendCard(
                      onTap: () {
                        if (!event.isRead) controller.markRead(event.id);
                        final path = deepLinkPathFor(event.type, event.data);
                        if (path != null) context.push(path);
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_iconFor(event.type)),
                          const SizedBox(width: AscendSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: event.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  event.body,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: AscendSpacing.xs),
                                Text(
                                  _relativeTime(event.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (!event.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(
                                top: AscendSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
