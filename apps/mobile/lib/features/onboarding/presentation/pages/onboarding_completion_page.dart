import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../companion/domain/companion_animation_state.dart';
import '../../../companion/presentation/widgets/companion_avatar.dart';
import '../../../profile/domain/preferences_model.dart';
import '../providers/onboarding_controller.dart';

class OnboardingCompletionPage extends ConsumerWidget {
  const OnboardingCompletionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(
      onboardingControllerProvider.select((s) => s.draft),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AscendSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompanionAvatar(
              companion: draft.companion ?? Companion.atlas,
              state: CompanionAnimationState.celebrating,
              size: 120,
            ),
            const SizedBox(height: AscendSpacing.lg),
            Text(
              "You're ready, ${draft.firstName ?? 'friend'}!",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AscendSpacing.sm),
            Text(
              'Your dashboard, workouts, and companion are ready whenever you are.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
