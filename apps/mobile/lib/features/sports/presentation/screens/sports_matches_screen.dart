import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../friends/presentation/providers/friends_controller.dart';
import '../../domain/sport_match.dart';
import '../providers/sports_matches_controller.dart';

/// Confirmed sports matches home — Build Session 8 Part 10. Only
/// Badminton exists this session. Reachable from the Community tab.
class SportsMatchesScreen extends ConsumerWidget {
  const SportsMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sportsMatchesControllerProvider);
    final controller = ref.read(sportsMatchesControllerProvider.notifier);
    // Loaded eagerly so the opponent picker isn't racing the fetch.
    ref.watch(friendsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sports')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChallengeDialog(context, ref),
        tooltip: 'Challenge a friend',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(AscendSpacing.md),
                  children: [
                    if (state.rating != null)
                      AscendCard(
                        child: Row(
                          children: [
                            const Icon(Icons.sports_tennis_outlined),
                            const SizedBox(width: AscendSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Badminton rating: ${state.rating!.rating.round()}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    state.rating!.isProvisional
                                        ? 'Provisional · ${state.rating!.matchesPlayed} matches played'
                                        : '${state.rating!.matchesPlayed} matches played',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AscendSpacing.md),
                    if (state.matches.isEmpty)
                      const AscendEmptyState(
                        icon: Icons.sports_tennis_outlined,
                        title: 'No matches yet',
                        message:
                            'Challenge a friend to a confirmed Badminton match.',
                      )
                    else
                      for (final match in state.matches)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AscendSpacing.sm,
                          ),
                          child: AscendCard(
                            onTap: () => context.push(
                              RoutePaths.sportMatchDetailPath(match.id),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(_statusLabel(match.status)),
                                ),
                                if (match.flagged)
                                  const Padding(
                                    padding: EdgeInsets.only(
                                      right: AscendSpacing.sm,
                                    ),
                                    child: Icon(Icons.flag_outlined, size: 16),
                                  ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _showChallengeDialog(BuildContext context, WidgetRef ref) async {
    final friends = ref.read(friendsControllerProvider).friends;

    if (friends.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Challenge a friend'),
          content: const Text(
            'Add a friend first to challenge them to a match.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Challenge a friend to Badminton'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final friend in friends)
                ListTile(
                  title: Text(friend.displayName),
                  onTap: () => Navigator.of(dialogContext).pop(friend.userId),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (chosen == null) return;
    final match = await ref
        .read(sportsMatchesControllerProvider.notifier)
        .createMatch(chosen);
    if (match != null && context.mounted) {
      context.push(RoutePaths.sportMatchDetailPath(match.id));
    }
  }

  String _statusLabel(SportMatchStatus status) {
    switch (status) {
      case SportMatchStatus.created:
        return 'Created';
      case SportMatchStatus.invited:
        return 'Awaiting response';
      case SportMatchStatus.ready:
        return 'Both ready';
      case SportMatchStatus.inProgress:
        return 'In progress';
      case SportMatchStatus.scorePending:
        return 'Score awaiting confirmation';
      case SportMatchStatus.disputed:
        return 'Disputed';
      case SportMatchStatus.confirmed:
        return 'Confirmed';
      case SportMatchStatus.canceled:
        return 'Canceled';
      case SportMatchStatus.void_:
        return 'Voided';
    }
  }
}
