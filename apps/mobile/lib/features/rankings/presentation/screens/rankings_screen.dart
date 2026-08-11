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
/// no exact location is ever collected or shown — only self-typed
/// coarse locality labels (country/region/city/local area).
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
    String? localityCountry,
    String? localityRegion,
    String? localityCity,
    String? localityArea,
  })
  onOptIn;

  @override
  State<_OptInPrompt> createState() => _OptInPromptState();
}

class _OptInPromptState extends State<_OptInPrompt> {
  RankingScope _scope = RankingScope.global;
  final _countryController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isSubmitting = false;

  // A given tier requires every field from country down through its
  // own — see RankingScope's doc comment and the backend's
  // rankings-locality.util.ts, which this mirrors.
  bool get _needsCountry => isLocalityScope(_scope);
  bool get _needsRegion => localityTierIndex(_scope) >= 1;
  bool get _needsCity => localityTierIndex(_scope) >= 2;
  bool get _needsArea => localityTierIndex(_scope) >= 3;

  bool get _localityComplete =>
      (!_needsCountry || _countryController.text.trim().isNotEmpty) &&
      (!_needsRegion || _regionController.text.trim().isNotEmpty) &&
      (!_needsCity || _cityController.text.trim().isNotEmpty) &&
      (!_needsArea || _areaController.text.trim().isNotEmpty);

  @override
  void dispose() {
    _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final ok = await widget.onOptIn(
      scope: _scope,
      localityCountry: _needsCountry ? _countryController.text.trim() : null,
      localityRegion: _needsRegion ? _regionController.text.trim() : null,
      localityCity: _needsCity ? _cityController.text.trim() : null,
      localityArea: _needsArea ? _areaController.text.trim() : null,
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
        Wrap(
          spacing: AscendSpacing.sm,
          runSpacing: AscendSpacing.sm,
          children: [
            for (final scope in RankingScope.values)
              ChoiceChip(
                label: Text(rankingScopeLabel(scope)),
                selected: _scope == scope,
                onSelected: (_) => setState(() => _scope = scope),
              ),
          ],
        ),
        if (_needsCountry) ...[
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _countryController,
            label: 'Country',
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_needsRegion) ...[
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _regionController,
            label: 'Region or state',
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_needsCity) ...[
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _cityController,
            label: 'City',
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_needsArea) ...[
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _areaController,
            label: 'Neighborhood or local area',
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: AscendSpacing.lg),
        AscendPrimaryButton(
          label: 'Opt in to Rankings',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting || !_localityComplete ? null : _submit,
        ),
      ],
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView({required this.state, required this.controller});

  final RankingsState state;
  final RankingsController controller;

  bool _canView(RankingScope candidate) {
    if (!isLocalityScope(candidate)) return true;
    final viewerScope = state.status.scope;
    if (viewerScope == null) return false;
    return localityTierIndex(candidate) <= localityTierIndex(viewerScope);
  }

  // S13 Part 8 — a ranking is never a black-box number (design-bible.md's
  // Rankings transparency requirement): this is what a score is actually
  // made of, always shown regardless of the selected category.
  String _provenanceSummary(LeaderboardEntry entry) {
    final parts = <String>[];
    if (entry.strengthDays > 0) {
      parts.add(
        '${entry.strengthDays} strength ${entry.strengthDays == 1 ? 'day' : 'days'}',
      );
    }
    if (entry.cardioDays > 0) {
      final verified = entry.verifiedCardioDays > 0
          ? ', ${entry.verifiedCardioDays} verified'
          : '';
      parts.add(
        '${entry.cardioDays} cardio ${entry.cardioDays == 1 ? 'day' : 'days'}$verified',
      );
    }
    if (entry.nutritionDays > 0) {
      parts.add(
        '${entry.nutritionDays} meal ${entry.nutritionDays == 1 ? 'day' : 'days'}',
      );
    }
    if (parts.isEmpty) return 'No logged activity yet this season';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
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
        Wrap(
          spacing: AscendSpacing.sm,
          runSpacing: AscendSpacing.sm,
          children: [
            for (final scope in RankingScope.values)
              ChoiceChip(
                label: Text(rankingScopeLabel(scope)),
                selected: state.selectedScope == scope,
                onSelected: _canView(scope)
                    ? (_) => controller.selectScope(scope)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: AscendSpacing.sm),
        Text('Ranked by', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AscendSpacing.xs),
        Wrap(
          spacing: AscendSpacing.sm,
          runSpacing: AscendSpacing.sm,
          children: [
            for (final category in RankingCategory.values)
              ChoiceChip(
                label: Text(rankingCategoryLabel(category)),
                selected: state.selectedCategory == category,
                onSelected: (_) => controller.selectCategory(category),
              ),
          ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.isViewer
                              ? '${entry.displayName ?? 'You'} (you)'
                              : (entry.displayName ?? 'Ascend member'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _provenanceSummary(entry),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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
                                  '${rankingScopeLabel(state.selectedScope)} leaderboard',
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
