import '../../../core/networking/api_client.dart';

/// Thin client for services/api/src/modules/data-export — Build
/// Session 8 Part 14. The export payload is a loosely-typed JSON blob
/// by design (it spans account/fitness/nutrition/cardio/health/
/// achievements/social sections) rather than a rigid domain model, so
/// the Flutter side never has to be kept in lockstep with every field
/// the backend adds to the export.
class DataExportRepository {
  DataExportRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchExport() async {
    final envelope = await _apiClient.get(
      '/account/data-export',
      (data) => data as Map<String, dynamic>,
    );
    return envelope.data!;
  }
}
