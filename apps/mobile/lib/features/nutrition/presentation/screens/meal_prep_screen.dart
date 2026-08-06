import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/app_shell.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/sync/sync_status_indicator.dart';
import '../../domain/meal_entry.dart';
import '../../domain/meal_type.dart';
import '../../domain/nutrition_dashboard_summary.dart';
import '../../domain/saved_meal.dart';
import '../providers/meal_entry_controller.dart';
import '../providers/nutrition_summary_controller.dart';
import '../providers/saved_meal_controller.dart';
import '../providers/water_controller.dart';

/// The Meal Prep tab — today's macro summary, per-meal food logging, a
/// water tracker, and saved meals, all backed by real nutrition-log/foods/
/// water/saved-meals endpoints (see
/// services/api/src/modules/{foods,nutrition-log,water,saved-meals}).
/// AI-generated meal plans are deliberately out of scope this session —
/// see packages/docs/product/parking-lot.md.
class MealPrepScreen extends ConsumerWidget {
  const MealPrepScreen({super.key});

  Future<void> _copyFromYesterday(WidgetRef ref, BuildContext context) async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    try {
      final result = await ref
          .read(todaysMealEntriesProvider.notifier)
          .copyEntries(sourceDate: yesterday, targetDate: today);
      ref.invalidate(nutritionDashboardSummaryProvider);
      if (!context.mounted) return;
      final String message;
      if (!result.synced) {
        message =
            "You're offline — copying yesterday's meals once you're back online.";
      } else if (result.copiedCount == 0) {
        message = 'No meals logged yesterday to copy.';
      } else {
        message =
            'Copied ${result.copiedCount} '
            '${result.copiedCount == 1 ? 'entry' : 'entries'} from yesterday.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't copy yesterday's meals.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(nutritionDashboardSummaryProvider);
    final entriesAsync = ref.watch(todaysMealEntriesProvider);
    final savedMealsAsync = ref.watch(savedMealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Prep'),
        actions: [
          IconButton(
            icon: const Icon(Icons.military_tech_outlined),
            tooltip: 'Achievements',
            onPressed: () => context.push(RoutePaths.achievements),
          ),
          const ProfileIconAction(),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(nutritionDashboardSummaryProvider.future),
            ref.read(todaysMealEntriesProvider.notifier).refresh(),
            ref.read(todaysWaterProvider.notifier).refresh(),
            ref.read(savedMealsProvider.notifier).refresh(),
          ]),
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              const SyncStatusIndicator(),
              AscendSectionHeader(
                title: "Today's macros",
                actionLabel: 'Edit targets',
                onAction: () async {
                  final saved = await context.push<bool>(
                    RoutePaths.macroTargetEditor,
                  );
                  if (saved ?? false) {
                    ref.invalidate(nutritionDashboardSummaryProvider);
                  }
                },
              ),
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
              AscendSectionHeader(
                title: 'Meals',
                actionLabel: 'Copy yesterday',
                onAction: () => _copyFromYesterday(ref, context),
              ),
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
              savedMealsAsync.when(
                data: (savedMeals) =>
                    _SavedMealsSection(savedMeals: savedMeals),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AscendSpacing.lg),
                  child: AscendLoadingIndicator(label: 'Loading saved meals'),
                ),
                error: (error, stackTrace) => AscendEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: "Couldn't load saved meals",
                  message: 'Pull to refresh to try again.',
                ),
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
      await ref.read(todaysWaterProvider.notifier).addEntry(amountMl);
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
      await ref.read(todaysMealEntriesProvider.notifier).deleteEntry(entry.id);
      ref.invalidate(nutritionDashboardSummaryProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't remove that entry. Try again.")),
      );
    }
  }

  Future<void> _saveAsMeal(WidgetRef ref, BuildContext context) async {
    final controller = TextEditingController(text: mealTypeLabel(mealType));
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as a saved meal'),
        content: AscendTextField(controller: controller, label: 'Name'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      await ref
          .read(savedMealsProvider.notifier)
          .create(
            name: name,
            items: entries
                .map(
                  (e) => SavedMealItemDraft(
                    foodId: e.food.id,
                    foodName: e.food.name,
                    foodBrand: e.food.brand,
                    foodIsEstimated: e.food.isEstimated,
                    foodServingId: e.foodServing?.id,
                    foodServingLabel: e.foodServing?.label,
                    quantity: e.quantity,
                  ),
                )
                .toList(),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved "$name".')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save that meal. Try again.")),
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
              if (entries.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: 'Save as a saved meal',
                  onPressed: () => _saveAsMeal(ref, context),
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

class _SavedMealsSection extends ConsumerWidget {
  const _SavedMealsSection({required this.savedMeals});

  final List<SavedMeal> savedMeals;

  Future<void> _delete(
    WidgetRef ref,
    BuildContext context,
    SavedMeal meal,
  ) async {
    try {
      await ref.read(savedMealsProvider.notifier).delete(meal.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't remove that saved meal.")),
      );
    }
  }

  Future<void> _log(WidgetRef ref, BuildContext context, SavedMeal meal) async {
    final mealType = await showAscendBottomSheet<MealType>(
      context: context,
      title: 'Log "${meal.name}" to',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in MealType.values)
            ListTile(
              title: Text(mealTypeLabel(type)),
              onTap: () => Navigator.of(context).pop(type),
            ),
        ],
      ),
    );
    if (mealType == null) return;

    try {
      await ref
          .read(savedMealsProvider.notifier)
          .logMeal(id: meal.id, mealType: mealType, date: DateTime.now());
      ref.invalidate(nutritionDashboardSummaryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logging "${meal.name}" to ${mealTypeLabel(mealType)} — it will '
            'appear once synced.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't log that meal. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (savedMeals.isEmpty) {
      return const AscendEmptyState(
        icon: Icons.bookmark_outline,
        title: 'No saved meals yet',
        message:
            'Use the bookmark icon on a logged meal above to save it for reuse.',
      );
    }

    return Column(
      children: [
        for (final meal in savedMeals)
          Padding(
            padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
            child: AscendCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${meal.items.length} ${meal.items.length == 1 ? 'item' : 'items'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AscendGhostButton(
                    label: 'Log',
                    onPressed: () => _log(ref, context, meal),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete saved meal',
                    onPressed: () => _delete(ref, context, meal),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
