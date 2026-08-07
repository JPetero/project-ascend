import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/auth_identity.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_identity_controller.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';

/// Build Session 9 Part 5/6 — the single consolidated home for
/// credential/session/account-closure actions, reached from the
/// Dashboard's Account section. Replaces the individual identity card,
/// verify-email banner, and change-password row that Part 4 had placed
/// directly on the Dashboard.
class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final identitiesAsync = ref.watch(authIdentitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account & Security')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(authIdentitiesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AscendSpacing.md),
            children: [
              AscendCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AscendSpacing.xs),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (user != null && user.emailVerifiedAt == null) ...[
                const SizedBox(height: AscendSpacing.sm),
                const _VerifyEmailBanner(),
              ],
              const SizedBox(height: AscendSpacing.sm),
              identitiesAsync.maybeWhen(
                data: (identities) => _IdentitiesCard(identities: identities),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Credentials'),
              const SizedBox(height: AscendSpacing.sm),
              AscendCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline),
                    SizedBox(width: AscendSpacing.sm),
                    Expanded(child: Text('Change password')),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Sessions'),
              const SizedBox(height: AscendSpacing.sm),
              const _SignOutEverywhereCard(),
              const SizedBox(height: AscendSpacing.lg),
              const AscendSectionHeader(title: 'Danger zone'),
              const SizedBox(height: AscendSpacing.sm),
              AscendDangerButton(
                label: 'Delete my account',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DeleteAccountScreen(),
                  ),
                ),
              ),
              const SizedBox(height: AscendSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentitiesCard extends StatelessWidget {
  const _IdentitiesCard({required this.identities});

  final List<AuthIdentity> identities;

  @override
  Widget build(BuildContext context) {
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Signed in with', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AscendSpacing.xs),
          for (final identity in identities)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${_providerLabel(identity.provider)}'
                '${identity.providerEmail != null ? ' · ${identity.providerEmail}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: AscendSpacing.xs),
          Text(
            'Linking Google and Apple accounts is coming soon.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'GOOGLE':
        return 'Google';
      case 'APPLE':
        return 'Apple';
      default:
        return 'Email';
    }
  }
}

/// Shown only while [AuthUser.emailVerifiedAt] is null. Resending never
/// confirms whether the previous email arrived (the backend doesn't
/// report delivery status), so the button always shows the same honest
/// "on its way" confirmation.
class _VerifyEmailBanner extends ConsumerStatefulWidget {
  const _VerifyEmailBanner();

  @override
  ConsumerState<_VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends ConsumerState<_VerifyEmailBanner> {
  bool _isSending = false;

  Future<void> _resend() async {
    setState(() => _isSending = true);
    try {
      await ref.read(authControllerProvider.notifier).resendVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If your email is unverified, a new link is on its way.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AscendCard(
      child: Row(
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AscendSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verify your email', style: theme.textTheme.titleSmall),
                Text(
                  'Confirm your email address to secure your account.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AscendSpacing.sm),
          AscendSecondaryButton(
            label: 'Resend',
            expand: false,
            isLoading: _isSending,
            onPressed: _isSending ? null : _resend,
          ),
        ],
      ),
    );
  }
}

class _SignOutEverywhereCard extends ConsumerStatefulWidget {
  const _SignOutEverywhereCard();

  @override
  ConsumerState<_SignOutEverywhereCard> createState() =>
      _SignOutEverywhereCardState();
}

class _SignOutEverywhereCardState
    extends ConsumerState<_SignOutEverywhereCard> {
  String? _errorMessage;

  Future<void> _confirmAndSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of every device?'),
        content: const Text(
          "This ends every active session, including this one. You'll need to sign back in.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out everywhere'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _errorMessage = null);
    try {
      await ref.read(authControllerProvider.notifier).signOutEverywhere();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      authControllerProvider.select((s) => s.isSubmitting),
    );
    return AscendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign out of all other devices',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AscendSpacing.xs),
          Text(
            'Ends every session on every device, including this one.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AscendSpacing.xs),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AscendSpacing.sm),
          AscendSecondaryButton(
            label: 'Sign out everywhere',
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _confirmAndSignOut,
          ),
        ],
      ),
    );
  }
}
