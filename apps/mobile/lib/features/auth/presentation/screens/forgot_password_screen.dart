import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/auth_controller.dart';

/// Build Session 9 Part 4 — replaces the old "coming soon" snackbar on
/// the sign-in screen with a real request-a-reset-link flow. Always
/// shows the same confirmation regardless of whether the email has an
/// account, matching the backend's no-enumeration response.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _errorMessage;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _submitted = true);
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
          child: _submitted
              ? _buildConfirmation(context)
              : _buildForm(context, isSubmitting),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isSubmitting) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset your password',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AscendSpacing.sm),
          Text(
            "Enter the email on your account and we'll send you a link to reset your password.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AscendSpacing.lg),
          AscendTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Enter your email.'
                : null,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AscendSpacing.sm),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AscendSpacing.lg),
          AscendPrimaryButton(
            label: 'Send reset link',
            isLoading: isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 56,
          color: AscendColors.successEmerald,
        ),
        const SizedBox(height: AscendSpacing.md),
        Text(
          'Check your email',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AscendSpacing.sm),
        Text(
          "If that email has an account, we've sent a link to reset your password. It expires in one hour.",
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AscendSpacing.lg),
        AscendSecondaryButton(
          label: 'Back to sign in',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
