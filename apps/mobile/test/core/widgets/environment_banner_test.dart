import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/widgets/environment_banner.dart';

void main() {
  group('environmentBannerLabel', () {
    test('dev shows a DEV label', () {
      expect(environmentBannerLabel(AppEnvironment.dev), 'DEV');
    });

    test('staging shows a STAGING label', () {
      expect(environmentBannerLabel(AppEnvironment.staging), 'STAGING');
    });

    test('prod has no label — never shown', () {
      expect(environmentBannerLabel(AppEnvironment.prod), isNull);
    });
  });

  group('EnvironmentBanner', () {
    testWidgets('shows a Banner for a dev build', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: EnvironmentBanner(
            environment: AppEnvironment.dev,
            child: Text('content'),
          ),
        ),
      );

      expect(find.byType(Banner), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('shows a Banner for a staging build', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: EnvironmentBanner(
            environment: AppEnvironment.staging,
            child: Text('content'),
          ),
        ),
      );

      expect(find.byType(Banner), findsOneWidget);
    });

    testWidgets('renders the child directly with no Banner for a prod build', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: EnvironmentBanner(
            environment: AppEnvironment.prod,
            child: Text('content'),
          ),
        ),
      );

      expect(find.byType(Banner), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
