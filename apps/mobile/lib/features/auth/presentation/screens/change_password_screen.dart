import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/auth_controller.dart';

/// Build Session 9 Part 4 — the authenticated counterpart to the
/// email-link reset flow, reached from the dashboard's Account section.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmNewPassword: _confirmPasswordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password changed.')));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      authControllerProvider.select((s) => s.isSubmitting),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AscendTextField(
                  label: 'Current password',
                  controller: _currentPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter your current password.'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  label: 'New password',
                  controller: _newPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Use at least 8 characters.';
                    }
                    final hasUpper = value.contains(RegExp(r'[A-Z]'));
                    final hasLower = value.contains(RegExp(r'[a-z]'));
                    final hasDigit = value.contains(RegExp(r'[0-9]'));
                    if (!hasUpper || !hasLower || !hasDigit) {
                      return 'Include an uppercase letter, lowercase letter, and a number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  label: 'Confirm new password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => value != _newPasswordController.text
                      ? 'Passwords do not match.'
                      : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AscendSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AscendSpacing.lg),
                AscendPrimaryButton(
                  label: 'Change password',
                  isLoading: isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
