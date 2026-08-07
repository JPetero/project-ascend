import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/challenge.dart';
import '../providers/challenges_controller.dart';

/// Home for time-boxed, join-by-choice challenges — Founder Scenario 21.
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengesControllerProvider);
    final controller = ref.read(challengesControllerProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Challenges'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mine'),
              Tab(text: 'Discover'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(RoutePaths.challengeCreate),
          tooltip: 'New challenge',
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: state.isLoading
              ? const AscendLoadingIndicator()
              : RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: TabBarView(
                    children: [
                      _ChallengeList(
                        challenges: state.mine,
                        emptyTitle: 'No challenges yet',
                        emptyMessage:
                            'Create one, or join a challenge from Discover.',
                        onTap: (challenge) => context.push(
                          RoutePaths.challengeDetailPath(challenge.id),
                        ),
                      ),
                      _ChallengeList(
                        challenges: state.discoverable,
                        emptyTitle: 'Nothing to discover right now',
                        emptyMessage:
                            'Check back later, or create your own challenge.',
                        onTap: (challenge) => context.push(
                          RoutePaths.challengeDetailPath(challenge.id),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ChallengeList extends StatelessWidget {
  const _ChallengeList({
    required this.challenges,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onTap,
  });

  final List<Challenge> challenges;
  final String emptyTitle;
  final String emptyMessage;
  final void Function(Challenge challenge) onTap;

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return ListView(
        children: [
          AscendEmptyState(
            icon: Icons.flag_outlined,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        for (final challenge in challenges)
          AscendCard(
            onTap: () => onTap(challenge),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${challenge.participantCount} joined'
                        '${challenge.hasEnded ? ' · Ended' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
      ],
    );
  }
}
