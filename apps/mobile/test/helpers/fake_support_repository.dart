import 'package:mobile/features/support/data/support_repository.dart';
import 'package:mobile/features/support/domain/support_ticket.dart';

SupportTicket sampleTicket({
  String id = 'ticket-1',
  SupportCategory category = SupportCategory.bugReport,
  String subject = 'App crashes on save',
  String message = 'Steps to repro...',
  SupportTicketStatus status = SupportTicketStatus.open,
  List<SupportTicketReply>? replies,
}) {
  return SupportTicket(
    id: id,
    category: category,
    subject: subject,
    message: message,
    status: status,
    createdAt: DateTime.utc(2026, 8, 7),
    replies: replies,
  );
}

/// In-memory stand-in for [SupportRepository].
class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({List<SupportTicket>? tickets})
    : tickets = tickets ?? [];

  final List<SupportTicket> tickets;
  final Map<String, List<SupportTicketReply>> repliesByTicket = {};

  @override
  Future<SupportTicket> create({
    required SupportCategory category,
    required String subject,
    required String message,
  }) async {
    final ticket = SupportTicket(
      id: 'ticket-${tickets.length}',
      category: category,
      subject: subject,
      message: message,
      status: SupportTicketStatus.open,
      createdAt: DateTime.now(),
    );
    tickets.insert(0, ticket);
    return ticket;
  }

  @override
  Future<List<SupportTicket>> listMine() async => List.unmodifiable(tickets);

  @override
  Future<SupportTicket> getById(String id) async {
    final ticket = tickets.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('not found'),
    );
    return SupportTicket(
      id: ticket.id,
      category: ticket.category,
      subject: ticket.subject,
      message: ticket.message,
      status: ticket.status,
      createdAt: ticket.createdAt,
      replies: List.unmodifiable(repliesByTicket[id] ?? const []),
    );
  }

  @override
  Future<SupportTicketReply> addReply(String id, String body) async {
    final reply = SupportTicketReply(
      id: 'reply-${(repliesByTicket[id]?.length ?? 0)}',
      authorId: 'me',
      isStaff: false,
      body: body,
      createdAt: DateTime.now(),
    );
    repliesByTicket.putIfAbsent(id, () => []).add(reply);
    return reply;
  }
}
