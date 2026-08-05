import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../profile/domain/profile_model.dart';
import '../providers/onboarding_controller.dart';

class OnboardingPersonalDetailsPage extends ConsumerStatefulWidget {
  const OnboardingPersonalDetailsPage({super.key});

  @override
  ConsumerState<OnboardingPersonalDetailsPage> createState() =>
      _OnboardingPersonalDetailsPageState();
}

class _OnboardingPersonalDetailsPageState
    extends ConsumerState<OnboardingPersonalDetailsPage> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _countryController;
  late final TextEditingController _languageController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).draft;
    _firstNameController = TextEditingController(text: draft.firstName ?? '');
    _countryController = TextEditingController(text: draft.countryCode ?? '');
    _languageController = TextEditingController(
      text: draft.languageCode ?? 'en',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _countryController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final draft = ref.read(onboardingControllerProvider).draft;
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13),
    );
    if (picked != null) {
      ref
          .read(onboardingControllerProvider.notifier)
          .updateDraft((d) => d.copyWith(dateOfBirth: picked));
    }
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
          AscendTextField(
            label: 'First name',
            controller: _firstNameController,
            onChanged: (value) => ref
                .read(onboardingControllerProvider.notifier)
                .updateDraft((d) => d.copyWith(firstName: value)),
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendCard(
            onTap: _pickDateOfBirth,
            semanticLabel: 'Date of birth',
            child: Row(
              children: [
                const Icon(Icons.cake_outlined),
                const SizedBox(width: AscendSpacing.sm),
                Text(
                  draft.dateOfBirth == null
                      ? 'Select date of birth'
                      : '${draft.dateOfBirth!.year}-${draft.dateOfBirth!.month.toString().padLeft(2, '0')}-${draft.dateOfBirth!.day.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            label: 'Country code (e.g. US)',
            controller: _countryController,
            onChanged: (value) => ref
                .read(onboardingControllerProvider.notifier)
                .updateDraft(
                  (d) => d.copyWith(countryCode: value.toUpperCase()),
                ),
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            label: 'Language code (e.g. en)',
            controller: _languageController,
            onChanged: (value) => ref
                .read(onboardingControllerProvider.notifier)
                .updateDraft((d) => d.copyWith(languageCode: value)),
          ),
          const SizedBox(height: AscendSpacing.md),
          Row(
            children: [
              const Expanded(child: Text('Units')),
              SegmentedButton<UnitSystem>(
                segments: const [
                  ButtonSegment(
                    value: UnitSystem.metric,
                    label: Text('Metric'),
                  ),
                  ButtonSegment(
                    value: UnitSystem.imperial,
                    label: Text('Imperial'),
                  ),
                ],
                selected: {draft.unitSystem ?? UnitSystem.metric},
                onSelectionChanged: (selection) => ref
                    .read(onboardingControllerProvider.notifier)
                    .updateDraft(
                      (d) => d.copyWith(unitSystem: selection.first),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
