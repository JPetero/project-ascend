import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/route_paths.dart';
import '../providers/auth_controller.dart';
import '../widgets/social_sign_in_buttons.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AscendSpacing.sm),
                Text(
                  'Sign in to continue your progress.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AscendSpacing.lg),
                AscendTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter your email.'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.md),
                AscendTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter your password.'
                      : null,
                ),
                const SizedBox(height: AscendSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: AscendGhostButton(
                    label: 'Forgot password?',
                    onPressed: () => context.push(RoutePaths.forgotPassword),
                  ),
                ),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AscendSpacing.sm),
                ],
                const SizedBox(height: AscendSpacing.md),
                AscendPrimaryButton(
                  label: 'Sign In',
                  isLoading: isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: AscendSpacing.lg),
                SocialSignInButtons(
                  onError: (message) => setState(() => _errorMessage = message),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
