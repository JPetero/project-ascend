import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// The corner-ribbon text for a given [AppEnvironment] — `null` for
/// [AppEnvironment.prod], since a production build should never carry a
/// visible "which build is this" marker. Pure so it's unit-testable
/// without mounting a widget tree.
String? environmentBannerLabel(AppEnvironment environment) {
  switch (environment) {
    case AppEnvironment.dev:
      return 'DEV';
    case AppEnvironment.staging:
      return 'STAGING';
    case AppEnvironment.prod:
      return null;
  }
}

/// A small corner ribbon (S13 Part 16-27) showing which [AppEnvironment]
/// this build is — so a tester can't mistake a dev or staging build for
/// production at a glance, the same failure mode
/// [AppConfig.apiBaseUrl]'s doc comment refuses to paper over with a
/// fabricated default. Renders nothing at all for
/// [AppEnvironment.prod] (see [environmentBannerLabel]), matching
/// [MaterialApp]'s own `debugShowCheckedModeBanner` convention of never
/// appearing in a release-configured build.
class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({
    super.key,
    required this.environment,
    required this.child,
  });

  final AppEnvironment environment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = environmentBannerLabel(environment);
    if (label == null) return child;

    return Banner(
      message: label,
      location: BannerLocation.topEnd,
      color: environment == AppEnvironment.staging
          ? Colors.deepOrange
          : Colors.blueAccent,
      child: child,
    );
  }
}
