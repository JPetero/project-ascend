import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/food_repository.dart';
import '../providers/food_controller.dart';

/// Creates a user-owned custom food — values are the user's own estimate,
/// never presented as lab-verified. See
/// packages/docs/product/wellness-ethics-bible.md.
class CustomFoodEditorScreen extends ConsumerStatefulWidget {
  const CustomFoodEditorScreen({super.key});

  @override
  ConsumerState<CustomFoodEditorScreen> createState() =>
      _CustomFoodEditorScreenState();
}

class _CustomFoodEditorScreenState
    extends ConsumerState<CustomFoodEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _servingDescription = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _name.dispose();
    _servingDescription.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (double.tryParse(value) == null) return 'Enter a number';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final created = await ref
          .read(foodRepositoryProvider)
          .createCustom(
            CustomFoodInput(
              name: _name.text.trim(),
              servingDescription: _servingDescription.text.trim(),
              caloriesPerServing: double.parse(_calories.text),
              proteinGramsPerServing: double.parse(_protein.text),
              carbGramsPerServing: double.parse(_carbs.text),
              fatGramsPerServing: double.parse(_fat.text),
            ),
          );
      if (mounted) Navigator.of(context).pop(created);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save that food. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a custom food')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              Text(
                'Enter your own estimate — this is not verified against a '
                'lab-tested database.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _name,
                label: 'Food name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _servingDescription,
                label: 'Serving size (e.g. "1 cup cooked")',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _calories,
                label: 'Calories per serving',
                keyboardType: TextInputType.number,
                validator: _requiredNumber,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _protein,
                label: 'Protein (g) per serving',
                keyboardType: TextInputType.number,
                validator: _requiredNumber,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _carbs,
                label: 'Carbs (g) per serving',
                keyboardType: TextInputType.number,
                validator: _requiredNumber,
              ),
              const SizedBox(height: AscendSpacing.md),
              AscendTextField(
                controller: _fat,
                label: 'Fat (g) per serving',
                keyboardType: TextInputType.number,
                validator: _requiredNumber,
              ),
              const SizedBox(height: AscendSpacing.lg),
              AscendPrimaryButton(
                label: 'Save food',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
