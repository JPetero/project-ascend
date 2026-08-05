import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../companion/presentation/widgets/companion_avatar.dart';
import '../../../profile/domain/preferences_model.dart';
import '../providers/onboarding_controller.dart';

class OnboardingCompanionPage extends ConsumerWidget {
  const OnboardingCompanionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.draft.companion),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AscendSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Atlas and Nova offer the same guidance and support — pick whichever presentation '
            'feels right for you. Your workouts are always based on your goals and profile, not '
            'who you choose here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AscendSpacing.lg),
          _CompanionOption(
            companion: Companion.atlas,
            title: 'Atlas',
            description: 'Calm, confident, and direct.',
            isSelected: selected == Companion.atlas,
            onTap: () => ref
                .read(onboardingControllerProvider.notifier)
                .setCompanion(Companion.atlas),
          ),
          const SizedBox(height: AscendSpacing.md),
          _CompanionOption(
            companion: Companion.nova,
            title: 'Nova',
            description: 'Warm, reflective, and reassuring.',
            isSelected: selected == Companion.nova,
            onTap: () => ref
                .read(onboardingControllerProvider.notifier)
                .setCompanion(Companion.nova),
          ),
        ],
      ),
    );
  }
}

class _CompanionOption extends StatelessWidget {
  const _CompanionOption({
    required this.companion,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final Companion companion;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title, $description',
      child: InkWell(
        onTap: onTap,
        borderRadius: AscendRadius.largeRadius,
        child: Container(
          padding: const EdgeInsets.all(AscendSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AscendRadius.largeRadius,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CompanionAvatar(companion: companion, size: 64),
              const SizedBox(width: AscendSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
