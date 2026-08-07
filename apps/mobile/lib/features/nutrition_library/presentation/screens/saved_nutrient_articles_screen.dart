import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../providers/nutrition_library_controller.dart';

/// Articles the caller has bookmarked from the Nutrition Library —
/// Build Session 8 Part 11.
class SavedNutrientArticlesScreen extends ConsumerWidget {
  const SavedNutrientArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedNutrientArticlesControllerProvider);
    final controller = ref.read(
      savedNutrientArticlesControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Articles')),
      body: SafeArea(
        child: state.when(
          loading: () => const AscendLoadingIndicator(),
          error: (error, _) => AscendEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load saved articles',
            message: error.toString(),
            actionLabel: 'Retry',
            onAction: controller.load,
          ),
          data: (articles) => articles.isEmpty
              ? const AscendEmptyState(
                  icon: Icons.bookmark_border,
                  title: 'No saved articles yet',
                  message:
                      'Tap the bookmark icon on any Nutrition Library article to save it here.',
                )
              : RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AscendSpacing.md),
                    itemCount: articles.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AscendSpacing.sm),
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return AscendCard(
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
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
