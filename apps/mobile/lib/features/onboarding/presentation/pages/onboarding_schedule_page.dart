import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/onboarding_controller.dart';

const _durations = [15, 30, 45, 60, 90];
const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class OnboardingSchedulePage extends ConsumerWidget {
  const OnboardingSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(
      onboardingControllerProvider.select((s) => s.draft),
    );
    final selectedDays = draft.daysOfWeek.toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AscendSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preferred workout duration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AscendSpacing.sm),
          Wrap(
            spacing: AscendSpacing.sm,
            children: [
              for (final duration in _durations)
                ChoiceChip(
                  label: Text('$duration min'),
                  selected: draft.durationMinutes == duration,
                  onSelected: (_) => ref
                      .read(onboardingControllerProvider.notifier)
                      .updateDraft(
                        (d) => d.copyWith(durationMinutes: duration),
                      ),
                ),
            ],
          ),
          const SizedBox(height: AscendSpacing.lg),
          Text('Workout days', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AscendSpacing.sm),
          Wrap(
            spacing: AscendSpacing.sm,
            runSpacing: AscendSpacing.sm,
            children: [
              for (final day in _days)
                FilterChip(
                  label: Text(day),
                  selected: selectedDays.contains(day),
                  onSelected: (isSelected) {
                    final updated = [...draft.daysOfWeek];
                    if (isSelected) {
                      updated.add(day);
                    } else {
                      updated.remove(day);
                    }
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .updateDraft((d) => d.copyWith(daysOfWeek: updated));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
