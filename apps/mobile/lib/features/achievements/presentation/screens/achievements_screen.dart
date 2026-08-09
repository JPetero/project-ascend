import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../sharing/domain/share_content.dart';
import '../../../sharing/presentation/screens/share_content_screen.dart';
import '../../domain/achievement.dart';
import '../providers/achievement_controller.dart';
import '../widgets/achievement_icon.dart';

/// The full achievement catalog — earned achievements ("medals") shown in
/// full color with their earned date, locked ones shown muted with a
/// progress bar toward `targetSteps`. Never implies an achievement is
/// earned before the server actually recorded `earnedAt` — see
/// packages/docs/product/atlas-nova-bible.md's celebration rules.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: SafeArea(
        child: achievementsAsync.when(
          data: (achievements) {
            if (achievements.isEmpty) {
              return const AscendEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No achievements yet',
                message:
                    'Complete a workout or log a meal to start earning achievements.',
              );
            }

            final earnedCount = achievements.where((a) => a.isEarned).length;
            final byCategory = <AchievementCategory, List<Achievement>>{};
            for (final achievement in achievements) {
              byCategory
                  .putIfAbsent(achievement.category, () => [])
                  .add(achievement);
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(achievementsProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(AscendSpacing.md),
                children: [
                  Text(
                    '$earnedCount of ${achievements.length} earned',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AscendSpacing.md),
                  for (final category in byCategory.keys) ...[
                    AscendSectionHeader(
                      title: achievementCategoryLabel(category),
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    for (final achievement in byCategory[category]!)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AscendSpacing.sm,
                        ),
                        child: _AchievementCard(achievement: achievement),
                      ),
                    const SizedBox(height: AscendSpacing.md),
                  ],
                ],
              ),
            );
          },
          loading: () => const AscendLoadingIndicator(),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load your achievements",
            message: 'Pull to refresh to try again.',
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = achievement.isEarned;
    final iconColor = earned
        ? AscendColors.premiumGold
        : theme.colorScheme.onSurfaceVariant;

    return AscendCard(
      semanticLabel: earned
          ? '${achievement.title}, earned'
          : '${achievement.title}, locked, ${achievement.progress} of ${achievement.targetSteps}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            achievementIconFor(achievement.iconAsset),
            color: iconColor,
            size: 32,
          ),
          const SizedBox(width: AscendSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: earned ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AscendSpacing.xs),
                Text(achievement.description, style: theme.textTheme.bodySmall),
                if (!earned && achievement.targetSteps > 1) ...[
                  const SizedBox(height: AscendSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AscendRadius.small),
                    child: LinearProgressIndicator(
                      value: achievement.progress / achievement.targetSteps,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: AscendSpacing.xs),
                  Text(
                    '${achievement.progress} / ${achievement.targetSteps}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (earned) ...[
            const Icon(Icons.check_circle, color: AscendColors.successEmerald),
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              tooltip: 'Share this achievement',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ShareContentScreen(
                    content: ShareContent(
                      type: ShareContentType.achievement,
                      title: achievement.title,
                      subtitle: achievement.description,
                      statLines: [
                        ShareStatLine(
                          label: 'Category',
                          value: achievementCategoryLabel(achievement.category),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
