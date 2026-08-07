import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../providers/nutrition_library_controller.dart';

/// The free Ascend Nutrition Library home — Build Session 8 Part 11.
/// Reachable from the Meal Prep tab. General education only; see
/// [NutrientArticle.safetyNote] shown on every article.
class NutritionLibraryScreen extends ConsumerWidget {
  const NutritionLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(nutrientCategoriesControllerProvider);
    final controller = ref.read(nutrientCategoriesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Saved articles',
            onPressed: () => context.push(RoutePaths.savedNutrientArticles),
          ),
        ],
      ),
      body: SafeArea(
        child: categoriesState.when(
          loading: () => const AscendLoadingIndicator(),
          error: (error, _) => AscendEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load the library',
            message: error.toString(),
            actionLabel: 'Retry',
            onAction: controller.load,
          ),
          data: (categories) => RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.all(AscendSpacing.md),
              children: [
                for (final category in categories) ...[
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    category.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AscendSpacing.sm),
                  for (final article in category.articles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
                      child: AscendCard(
                        onTap: () => context.push(
                          RoutePaths.nutrientArticleDetailPath(article.slug),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              article.summary,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AscendSpacing.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
