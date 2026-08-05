import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../providers/auth_controller.dart';

/// Shown while the app resolves auth/profile state. Successful resolution
/// is driven entirely by [routerProvider]'s redirect logic — this screen
/// only needs to render the loading animation for that case. If profile
/// loading fails outright (not just "still loading"), it shows a retry /
/// sign-out affordance instead of leaving the user stuck on a spinner with
/// no way out.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(
      authControllerProvider.select((s) => s.status),
    );
    final profileState = authStatus == AuthStatus.authenticated
        ? ref.watch(profileControllerProvider)
        : null;

    if (profileState is AsyncError) {
      return _SplashError(
        onRetry: () => ref.read(profileControllerProvider.notifier).load(),
        onSignOut: () => ref.read(authControllerProvider.notifier).logout(),
      );
    }

    return const _SplashLoading();
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AscendColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AscendColors.primaryCyan,
                        AscendColors.successEmerald,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 44,
                  ),
                )
                .animate(target: reduceMotion ? 0 : 1)
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: AscendSpacing.lg),
            Text(
                  'Project Ascend',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AscendColors.primaryTextDark,
                  ),
                )
                .animate(target: reduceMotion ? 0 : 1)
                .fadeIn(delay: 200.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.onRetry, required this.onSignOut});

  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AscendColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AscendSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AscendColors.secondaryTextDark,
                size: 48,
              ),
              const SizedBox(height: AscendSpacing.md),
              Text(
                "Couldn't load your profile",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AscendColors.primaryTextDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AscendSpacing.sm),
              Text(
                'Check your connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AscendSpacing.lg),
              AscendPrimaryButton(label: 'Try again', onPressed: onRetry),
              const SizedBox(height: AscendSpacing.sm),
              AscendGhostButton(label: 'Sign out', onPressed: onSignOut),
            ],
          ),
        ),
      ),
    );
  }
}
