import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AscendSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
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
                  size: 40,
                ),
              ),
              const SizedBox(height: AscendSpacing.lg),
              Text(
                'Project Ascend',
                style: theme.textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AscendSpacing.sm),
              Text(
                'Become healthier, stronger, and more confident — with an intelligent '
                'companion by your side every step of the way.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AscendPrimaryButton(
                label: 'Create Account',
                onPressed: () => context.push(RoutePaths.register),
              ),
              const SizedBox(height: AscendSpacing.sm),
              AscendSecondaryButton(
                label: 'Sign In',
                onPressed: () => context.push(RoutePaths.signIn),
              ),
              const SizedBox(height: AscendSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
