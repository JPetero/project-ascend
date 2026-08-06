import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../companion/domain/companion_dialogue.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../providers/deload_controller.dart';

/// Shows the user's active deload recommendation, if any — see
/// packages/docs/product/user-scenario-bible.md Scenario 10. Renders
/// nothing when there's no active recommendation, loading, or on error
/// (a deload suggestion is a nice-to-have nudge, never worth an error
/// state of its own on the Dashboard).
class DeloadCard extends ConsumerWidget {
  const DeloadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deloadAsync = ref.watch(activeDeloadProvider);
    final preferences = ref.watch(
      preferencesControllerProvider.select((s) => s.asData?.value),
    );

    return deloadAsync.maybeWhen(
      data: (recommendation) {
        if (recommendation == null) return const SizedBox.shrink();
        final intro = preferences == null
            ? null
            : CompanionDialogue.deloadIntro(
                companion: preferences.companion,
                style: preferences.coachingStyle,
              );
        return Padding(
          padding: const EdgeInsets.only(bottom: AscendSpacing.lg),
          child: AscendCard(
            semanticLabel: 'Deload suggestion',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.self_improvement_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AscendSpacing.sm),
                    Expanded(
                      child: Text(
                        'Consider a lighter week',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AscendSpacing.xs),
                if (intro != null) ...[
                  Text(intro, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AscendSpacing.xs),
                ],
                Text(
                  recommendation.reason,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AscendSpacing.sm),
                Row(
                  children: [
                    AscendGhostButton(
                      label: 'Not now',
                      onPressed: () async {
                        await ref
                            .read(deloadRepositoryProvider)
                            .dismiss(recommendation.id);
                        ref.invalidate(activeDeloadProvider);
                      },
                    ),
                    const SizedBox(width: AscendSpacing.sm),
                    AscendGhostButton(
                      label: 'Remind me later',
                      onPressed: () async {
                        await ref
                            .read(deloadRepositoryProvider)
                            .postpone(recommendation.id);
                        ref.invalidate(activeDeloadProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
