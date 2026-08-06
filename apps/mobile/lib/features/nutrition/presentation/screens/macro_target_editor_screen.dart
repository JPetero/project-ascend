import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/validation/form_validators.dart';
import '../../data/macro_target_repository.dart';
import '../../domain/macro_target.dart';
import '../providers/macro_target_controller.dart';

/// Lets a user override the safe-default macro estimate with their own
/// targets. Values are always bounded server-side (see
/// services/api/src/modules/macro-targets/dto/upsert-macro-target.dto.ts)
/// so a typo can't produce a dangerously low target — this screen is not a
/// substitute for guidance from a qualified professional, and says so.
class MacroTargetEditorScreen extends ConsumerStatefulWidget {
  const MacroTargetEditorScreen({super.key});

  @override
  ConsumerState<MacroTargetEditorScreen> createState() =>
      _MacroTargetEditorScreenState();
}

class _MacroTargetEditorScreenState
    extends ConsumerState<MacroTargetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();
  bool _isSaving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _fiber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(macroTargetProvider.notifier)
          .upsert(
            MacroTargetInput(
              calorieTarget: int.parse(_calories.text),
              proteinGramsTarget: int.parse(_protein.text),
              carbGramsTarget: int.parse(_carbs.text),
              fatGramsTarget: int.parse(_fat.text),
              fiberGramsTarget: _fiber.text.trim().isEmpty
                  ? null
                  : int.parse(_fiber.text),
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save your targets. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetAsync = ref.watch(macroTargetProvider);

    ref.listen(macroTargetProvider, (previous, next) {
      final target = next.valueOrNull;
      if (target == null || _prefilled) return;
      _prefilled = true;
      _calories.text = target.calorieTarget.toString();
      _protein.text = target.proteinGramsTarget.toString();
      _carbs.text = target.carbGramsTarget.toString();
      _fat.text = target.fatGramsTarget.toString();
      _fiber.text = target.fiberGramsTarget?.toString() ?? '';
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Daily macro targets')),
      body: SafeArea(
        child: targetAsync.when(
          data: (target) => _buildForm(context, target),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AscendSpacing.xxl),
            child: AscendLoadingIndicator(label: 'Loading your targets'),
          ),
          error: (error, stackTrace) => AscendEmptyState(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load your targets",
            message: 'Try again in a moment.',
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, MacroTarget target) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AscendSpacing.md),
        children: [
          if (target.isEstimatedDefault)
            Padding(
              padding: const EdgeInsets.only(bottom: AscendSpacing.sm),
              child: Text(
                'These are a general starting estimate based on your '
                'profile — not personalized or medical advice.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Text(target.disclaimer, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _calories,
            label: 'Calories',
            keyboardType: TextInputType.number,
            validator: requiredInt,
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _protein,
            label: 'Protein (g)',
            keyboardType: TextInputType.number,
            validator: requiredInt,
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _carbs,
            label: 'Carbs (g)',
            keyboardType: TextInputType.number,
            validator: requiredInt,
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _fat,
            label: 'Fat (g)',
            keyboardType: TextInputType.number,
            validator: requiredInt,
          ),
          const SizedBox(height: AscendSpacing.md),
          AscendTextField(
            controller: _fiber,
            label: 'Fiber (g) — optional',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AscendSpacing.lg),
          AscendPrimaryButton(
            label: 'Save targets',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}
