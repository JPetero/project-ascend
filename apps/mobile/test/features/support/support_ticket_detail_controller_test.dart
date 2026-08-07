import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/support/presentation/providers/support_ticket_detail_controller.dart';

import '../../helpers/fake_support_repository.dart';

void main() {
  test('loads a ticket with no replies', () async {
    final repository = FakeSupportRepository(
      tickets: [sampleTicket(id: 'ticket-1')],
    );
    final controller = SupportTicketDetailController(
      repository: repository,
      ticketId: 'ticket-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.ticket?.id, 'ticket-1');
    expect(controller.state.ticket?.replies, isEmpty);
  });

  test('adding a reply appends it to the thread', () async {
    final repository = FakeSupportRepository(
      tickets: [sampleTicket(id: 'ticket-1')],
    );
    final controller = SupportTicketDetailController(
      repository: repository,
      ticketId: 'ticket-1',
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.addReply('Any update?');

    expect(ok, isTrue);
    expect(controller.state.ticket?.replies, hasLength(1));
    expect(controller.state.ticket?.replies?.single.isStaff, isFalse);
  });
}
