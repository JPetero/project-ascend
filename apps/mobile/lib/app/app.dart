import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/ascend_theme.dart';
import '../core/routing/app_router.dart';
import '../features/profile/domain/preferences_model.dart';
import '../features/profile/presentation/providers/preferences_controller.dart';

class AscendApp extends ConsumerWidget {
  const AscendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
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

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
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
      ),
    );
  }
}
