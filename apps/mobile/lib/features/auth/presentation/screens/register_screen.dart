import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptedTerms) {
      setState(
        () => _errorMessage = 'Please acknowledge the terms to continue.',
      );
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            firstName: _firstNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            acceptedTerms: _acceptedTerms,
          );
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
                  'Create your account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AscendSpacing.sm),
                Text(
                  'Start your journey with Ascend.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AscendSpacing.lg),
                AscendTextField(
                  label: 'First name',
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter your first name.'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your email.';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  label: 'Password',
                  controller: _passwordController,
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
                  label: 'Confirm password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => value != _passwordController.text
                      ? 'Passwords do not match.'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.md),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _acceptedTerms,
                  onChanged: (value) =>
                      setState(() => _acceptedTerms = value ?? false),
                  title: const Text(
                    'I agree to the Terms of Service and Privacy Policy.',
                  ),
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
                  label: 'Create Account',
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
