import '../../../core/networking/api_client.dart';
import '../domain/support_ticket.dart';

/// Thin client for services/api/src/modules/support — help center,
/// bug reports, safety reports, accessibility feedback, account
/// recovery, billing help, and moderation appeals (Founder Scenario
/// 27). Every category is free on every tier.
class SupportRepository {
  SupportRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<SupportTicket> create({
    required SupportCategory category,
    required String subject,
    required String message,
  }) async {
    final envelope = await _apiClient.post(
      '/support/tickets',
      (data) => data as Map<String, dynamic>,
      data: {
        'category': supportCategoryToJson(category),
        'subject': subject,
        'message': message,
      },
    );
    return SupportTicket.fromJson(envelope.data!);
  }

  Future<List<SupportTicket>> listMine() async {
    final envelope = await _apiClient.get(
      '/support/tickets',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((t) => SupportTicket.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<SupportTicket> getById(String id) async {
    final envelope = await _apiClient.get(
      '/support/tickets/$id',
      (data) => data as Map<String, dynamic>,
    );
    return SupportTicket.fromJson(envelope.data!);
  }

  Future<SupportTicketReply> addReply(String id, String body) async {
    final envelope = await _apiClient.post(
      '/support/tickets/$id/replies',
      (data) => data as Map<String, dynamic>,
      data: {'body': body},
    );
    return SupportTicketReply.fromJson(envelope.data!);
  }
}
