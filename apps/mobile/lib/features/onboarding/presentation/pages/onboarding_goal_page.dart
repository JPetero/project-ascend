import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/onboarding_controller.dart';

const _goals = [
  ('BUILD_STRENGTH', 'Build strength'),
  ('LOSE_WEIGHT', 'Lose weight'),
  ('IMPROVE_ENDURANCE', 'Improve endurance'),
  ('IMPROVE_MOBILITY', 'Improve mobility'),
  ('STAY_CONSISTENT', 'Stay consistent'),
  ('GENERAL_HEALTH', 'General health'),
];

class OnboardingGoalPage extends ConsumerWidget {
  const OnboardingGoalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = ref.watch(
      onboardingControllerProvider.select((s) => s.draft.primaryGoal),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AscendSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What matters most to you right now? We'll shape your recommendations around this "
            'goal, your ability, equipment, and preferences — not just one factor.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AscendSpacing.lg),
          Wrap(
            spacing: AscendSpacing.sm,
            runSpacing: AscendSpacing.sm,
            children: [
              for (final (value, label) in _goals)
                ChoiceChip(
                  label: Text(label),
                  selected: selectedGoal == value,
                  onSelected: (_) => ref
                      .read(onboardingControllerProvider.notifier)
                      .updateDraft((d) => d.copyWith(primaryGoal: value)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
