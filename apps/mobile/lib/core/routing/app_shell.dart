import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import 'route_paths.dart';

/// The main tabbed shell, in the authoritative product order (see
/// packages/docs/product/design-bible.md): Workout, Meal Prep, Social,
/// Assistant, Leaderboards. Profile/Dashboard is intentionally not a tab —
/// see [ProfileIconAction], added to each tab screen's app bar instead.
/// Each branch keeps its own navigation stack via [StatefulNavigationShell].
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    AscendNavItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center_rounded,
      label: 'Workout',
    ),
    AscendNavItem(
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant_rounded,
      label: 'Meal Prep',
    ),
    AscendNavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Social',
    ),
    AscendNavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Assistant',
    ),
    AscendNavItem(
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard_rounded,
      label: 'Leaderboards',
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
