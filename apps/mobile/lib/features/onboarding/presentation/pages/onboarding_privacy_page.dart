import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class OnboardingPrivacyPage extends StatelessWidget {
  const OnboardingPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AscendSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your privacy, by default',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AscendSpacing.md),
          const _PrivacyPoint(
            icon: Icons.lock_outline,
            text:
                'Your profile is private by default. Nothing is shared publicly unless you choose to.',
          ),
          const _PrivacyPoint(
            icon: Icons.location_off_outlined,
            text: 'Location is never shared publicly by default.',
          ),
          const _PrivacyPoint(
            icon: Icons.medical_services_outlined,
            text:
                'Ascend does not diagnose medical conditions. Camera-based estimates, where '
                'available in the future, are not clinically accurate.',
          ),
          const _PrivacyPoint(
            icon: Icons.watch_outlined,
            text:
                'Wearable and camera access always require your explicit consent, and you can '
                'revoke it at any time from Profile.',
          ),
          const _PrivacyPoint(
            icon: Icons.sentiment_satisfied_outlined,
            text:
                'No shaming language, and no exercise recommendations based solely on sex — we '
                'consider your goals, ability, equipment, and preferences together.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AscendSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
