import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';
import '../../domain/nutrition_dashboard_summary.dart';
import '../providers/nutrition_summary_controller.dart';

/// The Meal Prep tab — today's macro/hydration summary backed by real
/// nutrition data (see NutritionSummaryRepository). Food search, meal entry
/// logging, and custom foods use the same backend endpoints
/// (services/api/src/modules/foods, nutrition-log, water) but their
/// dedicated screens ship in the Nutrition Tracking foundation milestone —
/// see packages/docs/product/parking-lot.md. Nothing on this screen is
/// simulated in the meantime; sections not yet wired say so honestly.
class MealPrepScreen extends ConsumerWidget {
  const MealPrepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(nutritionDashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Prep'),
        actions: const [ProfileIconAction()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.refresh(nutritionDashboardSummaryProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              const AscendSectionHeader(title: "Today's macros"),
              const SizedBox(height: AscendSpacing.sm),
              nutritionAsync.when(
                data: (nutrition) => _TodaySummary(nutrition: nutrition),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AscendSpacing.xxl),
                  child: AscendLoadingIndicator(
                    label: 'Loading your nutrition',
                  ),
                ),
                error: (error, stackTrace) => AscendEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: "Couldn't load your nutrition",
                  message: 'Pull to refresh to try again.',
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Meals'),
              const SizedBox(height: AscendSpacing.sm),
              const AscendEmptyState(
                icon: Icons.restaurant_menu_outlined,
                title: 'Meal logging is on its way',
                message:
                    'Food search, custom foods, and per-meal logging arrive '
                    'in the next update. Nothing here is simulated in the '
                    'meantime.',
              ),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Saved meals'),
              const SizedBox(height: AscendSpacing.sm),
              const AscendEmptyState(
                icon: Icons.bookmark_outline,
                title: 'Saved meals are coming soon',
                message: 'Save a meal once logging ships to reuse it here.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.nutrition});

  final NutritionDashboardSummary nutrition;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AscendCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calories',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      '${nutrition.calories.round()} / ${nutrition.calorieTarget}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AscendSpacing.md),
        Row(
          children: [
            Expanded(
              child: AscendCard(
                child: Column(
                  children: [
                    Text(
                      'Protein',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    AscendProgressRing(
                      progress:
                          nutrition.proteinGrams / nutrition.proteinTargetGrams,
                      label: '${nutrition.proteinGrams.round()}g',
                      size: 72,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AscendSpacing.md),
            Expanded(
              child: AscendCard(
                child: Column(
                  children: [
                    Text(
                      'Water',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    AscendProgressRing(
                      progress:
                          nutrition.hydrationMl / nutrition.hydrationTargetMl,
                      label:
                          '${(nutrition.hydrationMl / 1000).toStringAsFixed(1)}L',
                      color: AscendColors.primaryCyan,
                      size: 72,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
