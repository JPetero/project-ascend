import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/nutrition_library_controller.dart';

/// A single Nutrition Library article — Build Session 8 Part 11. The
/// safety note is always shown, never collapsed or hidden behind a
/// tap: this is general education, not medical advice.
class NutrientArticleScreen extends ConsumerWidget {
  const NutrientArticleScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(nutrientArticleProvider(slug));
    final savedState = ref.watch(savedNutrientArticlesControllerProvider);
    final savedController = ref.read(
      savedNutrientArticlesControllerProvider.notifier,
    );
    final isSaved = savedController.isSaved(slug);

    return Scaffold(
      appBar: AppBar(
        title: Text(articleAsync.asData?.value.title ?? 'Article'),
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            tooltip: isSaved ? 'Unsave' : 'Save',
            onPressed: savedState.isLoading
                ? null
                : () => savedController.toggle(slug),
          ),
        ],
      ),
      body: SafeArea(
        child: articleAsync.when(
          loading: () => const AscendLoadingIndicator(),
          error: (error, _) => AscendEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load this article',
            message: error.toString(),
          ),
          data: (article) => ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              Text(
                article.summary,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AscendSpacing.md),
              Text(article.body),
              if (article.foodSources.isNotEmpty) ...[
                const SizedBox(height: AscendSpacing.lg),
                Text(
                  'Food sources',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AscendSpacing.sm),
                for (final source in article.foodSources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AscendSpacing.xs),
                    child: Text('${source.foodName} — ${source.amount}'),
                  ),
              ],
              if (article.references.isNotEmpty) ...[
                const SizedBox(height: AscendSpacing.lg),
                Text('Sources', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AscendSpacing.sm),
                for (final reference in article.references)
                  Text(
                    reference.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
              const SizedBox(height: AscendSpacing.lg),
              AscendCard(
                child: Text(
                  article.safetyNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
