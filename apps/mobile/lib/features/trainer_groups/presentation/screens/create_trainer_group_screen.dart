import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../providers/trainer_groups_controller.dart';

class CreateTrainerGroupScreen extends ConsumerStatefulWidget {
  const CreateTrainerGroupScreen({super.key});

  @override
  ConsumerState<CreateTrainerGroupScreen> createState() =>
      _CreateTrainerGroupScreenState();
}

class _CreateTrainerGroupScreenState
    extends ConsumerState<CreateTrainerGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final group = await ref
          .read(trainerGroupsRepositoryProvider)
          .createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
      ref.invalidate(trainerGroupsControllerProvider);
      if (!mounted) return;
      context.pushReplacement(RoutePaths.trainerGroupDetailPath(group.id));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AscendTextField(
                  controller: _nameController,
                  label: 'Group name',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a group name'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  controller: _descriptionController,
                  label: 'Description — optional',
                  maxLines: 3,
                  maxLength: 280,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AscendSpacing.sm),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AscendSpacing.lg),
                AscendPrimaryButton(
                  label: 'Create group',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
