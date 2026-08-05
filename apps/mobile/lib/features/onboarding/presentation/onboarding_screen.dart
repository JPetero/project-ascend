import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/onboarding_draft.dart';
import 'pages/onboarding_body_measurements_page.dart';
import 'pages/onboarding_companion_page.dart';
import 'pages/onboarding_completion_page.dart';
import 'pages/onboarding_experience_equipment_page.dart';
import 'pages/onboarding_goal_page.dart';
import 'pages/onboarding_personal_details_page.dart';
import 'pages/onboarding_privacy_page.dart';
import 'pages/onboarding_schedule_page.dart';
import 'pages/onboarding_wearables_page.dart';
import 'providers/onboarding_controller.dart';

const _pageTitles = {
  OnboardingPage.companion: 'Choose your companion',
  OnboardingPage.personalDetails: 'Tell us about yourself',
  OnboardingPage.bodyMeasurements: 'Sex & measurements',
  OnboardingPage.goal: 'Your primary goal',
  OnboardingPage.experienceAndEquipment: 'Experience & equipment',
  OnboardingPage.schedule: 'Your schedule',
  OnboardingPage.wearables: 'Connect wearables',
  OnboardingPage.privacySummary: 'Privacy summary',
  OnboardingPage.completion: "You're all set",
};

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Widget _pageFor(OnboardingPage page) {
    switch (page) {
      case OnboardingPage.companion:
        return const OnboardingCompanionPage();
      case OnboardingPage.personalDetails:
        return const OnboardingPersonalDetailsPage();
      case OnboardingPage.bodyMeasurements:
        return const OnboardingBodyMeasurementsPage();
      case OnboardingPage.goal:
        return const OnboardingGoalPage();
      case OnboardingPage.experienceAndEquipment:
        return const OnboardingExperienceEquipmentPage();
      case OnboardingPage.schedule:
        return const OnboardingSchedulePage();
      case OnboardingPage.wearables:
        return const OnboardingWearablesPage();
      case OnboardingPage.privacySummary:
        return const OnboardingPrivacyPage();
      case OnboardingPage.completion:
        return const OnboardingCompletionPage();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final totalPages = OnboardingPage.values.length;
    final isFirstPage = onboardingState.page == OnboardingPage.companion;
    final isLastPage = onboardingState.page == OnboardingPage.completion;

    return Scaffold(
      appBar: AppBar(
        leading: isFirstPage
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(onboardingControllerProvider.notifier).goBack(),
              ),
        title: Text(_pageTitles[onboardingState.page] ?? ''),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AscendSpacing.md),
              child: ClipRRect(
                borderRadius: AscendRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: (onboardingState.pageIndex + 1) / totalPages,
                  minHeight: 6,
                  semanticsLabel:
                      'Step ${onboardingState.pageIndex + 1} of $totalPages',
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(onboardingState.page),
                  child: _pageFor(onboardingState.page),
                ),
              ),
            ),
            if (onboardingState.syncError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AscendSpacing.md,
                  AscendSpacing.sm,
                  AscendSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: AscendSpacing.sm),
                    Expanded(
                      child: Text(
                        onboardingState.syncError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AscendSpacing.md),
              child: AscendPrimaryButton(
                label: isLastPage ? 'Enter Ascend' : 'Next',
                isLoading: onboardingState.isSubmitting,
                onPressed: () =>
                    ref.read(onboardingControllerProvider.notifier).goNext(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
