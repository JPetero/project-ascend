import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';

import '../../helpers/test_provider_scope.dart';

Future<void> _pumpRegisterScreen(WidgetTester tester) async {
  final container = await createTestContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RegisterScreen()),
    ),
  );
}

void main() {
  group('RegisterScreen validation', () {
    testWidgets('shows field errors when submitting empty form', (
      tester,
    ) async {
      await _pumpRegisterScreen(tester);

      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Enter your first name.'), findsOneWidget);
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
    });

    testWidgets('flags mismatched passwords', (tester) async {
      await _pumpRegisterScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'Ada',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'ada@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Str0ngPass!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'Different1!',
      );

      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(find.text('Enter your first name.'), findsNothing);
    });

    testWidgets('requires accepting the terms even with valid fields', (
      tester,
    ) async {
      await _pumpRegisterScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'First name'),
        'Ada',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'ada@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Str0ngPass!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'Str0ngPass!',
      );

      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(
        find.text('Please acknowledge the terms to continue.'),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    'also offers Google/Apple continue buttons (Build Session 10 Parts 9/10)',
    (tester) async {
      await _pumpRegisterScreen(tester);

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
    },
  );
}
