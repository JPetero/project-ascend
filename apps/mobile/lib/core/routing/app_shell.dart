import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/presentation/providers/notifications_controller.dart';
import '../design_system/design_system.dart';
import 'route_paths.dart';

/// The main tabbed shell, in the authoritative product order (see
/// packages/docs/product/design-bible.md, Founder Scenario 21): Train,
/// Fuel, Community, Ascend AI, Rankings, and Vision (Premium — see
/// [VisionScreen]). These are renamed labels over the original five tabs
/// (Workout/Meal Prep/Social/Assistant/Leaderboards); Vision is the one
/// genuinely new destination. Profile/Dashboard is intentionally not a
/// destination — see [ProfileIconAction], added to each screen's app bar
/// instead. Each branch keeps its own navigation stack via
/// [StatefulNavigationShell].
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    AscendNavItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center_rounded,
      label: 'Train',
    ),
    AscendNavItem(
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant_rounded,
      label: 'Fuel',
    ),
    AscendNavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Community',
    ),
    AscendNavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Ascend AI',
    ),
    AscendNavItem(
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard_rounded,
      label: 'Rankings',
    ),
    AscendNavItem(
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt_rounded,
      label: 'Vision',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AscendBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        items: _items,
        ascendIndex: 3,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// The notification-bell app-bar action every primary tab screen includes,
/// alongside [ProfileIconAction] — Build Session 8 Part 12. Tapping it
/// pushes the notifications inbox; the badge reflects the same unread
/// count shown there.
class NotificationBellAction extends ConsumerWidget {
  const NotificationBellAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationsInboxControllerProvider.select((s) => s.unreadCount),
    );

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.notifications_none),
      ),
      tooltip: 'Notifications',
      onPressed: () => context.push(RoutePaths.notificationsInbox),
    );
  }
}

/// The profile-icon app-bar action every primary tab screen includes in the
/// upper-right, per the design bible: tapping it pushes the Dashboard
/// screen (not a shell branch), so back navigation (button, Android system
/// back, and the back gesture) all return here without duplicating routes.
class ProfileIconAction extends StatelessWidget {
  const ProfileIconAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Dashboard & profile',
      onPressed: () => context.push(RoutePaths.dashboard),
    );
  }
}
