import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/support_ticket.dart';
import '../providers/support_controller.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SupportCategory _category = SupportCategory.general;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final ticket = await ref
          .read(supportRepositoryProvider)
          .create(
            category: _category,
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
          );
      ref.invalidate(supportControllerProvider);
      if (!mounted) return;
      context.pushReplacement(RoutePaths.supportTicketDetailPath(ticket.id));
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
      appBar: AppBar(title: const Text('New support ticket')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<SupportCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final category in SupportCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(supportCategoryLabel(category)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  controller: _subjectController,
                  label: 'Subject',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a subject'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  controller: _messageController,
                  label: 'Message',
                  maxLines: 6,
                  maxLength: 5000,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a message'
                      : null,
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
                  label: 'Submit',
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
