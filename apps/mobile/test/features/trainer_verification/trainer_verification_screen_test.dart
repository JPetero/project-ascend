import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_verification/domain/trainer_verification_status.dart';
import 'package:mobile/features/trainer_verification/presentation/screens/trainer_verification_screen.dart';

import '../../helpers/fake_trainer_verification_repository.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  testWidgets('shows the application form when the caller never applied', (
    tester,
  ) async {
    final container = await createTestContainer(signedIn: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerVerificationScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Certifications and experience'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('shows a pending status instead of the form', (tester) async {
    final repository = FakeTrainerVerificationRepository(
      status: TrainerVerificationApplicationStatus(
        status: TrainerVerificationDecision.pending,
        submittedAt: DateTime.utc(2026, 8, 1),
      ),
    );
    final container = await createTestContainer(
      signedIn: true,
      trainerVerificationRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerVerificationScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(find.text('Application pending review'), findsOneWidget);
    expect(find.text('Apply'), findsNothing);
  });

  testWidgets('shows the approved state with the verified badge copy', (
    tester,
  ) async {
    final repository = FakeTrainerVerificationRepository(
      status: TrainerVerificationApplicationStatus(
        status: TrainerVerificationDecision.approved,
        submittedAt: DateTime.utc(2026, 8, 1),
      ),
    );
    final container = await createTestContainer(
      signedIn: true,
      trainerVerificationRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerVerificationScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    expect(
      find.textContaining('Verified — your profile now shows'),
      findsOneWidget,
    );
  });

  testWidgets('submitting the form calls apply and shows the pending status', (
    tester,
  ) async {
    final repository = FakeTrainerVerificationRepository();
    final container = await createTestContainer(
      signedIn: true,
      trainerVerificationRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerVerificationScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.enterText(
      find.byType(TextFormField),
      'NASM certified, 5 years experience training clients.',
    );
    await tester.tap(find.text('Apply'));
    await pumpForAsyncSettle(tester);

    expect(find.text('Application pending review'), findsOneWidget);
  });

  testWidgets('validates a too-short credentials entry instead of submitting', (
    tester,
  ) async {
    final repository = FakeTrainerVerificationRepository();
    final container = await createTestContainer(
      signedIn: true,
      trainerVerificationRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TrainerVerificationScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.enterText(find.byType(TextFormField), 'too short');
    await tester.tap(find.text('Apply'));
    await pumpForAsyncSettle(tester);

    expect(
      find.text('Add at least 10 characters describing your credentials'),
      findsOneWidget,
    );
    expect(repository.status, isNull);
  });
}
