import 'package:mobile/features/companion/data/companion_memory_repository.dart';
import 'package:mobile/features/companion/domain/companion_memory_note.dart';

/// In-memory stand-in for [CompanionMemoryRepository].
class FakeCompanionMemoryRepository implements CompanionMemoryRepository {
  FakeCompanionMemoryRepository({List<CompanionMemoryNote>? notes})
    : notes = notes ?? [];

  final List<CompanionMemoryNote> notes;

  @override
  Future<List<CompanionMemoryNote>> fetchNotes() async =>
      List.unmodifiable(notes);

  @override
  Future<void> deleteNote(String id) async {
    notes.removeWhere((note) => note.id == id);
  }

  @override
  Future<void> clear() async => notes.clear();
}

CompanionMemoryNote sampleMemoryNote({
  String id = 'note-1',
  CompanionMemoryCategory category = CompanionMemoryCategory.goal,
  String value = 'Goal: build strength.',
  DateTime? createdAt,
}) {
  return CompanionMemoryNote(
    id: id,
    category: category,
    value: value,
    createdAt: createdAt ?? DateTime.utc(2026, 8, 9),
  );
}
