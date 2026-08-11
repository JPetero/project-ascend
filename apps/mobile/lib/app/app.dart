import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/design_system/ascend_theme.dart';
import '../core/routing/app_router.dart';
import '../core/widgets/environment_banner.dart';
import '../features/achievements/presentation/widgets/achievement_celebration_overlay.dart';
import '../features/feature_flags/presentation/providers/feature_flags_provider.dart';
import '../features/notifications/presentation/providers/push_registration_controller.dart';
import '../features/profile/domain/preferences_model.dart';
import '../features/profile/presentation/providers/preferences_controller.dart';

class AscendApp extends ConsumerWidget {
  const AscendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Riverpod providers are lazy — watching this here is what actually
    // starts remote push registration/tap-navigation (Build Session 11
    // Part 5/6), not just a value read.
    ref.watch(pushRegistrationControllerProvider);
    // Same "watching starts it" reasoning — resolves the caller's feature
    // flag map once at startup/sign-in (Build Session 12 Part 15-17).
    ref.watch(featureFlagsProvider);
    final themeMode = ref.watch(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.themeMode ?? AppThemeMode.system,
      ),
    );
    final reducedMotion = ref.watch(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.reducedMotion ?? false,
      ),
    );
    final textScale = ref.watch(
      preferencesControllerProvider.select(
        (s) => s.asData?.value?.textScale ?? 1.0,
      ),
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reducedMotion,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp.router(
        title: 'Project Ascend',
        debugShowCheckedModeBanner: false,
        theme: AscendTheme.light(),
        darkTheme: AscendTheme.dark(),
        themeMode: switch (themeMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.system => ThemeMode.system,
        },
        routerConfig: router,
        // Mounts inside the routed app (not wrapping it) so the overlay's
        // own BuildContext is inside the GoRouter/Navigator — see
        // AchievementCelebrationOverlay's doc comment for why that's
        // required, and why AppShell wouldn't be a wide-enough mount point.
        builder: (context, child) => EnvironmentBanner(
          environment: AppConfig.environment,
          child: AchievementCelebrationOverlay(child: child!),
        ),
      ),
    );
  }
}
