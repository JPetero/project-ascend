import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';

/// Honest coming-soon state — see packages/docs/product/design-bible.md's
/// rule against showing fake ranks or activity in production mode. No
/// simulated leaderboard here; it ships as a real feature later (see
/// packages/docs/product/parking-lot.md).
class LeaderboardsScreen extends StatelessWidget {
  const LeaderboardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        actions: const [ProfileIconAction()],
      ),
      body: const SafeArea(
        child: Center(
          child: AscendEmptyState(
            icon: Icons.leaderboard_outlined,
            title: 'Leaderboards are on their way',
            message:
                'Friendly rankings and challenges will arrive in a future '
                'release. Nothing here is simulated in the meantime.',
          ),
        ),
      ),
    );
  }
}
