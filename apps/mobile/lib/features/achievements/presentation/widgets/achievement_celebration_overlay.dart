import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../companion/domain/companion_dialogue.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../domain/achievement.dart';
import '../providers/achievement_celebration_controller.dart';
import '../widgets/achievement_icon.dart';

/// Mounted via `MaterialApp.router`'s `builder:` in `app/app.dart` — that
/// puts this widget's own [BuildContext] inside the app's `Navigator`/
/// `GoRouter` (unlike wrapping `MaterialApp.router` from the outside,
/// which would leave it with no navigator ancestor at all). This matters
/// because mounting inside `AppShell` instead — which only wraps the 5 tab
/// routes — would miss celebrations earned while the user is on the
/// Dashboard, a pushed Workout Summary screen, or anywhere else outside
/// the tab shell.
///
/// Presents one pending celebration at a time via [showAscendBottomSheet]
/// (common achievements) or a full-screen [showDialog] (milestone
/// achievements — see [isMilestoneAchievement]), then automatically moves
/// on to the next queued one, if any, once the current one is dismissed.
/// Both use the app-wide `disableAnimations` `MediaQuery` override already
/// applied in `app.dart` for reduced-motion support, rather than
/// duplicating that logic here.
///
/// Never blocks: both presentations are dismissible immediately (tap
/// outside, back button, or an explicit dismiss action) — this only ever
/// adds a brief, skippable moment, never a forced wait.
class AchievementCelebrationOverlay extends ConsumerStatefulWidget {
  const AchievementCelebrationOverlay({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AchievementCelebrationOverlay> createState() =>
      _AchievementCelebrationOverlayState();
}

class _AchievementCelebrationOverlayState
    extends ConsumerState<AchievementCelebrationOverlay> {
  bool _presenting = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Achievement>>(achievementCelebrationControllerProvider, (
      previous,
      next,
    ) {
      _maybePresentNext(next);
    });

    // Handles the case where a celebration was already queued (e.g. earned
    // offline before a restart) by the time this widget first builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybePresentNext(ref.read(achievementCelebrationControllerProvider));
    });

    return widget.child;
  }

  void _maybePresentNext(List<Achievement> queue) {
    if (_presenting || queue.isEmpty || !mounted) return;

    _presenting = true;
    final achievement = queue.first;
    final companion = ref.read(
      preferencesControllerProvider.select((s) => s.asData?.value?.companion),
    );
    final coachingStyle = ref.read(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.coachingStyle,
      ),
    );
    final message = (companion != null && coachingStyle != null)
        ? CompanionDialogue.celebration(
            companion: companion,
            style: coachingStyle,
            achievementTitle: achievement.title,
          )
        : '"${achievement.title}" earned!';

    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
    );

    final presentation = isMilestoneAchievement(achievement)
        ? _showMilestoneDialog(achievement: achievement, message: message)
        : showAscendBottomSheet<void>(
            context: context,
            title: 'Achievement unlocked',
            child: _CelebrationContent(
              achievement: achievement,
              message: message,
              onView: _viewAchievement,
            ),
          );

    presentation.whenComplete(() async {
      await ref
          .read(achievementCelebrationControllerProvider.notifier)
          .markShown(achievement.id);
      _presenting = false;
      if (!mounted) return;
      // Deliberately does not re-read the controller's state here and
      // present again inline: the Drift watch stream backing that state
      // hasn't necessarily caught up with the delete above yet, so an
      // immediate `ref.read` can still return the achievement we just
      // marked shown, presenting it a second time. `ref.listen` above
      // fires once the stream actually reflects the deletion, which is
      // what reliably advances to the next queued achievement (or does
      // nothing if the queue is now empty).
    });
  }

  Future<void> _showMilestoneDialog({
    required Achievement achievement,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          achievementIconFor(achievement.iconAsset),
          color: AscendColors.premiumGold,
          size: 40,
        ),
        title: const Text('Milestone!'),
        content: Semantics(
          liveRegion: true,
          label: 'Milestone achievement: ${achievement.title}. $message',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievement.title,
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AscendSpacing.sm),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _viewAchievement();
            },
            child: const Text('View medal'),
          ),
        ],
      ),
    );
  }

  /// Uses this State's own long-lived `context` (mounted inside the app's
  /// GoRouter for the whole session) rather than a dialog/sheet's own
  /// short-lived one, which is already gone by the time this runs.
  void _viewAchievement() {
    if (!mounted) return;
    context.push(RoutePaths.achievements);
  }
}

class _CelebrationContent extends StatelessWidget {
  const _CelebrationContent({
    required this.achievement,
    required this.message,
    required this.onView,
  });

  final Achievement achievement;
  final String message;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Achievement unlocked: ${achievement.title}. $message',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                achievementIconFor(achievement.iconAsset),
                color: AscendColors.premiumGold,
                size: 36,
              ),
              const SizedBox(width: AscendSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      achievement.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AscendSpacing.sm),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AscendSpacing.md),
          AscendGhostButton(
            label: 'View medal',
            onPressed: () {
              Navigator.of(context).pop();
              onView();
            },
          ),
        ],
      ),
    );
  }
}
