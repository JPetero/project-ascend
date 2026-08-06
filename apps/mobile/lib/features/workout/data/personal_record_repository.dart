import '../../../core/networking/api_client.dart';
import '../domain/personal_record.dart';

class PersonalRecordRepository {
  PersonalRecordRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<PersonalRecord>> list() async {
    final envelope = await _apiClient.get(
      '/personal-records',
      (data) => data as List<dynamic>,
    );
    return (envelope.data ?? [])
        .map((r) => PersonalRecord.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
