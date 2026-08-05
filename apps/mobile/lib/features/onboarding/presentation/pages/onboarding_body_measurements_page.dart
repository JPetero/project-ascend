import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../profile/domain/profile_model.dart';
import '../providers/onboarding_controller.dart';

class OnboardingBodyMeasurementsPage extends ConsumerStatefulWidget {
  const OnboardingBodyMeasurementsPage({super.key});

  @override
  ConsumerState<OnboardingBodyMeasurementsPage> createState() =>
      _OnboardingBodyMeasurementsPageState();
}

class _OnboardingBodyMeasurementsPageState
    extends ConsumerState<OnboardingBodyMeasurementsPage> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).draft;
    _heightController = TextEditingController(
      text: draft.heightCm?.toStringAsFixed(0) ?? '',
    );
    _weightController = TextEditingController(
      text: draft.weightKg?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(
      onboardingControllerProvider.select((s) => s.draft),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AscendSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This helps personalize your calculations. It is never used as the sole factor in '
            'your workout recommendations, and you can choose "Prefer not to say."',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AscendSpacing.lg),
          Text(
            'Sex used for calculations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AscendSpacing.sm),
          SegmentedButton<SexForCalculations>(
            segments: const [
              ButtonSegment(
                value: SexForCalculations.female,
                label: Text('Female'),
              ),
              ButtonSegment(
                value: SexForCalculations.male,
                label: Text('Male'),
              ),
              ButtonSegment(
                value: SexForCalculations.unspecified,
                label: Text('Prefer not to say'),
              ),
            ],
            selected: {
              draft.sexForCalculations ?? SexForCalculations.unspecified,
            },
            onSelectionChanged: (selection) => ref
                .read(onboardingControllerProvider.notifier)
                .updateDraft(
                  (d) => d.copyWith(sexForCalculations: selection.first),
                ),
          ),
          const SizedBox(height: AscendSpacing.lg),
          AscendTextField(
            label: 'Height (cm)',
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            onChanged: (value) => ref
                .read(onboardingControllerProvider.notifier)
                .updateDraft(
                  (d) => d.copyWith(heightCm: double.tryParse(value)),
                ),
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            label: 'Weight (kg)',
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => ref
                .read(onboardingControllerProvider.notifier)
                .updateDraft(
                  (d) => d.copyWith(weightKg: double.tryParse(value)),
                ),
          ),
        ],
      ),
    );
  }
}
