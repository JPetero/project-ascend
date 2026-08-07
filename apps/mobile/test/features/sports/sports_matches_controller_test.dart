import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sports/presentation/providers/sports_matches_controller.dart';

import '../../helpers/fake_sports_repository.dart';

void main() {
  test('loads matches and rating on construction', () async {
    final repository = FakeSportsRepository(
      matches: [sampleSportMatch(id: 'match-1')],
    );
    final controller = SportsMatchesController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.matches, hasLength(1));
    expect(controller.state.rating, isNotNull);
    expect(controller.state.isLoading, isFalse);
  });

  test('createMatch adds a new challenge and refreshes', () async {
    final repository = FakeSportsRepository();
    final controller = SportsMatchesController(repository: repository);
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final match = await controller.createMatch('friend-1');

    expect(match, isNotNull);
    expect(controller.state.matches, hasLength(1));
  });
}
