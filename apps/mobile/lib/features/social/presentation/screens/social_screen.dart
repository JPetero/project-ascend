import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';

/// Honest coming-soon state — see packages/docs/product/design-bible.md's
/// rule against showing fake users, posts, or activity in production mode.
/// No sample data here; Social ships as a real feature later (see
/// packages/docs/product/parking-lot.md).
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        actions: const [ProfileIconAction()],
      ),
      body: const SafeArea(
        child: Center(
          child: AscendEmptyState(
            icon: Icons.groups_outlined,
            title: 'Social is on its way',
            message:
                'Following friends, sharing progress, and challenges will '
                'arrive in a future release. Nothing here is simulated in '
                'the meantime.',
          ),
        ),
      ),
    );
  }
}
