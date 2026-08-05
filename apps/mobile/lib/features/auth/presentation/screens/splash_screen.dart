import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/design_system/design_system.dart';

/// Shown while the app resolves auth/profile state. Actual navigation is
/// driven entirely by [routerProvider]'s redirect logic — this screen just
/// needs to look good while that resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
