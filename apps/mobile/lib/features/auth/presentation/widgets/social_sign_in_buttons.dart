import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../feature_flags/domain/ascend_feature.dart';
import '../../../feature_flags/presentation/providers/feature_flags_provider.dart';
import '../providers/auth_controller.dart';

/// "Continue with Google/Apple" (Build Session 10 Parts 9/10), shared by
/// the sign-in and register screens — both ultimately resolve to the
/// same sign-in-or-register-on-first-use backend endpoints, so one
/// widget covers both flows. Apple only appears where
/// [AuthController.canSignInWithApple] is true (iOS/macOS) — see that
/// getter's doc comment for why Android/web are excluded rather than
/// shown with a button that could never work. Build Session 13
/// continuation Part A additionally gates each provider on its own
/// GOOGLE_SIGN_IN/APPLE_SIGN_IN feature flag — both default open (SAFE_CORE),
/// so an outage never hides a working sign-in option, but an admin can
/// still disable one without a release. Email/password stays available
/// regardless — this widget renders nothing at all rather than an
/// awkward lone divider once both providers are hidden.
class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({super.key, required this.onError});

  /// Called with the failure message on a real error, or `null` to clear
  /// a previously shown one. Cancelling the native picker calls neither
  /// — it's not an error.
  final void Function(String? message) onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider.notifier);
    final isSubmitting = ref.watch(
      authControllerProvider.select((s) => s.isSubmitting),
    );
    final googleEnabled = ref.watch(
      featureEnabledProvider(AscendFeature.googleSignIn),
    );
    final appleEnabled =
        controller.canSignInWithApple &&
        ref.watch(featureEnabledProvider(AscendFeature.appleSignIn));

    if (!googleEnabled && !appleEnabled) return const SizedBox.shrink();

    Future<void> handle(Future<void> Function() action) async {
      onError(null);
      try {
        await action();
      } on AppException catch (error) {
        onError(error.message);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AscendSpacing.sm),
              child: Text('or', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AscendSpacing.md),
        if (googleEnabled)
          AscendSecondaryButton(
            label: 'Continue with Google',
            isLoading: isSubmitting,
            onPressed: isSubmitting
                ? null
                : () => handle(controller.signInWithGoogle),
          ),
        if (appleEnabled) ...[
          const SizedBox(height: AscendSpacing.sm),
          AscendSecondaryButton(
            label: 'Continue with Apple',
            isLoading: isSubmitting,
            onPressed: isSubmitting
                ? null
                : () => handle(controller.signInWithApple),
          ),
        ],
      ],
    );
  }
}
