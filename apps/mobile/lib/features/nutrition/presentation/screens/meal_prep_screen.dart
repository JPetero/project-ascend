import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/meal_entry.dart';
import '../../domain/meal_type.dart';
import '../../domain/nutrition_dashboard_summary.dart';
import '../providers/meal_entry_controller.dart';
import '../providers/nutrition_summary_controller.dart';
import '../providers/water_controller.dart';

/// The Meal Prep tab — today's macro summary, per-meal food logging, and a
/// water tracker, all backed by the real nutrition-log/foods/water
/// endpoints (see services/api/src/modules/{foods,nutrition-log,water}).
/// Saved meals and AI-generated meal plans are deliberately out of scope
/// this session — see packages/docs/product/parking-lot.md — and say so
/// honestly rather than showing placeholder content as if it were real.
class MealPrepScreen extends ConsumerWidget {
  const MealPrepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(nutritionDashboardSummaryProvider);
    final entriesAsync = ref.watch(todaysMealEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Prep'),
        actions: const [ProfileIconAction()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(nutritionDashboardSummaryProvider.future),
            ref.refresh(todaysMealEntriesProvider.future),
            ref.refresh(todaysWaterProvider.future),
          ]),
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
              const AscendSectionHeader(title: 'Water'),
              const SizedBox(height: AscendSpacing.sm),
              const _WaterTracker(),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Meals'),
              const SizedBox(height: AscendSpacing.sm),
              entriesAsync.when(
                data: (entries) => _MealSections(entries: entries),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AscendSpacing.xxl),
                  child: AscendLoadingIndicator(label: 'Loading your meals'),
                ),
                error: (error, stackTrace) => AscendEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: "Couldn't load today's meals",
                  message: 'Pull to refresh to try again.',
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Saved meals'),
              const SizedBox(height: AscendSpacing.sm),
              const AscendEmptyState(
                icon: Icons.bookmark_outline,
                title: 'Saved meals are coming soon',
                message: 'Save a meal to reuse it here in a future release.',
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
    return AscendCard(
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
          AscendProgressRing(
            progress: nutrition.proteinGrams / nutrition.proteinTargetGrams,
            label: 'protein',
            size: 64,
          ),
        ],
      ),
    );
  }
}

class _WaterTracker extends ConsumerWidget {
  const _WaterTracker();

  Future<void> _addWater(
    WidgetRef ref,
    BuildContext context,
    int amountMl,
  ) async {
    try {
      await ref
          .read(waterRepositoryProvider)
          .addEntry(date: DateTime.now(), amountMl: amountMl);
      ref.invalidate(todaysWaterProvider);
      ref.invalidate(nutritionDashboardSummaryProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't log water. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(todaysWaterProvider);

    return AscendCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: Theme.of(context).textTheme.labelMedium),
                waterAsync.when(
                  data: (water) => Text(
                    '${(water.totalMl / 1000).toStringAsFixed(2)} L',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  loading: () => const Text('—'),
                  error: (error, stackTrace) => const Text('—'),
                ),
              ],
            ),
          ),
          AscendSecondaryButton(
            label: '+250ml',
            expand: false,
            onPressed: () => _addWater(ref, context, 250),
          ),
          const SizedBox(width: AscendSpacing.sm),
          AscendSecondaryButton(
            label: '+500ml',
            expand: false,
            onPressed: () => _addWater(ref, context, 500),
          ),
        ],
      ),
    );
  }
}

class _MealSections extends ConsumerWidget {
  const _MealSections({required this.entries});

  final List<MealEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final mealType in MealType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AscendSpacing.md),
            child: _MealSection(
              mealType: mealType,
              entries: entries.where((e) => e.mealType == mealType).toList(),
            ),
          ),
      ],
    );
  }
}

class _MealSection extends ConsumerWidget {
  const _MealSection({required this.mealType, required this.entries});

  final MealType mealType;
  final List<MealEntry> entries;

  Future<void> _delete(
    WidgetRef ref,
    BuildContext context,
    MealEntry entry,
  ) async {
    try {
      await ref.read(mealEntryRepositoryProvider).deleteEntry(entry.id);
      ref.invalidate(todaysMealEntriesProvider);
      ref.invalidate(nutritionDashboardSummaryProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't remove that entry. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCalories = entries.fold<double>(0, (sum, e) => sum + e.calories);

    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mealTypeLabel(mealType),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (entries.isNotEmpty)
                Text(
                  '${totalCalories.round()} kcal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add to ${mealTypeLabel(mealType)}',
                onPressed: () =>
                    context.push(RoutePaths.foodSearch, extra: mealType),
              ),
            ],
          ),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.food.name} · ${entry.calories.round()} kcal',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove',
                    onPressed: () => _delete(ref, context, entry),
                  ),
                ],
              ),
            ),
          if (entries.isEmpty)
            Text(
              'Nothing logged yet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
