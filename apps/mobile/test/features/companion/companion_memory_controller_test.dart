import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/domain/companion_memory_note.dart';
import 'package:mobile/features/companion/presentation/providers/companion_memory_controller.dart';

import '../../helpers/fake_companion_memory_repository.dart';

void main() {
  test('loads the caller\'s remembered notes on construction', () async {
    final repository = FakeCompanionMemoryRepository(
      notes: [sampleMemoryNote(value: 'Training for a half marathon.')],
    );
    final controller = CompanionMemoryController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(
      controller.state.notes.single.value,
      'Training for a half marathon.',
    );
  });

  test(
    'deleteNote() removes just that one note and is reflected in state',
    () async {
      final repository = FakeCompanionMemoryRepository(
        notes: [
          sampleMemoryNote(
            id: 'note-1',
            value: 'Training for a half marathon.',
          ),
          sampleMemoryNote(id: 'note-2', value: 'Has access to: dumbbells.'),
        ],
      );
      final controller = CompanionMemoryController(repository: repository);
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      await controller.deleteNote('note-1');

      expect(controller.state.notes.map((n) => n.id), ['note-2']);
      expect((await repository.fetchNotes()).map((n) => n.id), ['note-2']);
    },
  );

  test('clear() empties the notes and is reflected in state', () async {
    final repository = FakeCompanionMemoryRepository(
      notes: [sampleMemoryNote(value: 'Training for a half marathon.')],
    );
    final controller = CompanionMemoryController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    await controller.clear();

    expect(controller.state.notes, isEmpty);
    expect(await repository.fetchNotes(), isEmpty);
  });

  test('refresh() surfaces a fetch failure without throwing', () async {
    final controller = CompanionMemoryController(
      repository: _ThrowingCompanionMemoryRepository(),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.error, isNotNull);
  });
}

class _ThrowingCompanionMemoryRepository extends FakeCompanionMemoryRepository {
  @override
  Future<List<CompanionMemoryNote>> fetchNotes() async =>
      throw Exception('network error');
}
