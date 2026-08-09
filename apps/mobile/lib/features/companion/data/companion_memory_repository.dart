import '../../../core/networking/api_client.dart';
import '../domain/companion_memory_note.dart';

/// Thin client for `GET/DELETE /assistant/memory` (Build Session 10
/// Part 15) — the real, inspectable surface behind the "AI memory"
/// toggle in dashboard_screen.dart's `_SettingsCard`. Build Session 11
/// Part 4: notes are now structured (category/value/createdAt) instead
/// of raw remembered sentences, and a single note can be deleted without
/// clearing everything. Build Session 12 Part 4 added
/// `confirmPendingMemory` for the SENSITIVE-category confirm flow.
class CompanionMemoryRepository {
  CompanionMemoryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<CompanionMemoryNote>> fetchNotes() async {
    final envelope = await _apiClient.get(
      '/assistant/memory',
      (data) => data as Map<String, dynamic>,
    );
    final notes = envelope.data?['notes'] as List<dynamic>? ?? const [];
    return notes
        .cast<Map<String, dynamic>>()
        .map(CompanionMemoryNote.fromJson)
        .toList();
  }

  Future<void> deleteNote(String id) async {
    await _apiClient.delete('/assistant/memory/$id', (_) => null);
  }

  Future<void> clear() async {
    await _apiClient.delete('/assistant/memory', (_) => null);
  }

  /// Persists a candidate `POST /assistant/reply` surfaced but did not
  /// auto-save because [PendingCompanionMemory.category] is SENSITIVE —
  /// the user just explicitly agreed via the "Remember" prompt.
  Future<void> confirmPendingMemory(PendingCompanionMemory candidate) async {
    await _apiClient.post(
      '/assistant/memory/confirm',
      (_) => null,
      data: {
        'category': categoryToJson(candidate.category),
        'value': candidate.value,
      },
    );
  }
}
