import '../../../core/networking/api_client.dart';
import '../domain/trainer_verification_status.dart';

/// Thin client for the trainer-verification application flow (Build
/// Session 12 Part 25-26) — services/api's community.controller.ts
/// `/community/trainer-verification*` routes. Distinct from
/// CommunityRepository.upsertOwnProfile's `isTrainer` toggle: this is a
/// real application-and-admin-review pipeline, not a self-declared badge.
class TrainerVerificationRepository {
  TrainerVerificationRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Null when the caller has never applied.
  Future<TrainerVerificationApplicationStatus?> getMyStatus() async {
    final envelope = await _apiClient.get(
      '/community/trainer-verification/me',
      (data) => data as Map<String, dynamic>?,
    );
    final data = envelope.data;
    if (data == null) return null;
    return TrainerVerificationApplicationStatus.fromJson(data);
  }

  Future<TrainerVerificationApplicationStatus> apply({
    required String credentials,
  }) async {
    final envelope = await _apiClient.post(
      '/community/trainer-verification',
      (data) => data as Map<String, dynamic>,
      data: {'credentials': credentials},
    );
    return TrainerVerificationApplicationStatus.fromJson(envelope.data!);
  }
}
