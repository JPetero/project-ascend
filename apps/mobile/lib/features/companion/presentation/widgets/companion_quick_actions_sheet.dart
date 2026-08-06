import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

const _quickActions = [
  _QuickAction(
    icon: Icons.chat_bubble_outline,
    label: 'Ask me anything',
    path: RoutePaths.assistant,
  ),
  _QuickAction(
    icon: Icons.fitness_center_outlined,
    label: "Start today's workout",
    path: RoutePaths.workout,
  ),
  _QuickAction(
    icon: Icons.restaurant_outlined,
    label: 'Log a meal',
    path: RoutePaths.mealPrep,
  ),
  _QuickAction(
    icon: Icons.insights_outlined,
    label: 'Check my progress',
    path: RoutePaths.dashboard,
  ),
];

/// Opened by tapping the floating companion bubble. Offers the four core
/// quick actions plus a microphone placeholder for future voice input.
class CompanionQuickActionsSheet extends StatelessWidget {
  const CompanionQuickActionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAscendBottomSheet<void>(
      context: context,
      title: 'What would you like to do?',
      child: const CompanionQuickActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in _quickActions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(
                action.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(action.label),
            onTap: () {
              Navigator.of(context).pop();
              // Dashboard is a pushed route on top of the shell (see
              // AppShell's [ProfileIconAction] doc comment), not a tab —
              // push it rather than replacing the current tab location.
              if (action.path == RoutePaths.dashboard) {
                context.push(action.path);
              } else {
                context.go(action.path);
              }
            },
          ),
        const SizedBox(height: AscendSpacing.sm),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice input is coming soon.')),
            );
          },
          icon: const Icon(Icons.mic_none_rounded),
          label: const Text('Voice (coming soon)'),
        ),
      ],
    );
  }
}
