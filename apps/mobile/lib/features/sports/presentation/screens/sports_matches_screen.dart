import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../friends/presentation/providers/friends_controller.dart';
import '../../data/sports_repository.dart';
import '../../domain/sport_match.dart';
import '../providers/sports_matches_controller.dart';

/// Confirmed sports matches home — Build Session 8 Part 10. Badminton
/// and Table Tennis (Build Session 12 Part 23-24) share this same
/// generic point/set match engine. Reachable from the Community tab.
class SportsMatchesScreen extends ConsumerWidget {
  const SportsMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sportsMatchesControllerProvider);
    final controller = ref.read(sportsMatchesControllerProvider.notifier);
    // Loaded eagerly so the opponent picker isn't racing the fetch.
    ref.watch(friendsControllerProvider);

    final selectedSportName = _sportName(state.sports, state.selectedSportCode);

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
                    if (state.sports.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AscendSpacing.md,
                        ),
                        child: SegmentedButton<String>(
                          segments: [
                            for (final sport in state.sports)
                              ButtonSegment(
                                value: sport.code,
                                label: Text(sport.name),
                              ),
                          ],
                          selected: {state.selectedSportCode},
                          onSelectionChanged: (selection) =>
                              controller.selectSport(selection.first),
                        ),
                      ),
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
                                    '$selectedSportName rating: ${state.rating!.rating.round()}',
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
                        message: 'Challenge a friend to a confirmed match.',
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (match.sportName != null)
                                        Text(
                                          match.sportName!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      Text(_statusLabel(match.status)),
                                    ],
                                  ),
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

  String _sportName(List<SportSummary> sports, String code) {
    for (final sport in sports) {
      if (sport.code == code) return sport.name;
    }
    return code == SportsRepository.tableTennisCode
        ? 'Table Tennis'
        : 'Badminton';
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

    final state = ref.read(sportsMatchesControllerProvider);
    final sports = state.sports.isNotEmpty
        ? state.sports
        : const [
            SportSummary(
              code: SportsRepository.badmintonCode,
              name: 'Badminton',
            ),
          ];
    var chosenSportCode = state.selectedSportCode;

    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Challenge a friend'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sports.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: chosenSportCode,
                      items: [
                        for (final sport in sports)
                          DropdownMenuItem(
                            value: sport.code,
                            child: Text(sport.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => chosenSportCode = value);
                        }
                      },
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final friend in friends)
                        ListTile(
                          title: Text(friend.displayName),
                          onTap: () =>
                              Navigator.of(dialogContext).pop(friend.userId),
                        ),
                    ],
                  ),
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
      ),
    );

    if (chosen == null) return;
    final match = await ref
        .read(sportsMatchesControllerProvider.notifier)
        .createMatch(chosen, sportCode: chosenSportCode);
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
