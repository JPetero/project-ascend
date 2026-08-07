import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/route_paths.dart';
import '../providers/auth_controller.dart';

/// Build Session 9 Part 4. Reached either with [initialToken] already
/// known (a future universal/deep link would populate this) or blank —
/// this app has no deep-linking infrastructure yet, so today the token
/// must be pasted in from the reset email's link. See
/// packages/docs/build-session-9.md for that honest limitation.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _tokenController = TextEditingController(
    text: widget.initialToken ?? '',
  );
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
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
          .resetPassword(
            token: _tokenController.text.trim(),
            newPassword: _newPasswordController.text,
            confirmNewPassword: _confirmPasswordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your password has been reset. Sign in with your new password.',
          ),
        ),
      );
      context.go(RoutePaths.signIn);
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
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose a new password',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AscendSpacing.sm),
                Text(
                  'Paste the reset code from your email, then choose a new password.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AscendSpacing.lg),
                AscendTextField(
                  label: 'Reset code',
                  controller: _tokenController,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Paste the reset code from your email.'
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
                  label: 'Reset password',
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
