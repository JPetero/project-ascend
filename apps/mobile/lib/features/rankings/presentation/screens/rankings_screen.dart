import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../sharing/domain/share_content.dart';
import '../../../sharing/presentation/screens/share_content_screen.dart';
import '../../domain/ranking.dart';
import '../providers/rankings_controller.dart';

/// The Rankings tab — opt-in-only leaderboards, per Founder Scenario 16a.
/// Nothing here is simulated: with no [RankingMyStatus.optedIn], the
/// screen shows an honest opt-in prompt instead of a leaderboard, and
/// no exact location is ever collected or shown — only a self-typed
/// coarse region label.
class RankingsScreen extends ConsumerWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rankingsControllerProvider);
    final controller = ref.read(rankingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rankings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Challenges',
            onPressed: () => context.push(RoutePaths.challenges),
          ),
          if (state.status.optedIn)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Ranking settings',
              onPressed: () => _showOptOutSheet(context, controller),
            ),
          const NotificationBellAction(),
          const ProfileIconAction(),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const AscendLoadingIndicator()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: !state.status.optedIn
                    ? _OptInPrompt(onOptIn: controller.optIn)
                    : _LeaderboardView(state: state, controller: controller),
              ),
      ),
    );
  }

  void _showOptOutSheet(BuildContext context, RankingsController controller) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ranking settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AscendSpacing.sm),
              const Text(
                'Opting out removes you from every leaderboard immediately. '
                'You can opt back in any time.',
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendSecondaryButton(
                label: 'Opt out of Rankings',
                onPressed: () {
                  Navigator.pop(context);
                  controller.optOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptInPrompt extends StatefulWidget {
  const _OptInPrompt({required this.onOptIn});

  final Future<bool> Function({
    required RankingScope scope,
    String? regionLabel,
  })
  onOptIn;

  @override
  State<_OptInPrompt> createState() => _OptInPromptState();
}

class _OptInPromptState extends State<_OptInPrompt> {
  RankingScope _scope = RankingScope.global;
  final _regionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final ok = await widget.onOptIn(
      scope: _scope,
      regionLabel: _scope == RankingScope.region
          ? _regionController.text.trim()
          : null,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't opt in — try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        const AscendEmptyState(
          icon: Icons.leaderboard_outlined,
          title: 'Rankings are opt-in',
          message:
              'Join a friendly leaderboard based on active days, never raw '
              'volume or a single streak. Nothing is shown until you opt in, '
              'and you can leave at any time.',
        ),
        const SizedBox(height: AscendSpacing.md),
        Text(
          'Choose who you rank against',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AscendSpacing.sm),
        SegmentedButton<RankingScope>(
          segments: const [
            ButtonSegment(value: RankingScope.friends, label: Text('Friends')),
            ButtonSegment(value: RankingScope.region, label: Text('Region')),
            ButtonSegment(value: RankingScope.global, label: Text('Global')),
          ],
          selected: {_scope},
          onSelectionChanged: (selection) =>
              setState(() => _scope = selection.first),
        ),
        if (_scope == RankingScope.region) ...[
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _regionController,
            label: 'Your region (e.g. a city or state)',
          ),
        ],
        const SizedBox(height: AscendSpacing.lg),
        AscendPrimaryButton(
          label: 'Opt in to Rankings',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting
              ? null
              : (_scope == RankingScope.region &&
                        _regionController.text.trim().isEmpty
                    ? null
                    : _submit),
        ),
      ],
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView({required this.state, required this.controller});

  final RankingsState state;
  final RankingsController controller;

  @override
  Widget build(BuildContext context) {
    final canViewRegion = state.status.scope == RankingScope.region;

    return ListView(
      padding: const EdgeInsets.all(AscendSpacing.md),
      children: [
        AscendCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.status.season?.label ?? 'This season',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${state.status.activeDays ?? 0} active days · '
                      '${state.status.points ?? 0} points',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.md),
        SegmentedButton<RankingScope>(
          segments: [
            const ButtonSegment(
              value: RankingScope.friends,
              label: Text('Friends'),
            ),
            ButtonSegment(
              value: RankingScope.region,
              label: const Text('Region'),
              enabled: canViewRegion,
            ),
            const ButtonSegment(
              value: RankingScope.global,
              label: Text('Global'),
            ),
          ],
          selected: {state.selectedScope},
          onSelectionChanged: (selection) =>
              controller.selectScope(selection.first),
        ),
        const SizedBox(height: AscendSpacing.md),
        if (state.isLeaderboardLoading)
          const Padding(
            padding: EdgeInsets.all(AscendSpacing.lg),
            child: AscendLoadingIndicator(),
          )
        else if (state.leaderboard.isEmpty)
          const AscendEmptyState(
            icon: Icons.groups_outlined,
            title: 'No one here yet',
            message:
                'Once others opt in to this scope, they will show up here.',
          )
        else
          for (final entry in state.leaderboard)
            AscendCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '#${entry.rank}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  CircleAvatar(
                    backgroundImage: entry.avatarUrl != null
                        ? NetworkImage(entry.avatarUrl!)
                        : null,
                    child: entry.avatarUrl == null
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  const SizedBox(width: AscendSpacing.sm),
                  Expanded(
                    child: Text(
                      entry.isViewer
                          ? '${entry.displayName ?? 'You'} (you)'
                          : (entry.displayName ?? 'Ascend member'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${entry.points} pts',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (entry.isViewer)
                    IconButton(
                      icon: const Icon(Icons.ios_share_outlined, size: 18),
                      tooltip: 'Share your rank',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ShareContentScreen(
                            content: ShareContent(
                              type: ShareContentType.rankingMilestone,
                              title: '#${entry.rank}',
                              subtitle:
                                  '${_scopeLabel(state.selectedScope)} leaderboard',
                              statLines: [
                                ShareStatLine(
                                  label: 'Points',
                                  value: '${entry.points}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

String _scopeLabel(RankingScope scope) => switch (scope) {
  RankingScope.friends => 'Friends',
  RankingScope.region => 'Regional',
  RankingScope.global => 'Global',
};
