import 'package:mobile/features/companion/data/companion_memory_repository.dart';

/// In-memory stand-in for [CompanionMemoryRepository].
class FakeCompanionMemoryRepository implements CompanionMemoryRepository {
  FakeCompanionMemoryRepository({List<String>? notes}) : notes = notes ?? [];

  final List<String> notes;

  @override
  Future<List<String>> fetchNotes() async => List.unmodifiable(notes);

  @override
  Future<void> clear() async => notes.clear();
}
