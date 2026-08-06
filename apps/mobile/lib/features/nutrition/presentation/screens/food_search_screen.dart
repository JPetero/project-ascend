import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/food.dart';
import '../../domain/meal_type.dart';
import '../providers/food_controller.dart';
import '../providers/meal_entry_controller.dart';

/// Search the shared food catalog and the user's own custom foods, then
/// log a serving against [mealType] for today. Custom-food creation is a
/// pushed sub-route reached from here (see [RoutePaths.customFoodEditorNew]).
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key, required this.mealType});

  final MealType mealType;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();
  List<Food>? _results;
  bool _isSearching = false;
  Object? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(foodRepositoryProvider)
          .search(search: query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isSearching = false;
      });
    }
  }

  Future<void> _openLogSheet(Food food) async {
    final logged = await showAscendBottomSheet<bool>(
      context: context,
      title: food.name,
      child: _LogFoodSheet(food: food, mealType: widget.mealType),
    );
    if (logged == true) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _createCustomFood() async {
    final created = await context.push<Food>(RoutePaths.customFoodEditorNew);
    if (created != null) {
      await _openLogSheet(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add to ${mealTypeLabel(widget.mealType)}')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AscendSpacing.md),
              child: AscendTextField(
                controller: _searchController,
                label: 'Search foods (e.g. cooked white rice)',
                onChanged: _onQueryChanged,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_searchController.text),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const AscendLoadingIndicator(label: 'Searching');
    }
    if (_error != null) {
      return AscendEmptyState(
        icon: Icons.cloud_off_outlined,
        title: "Couldn't search foods",
        message: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => _search(_searchController.text),
      );
    }
    final results = _results ?? const [];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AscendSpacing.md),
      children: [
        if (results.isEmpty)
          const AscendEmptyState(
            icon: Icons.search_off_outlined,
            title: 'No foods found',
            message: 'Try a different search, or add your own food.',
          ),
        for (final food in results)
          Padding(
            padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
            child: AscendCard(
              onTap: () => _openLogSheet(food),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${food.servingDescription} · ${food.caloriesPerServing.round()} kcal'
                          '${food.isEstimated ? ' · estimated' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_circle_outline),
                ],
              ),
            ),
          ),
        AscendGhostButton(
          label: 'Create a custom food',
          icon: Icons.add,
          onPressed: _createCustomFood,
        ),
        const SizedBox(height: AscendSpacing.lg),
      ],
    );
  }
}

class _LogFoodSheet extends ConsumerStatefulWidget {
  const _LogFoodSheet({required this.food, required this.mealType});

  final Food food;
  final MealType mealType;

  @override
  ConsumerState<_LogFoodSheet> createState() => _LogFoodSheetState();
}

class _LogFoodSheetState extends ConsumerState<_LogFoodSheet> {
  double _quantity = 1;
  bool _isSaving = false;

  Future<void> _logIt() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(todaysMealEntriesProvider.notifier)
          .addEntry(
            food: widget.food,
            mealType: widget.mealType,
            quantity: _quantity,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't log that food. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final calories = (food.caloriesPerServing * _quantity).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${food.servingDescription} per serving'),
        const SizedBox(height: AscendSpacing.md),
        Row(
          children: [
            const Text('Servings'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _quantity > 0.5
                  ? () => setState(() => _quantity -= 0.5)
                  : null,
            ),
            Text(_quantity.toStringAsFixed(1)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _quantity += 0.5),
            ),
          ],
        ),
        Text(
          '$calories kcal total',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AscendSpacing.md),
        AscendPrimaryButton(
          label: 'Log it',
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _logIt,
        ),
      ],
    );
  }
}
