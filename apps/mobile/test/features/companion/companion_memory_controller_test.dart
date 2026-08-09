import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/companion/presentation/providers/companion_memory_controller.dart';

import '../../helpers/fake_companion_memory_repository.dart';

void main() {
  test('loads the caller\'s remembered notes on construction', () async {
    final repository = FakeCompanionMemoryRepository(
      notes: ['Training for a half marathon.'],
    );
    final controller = CompanionMemoryController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.notes, ['Training for a half marathon.']);
  });

  test('clear() empties the notes and is reflected in state', () async {
    final repository = FakeCompanionMemoryRepository(
      notes: ['Training for a half marathon.'],
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
  Future<List<String>> fetchNotes() async => throw Exception('network error');
}
