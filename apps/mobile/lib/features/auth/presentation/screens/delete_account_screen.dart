import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/auth_controller.dart';

/// Build Session 9 Part 5/6 — closing an account is deliberately more
/// friction than a two-button dialog: a dedicated screen, an explicit
/// warning, and re-entering the current password. On success the auth
/// state flips to unauthenticated and the router redirects to Welcome
/// on its own (same as sign-out) — no navigation call needed here.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(_passwordController.text);
    } on AppException catch (error) {
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      authControllerProvider.select((s) => s.isSubmitting),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: AscendSpacing.md),
                Text(
                  'This cannot be undone',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AscendSpacing.sm),
                const Text(
                  'Deleting your account signs you out of every device '
                  'immediately and your email address is freed for reuse. '
                  'This does not delete your data on its own — contact '
                  'Support if you need your data fully erased.',
                ),
                const SizedBox(height: AscendSpacing.lg),
                AscendTextField(
                  label: 'Confirm your password',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter your password.'
                      : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AscendSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: AscendSpacing.lg),
                AscendDangerButton(
                  label: 'Permanently delete my account',
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
