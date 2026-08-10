import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/trainer_verification/domain/trainer_verification_status.dart';
import 'package:mobile/features/trainer_verification/presentation/providers/trainer_verification_controller.dart';

import '../../helpers/fake_trainer_verification_repository.dart';

void main() {
  test('loads a null status when the caller never applied', () async {
    final repository = FakeTrainerVerificationRepository();
    final controller = TrainerVerificationController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, isNull);
    expect(controller.state.isLoading, isFalse);
  });

  test('loads an existing PENDING application', () async {
    final repository = FakeTrainerVerificationRepository(
      status: TrainerVerificationApplicationStatus(
        status: TrainerVerificationDecision.pending,
        submittedAt: DateTime.utc(2026, 8, 1),
      ),
    );
    final controller = TrainerVerificationController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(
      controller.state.status?.status,
      TrainerVerificationDecision.pending,
    );
  });

  test('applying records a PENDING application', () async {
    final repository = FakeTrainerVerificationRepository();
    final controller = TrainerVerificationController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.apply(
      credentials: 'NASM certified, 5 years experience',
    );

    expect(ok, isTrue);
    expect(
      controller.state.status?.status,
      TrainerVerificationDecision.pending,
    );
  });
}
