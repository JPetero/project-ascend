import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/support/presentation/providers/support_controller.dart';

import '../../helpers/fake_support_repository.dart';

void main() {
  test('loads the caller\'s tickets on construction', () async {
    final repository = FakeSupportRepository(tickets: [sampleTicket()]);
    final controller = SupportController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.tickets, hasLength(1));
    expect(controller.state.isLoading, isFalse);
  });

  test('starts empty with no tickets', () async {
    final repository = FakeSupportRepository();
    final controller = SupportController(repository: repository);
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.tickets, isEmpty);
  });
}
