import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/design_system/design_system.dart';

void main() {
  group('AscendSpacing', () {
    test('exposes the approved spacing scale', () {
      expect(AscendSpacing.xs, 4);
      expect(AscendSpacing.sm, 8);
      expect(AscendSpacing.smMd, 12);
      expect(AscendSpacing.md, 16);
      expect(AscendSpacing.mdLg, 20);
      expect(AscendSpacing.lg, 24);
      expect(AscendSpacing.xl, 32);
      expect(AscendSpacing.xxl, 40);
      expect(AscendSpacing.xxxl, 48);
      expect(AscendSpacing.huge, 64);
      expect(AscendSpacing.massive, 96);
    });
  });

  group('AscendRadius', () {
    test('exposes the approved radius scale', () {
      expect(AscendRadius.small, 8);
      expect(AscendRadius.medium, 16);
      expect(AscendRadius.large, 24);
      expect(AscendRadius.extraLarge, 32);
      expect(AscendRadius.pill, 999);
    });
  });

  group('AscendTheme', () {
    test('dark theme uses dark brightness and Material 3', () {
      final theme = AscendTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('light theme uses light brightness and Material 3', () {
      final theme = AscendTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('button themes enforce the 48x48 minimum tap target', () {
      final theme = AscendTheme.dark();
      final elevatedSize = theme.elevatedButtonTheme.style?.minimumSize
          ?.resolve({});
      expect(elevatedSize, const Size(48, 48));
    });
  });

  group('AscendPrimaryButton', () {
    testWidgets('invokes onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AscendPrimaryButton(
              label: 'Continue',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not invoke onPressed while loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AscendPrimaryButton(
              label: 'Continue',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AscendPrimaryButton));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });
}
