import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../providers/challenges_controller.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTimeRange? _range;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_range == null) {
      setState(() => _error = 'Choose a start and end date.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(challengesRepositoryProvider)
          .create(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            startsAt: _range!.start,
            endsAt: _range!.end.add(const Duration(days: 1)),
          );
      ref.invalidate(challengesControllerProvider);
      if (!mounted) return;
      context.pushReplacement(RoutePaths.challengeDetailPath(challenge.id));
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
      appBar: AppBar(title: const Text('New challenge')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AscendTextField(
                  controller: _titleController,
                  label: 'Challenge title',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a title'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  controller: _descriptionController,
                  label: 'Description — optional',
                  maxLines: 3,
                  maxLength: 280,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendCard(
                  onTap: _pickRange,
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_outlined),
                      const SizedBox(width: AscendSpacing.sm),
                      Expanded(
                        child: Text(
                          _range == null
                              ? 'Choose a start and end date'
                              : '${_formatDate(_range!.start)} – ${_formatDate(_range!.end)}',
                        ),
                      ),
                    ],
                  ),
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
                  label: 'Create challenge',
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

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
