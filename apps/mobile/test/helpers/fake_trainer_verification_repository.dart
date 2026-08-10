import 'package:mobile/features/trainer_verification/data/trainer_verification_repository.dart';
import 'package:mobile/features/trainer_verification/domain/trainer_verification_status.dart';

/// In-memory stand-in for [TrainerVerificationRepository].
class FakeTrainerVerificationRepository
    implements TrainerVerificationRepository {
  FakeTrainerVerificationRepository({this.status});

  TrainerVerificationApplicationStatus? status;

  @override
  Future<TrainerVerificationApplicationStatus?> getMyStatus() async => status;

  @override
  Future<TrainerVerificationApplicationStatus> apply({
    required String credentials,
  }) async {
    final applied = TrainerVerificationApplicationStatus(
      status: TrainerVerificationDecision.pending,
      submittedAt: DateTime.utc(2026, 8, 10),
    );
    status = applied;
    return applied;
  }
}
