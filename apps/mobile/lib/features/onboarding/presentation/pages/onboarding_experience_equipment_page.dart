import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../profile/domain/equipment_item.dart';
import '../providers/onboarding_controller.dart';

const _experienceLevels = [
  ('BEGINNER', 'New to exercise'),
  ('INTERMEDIATE', 'Some experience'),
  ('ADVANCED', 'Very experienced'),
];

const _equipmentOptions = [
  ('BODYWEIGHT_ONLY', 'No equipment'),
  ('DUMBBELLS', 'Dumbbells'),
  ('RESISTANCE_BANDS', 'Resistance bands'),
  ('BARBELL', 'Barbell'),
  ('KETTLEBELL', 'Kettlebell'),
  ('PULL_UP_BAR', 'Pull-up bar'),
  ('FULL_GYM', 'Full gym access'),
];

class OnboardingExperienceEquipmentPage extends ConsumerWidget {
  const OnboardingExperienceEquipmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(
      onboardingControllerProvider.select((s) => s.draft),
    );
    final selectedTypes = draft.equipment.map((e) => e.type).toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AscendSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Experience level',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AscendSpacing.sm),
          Wrap(
            spacing: AscendSpacing.sm,
            runSpacing: AscendSpacing.sm,
            children: [
              for (final (value, label) in _experienceLevels)
                ChoiceChip(
                  label: Text(label),
                  selected: draft.experienceLevel == value,
                  onSelected: (_) => ref
                      .read(onboardingControllerProvider.notifier)
                      .updateDraft((d) => d.copyWith(experienceLevel: value)),
                ),
            ],
          ),
          const SizedBox(height: AscendSpacing.lg),
          Text(
            'Available equipment',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AscendSpacing.sm),
          Wrap(
            spacing: AscendSpacing.sm,
            runSpacing: AscendSpacing.sm,
            children: [
              for (final (value, label) in _equipmentOptions)
                FilterChip(
                  label: Text(label),
                  selected: selectedTypes.contains(value),
                  onSelected: (isSelected) {
                    final updated = [...draft.equipment];
                    if (isSelected) {
                      updated.add(EquipmentItem(type: value));
                    } else {
                      updated.removeWhere((e) => e.type == value);
                    }
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .updateDraft((d) => d.copyWith(equipment: updated));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
