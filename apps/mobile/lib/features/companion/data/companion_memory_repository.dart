import '../../../core/networking/api_client.dart';

/// Thin client for `GET/DELETE /assistant/memory` (Build Session 10
/// Part 15) — the real, inspectable surface behind the "AI memory"
/// toggle in dashboard_screen.dart's `_SettingsCard`, which existed
/// since the original schema but had nothing to view or clear until now.
class CompanionMemoryRepository {
  CompanionMemoryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<String>> fetchNotes() async {
    final envelope = await _apiClient.get(
      '/assistant/memory',
      (data) => data as Map<String, dynamic>,
    );
    final notes = envelope.data?['notes'] as List<dynamic>? ?? const [];
    return notes.cast<String>();
  }

  Future<void> clear() async {
    await _apiClient.delete('/assistant/memory', (_) => null);
  }
}
