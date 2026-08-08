import '../../../core/networking/api_client.dart';
import '../../profile/domain/preferences_model.dart';
import '../domain/chat_message.dart';
import 'ai_provider.dart';

/// Build Session 9 Part 15/16 — the first real live provider: calls the
/// backend's `POST /assistant/reply` (see
/// services/api/src/modules/assistant/), which proxies to Anthropic when
/// `ANTHROPIC_API_KEY` is configured. Extends [AiProvider] directly
/// (never wraps [LocalDeterministicAiProvider] as its base), so `reply()`
/// stays inherited and the shared safety gate is structurally
/// impossible to bypass — this only ever overrides [generateReply].
///
/// [fallback] is used whenever the backend call fails for any reason —
/// not configured (no live key in this environment, see
/// build-session-9.md), offline, or a network/server error — so a user
/// on a Premium account that happens to hit any of those still gets a
/// real reply instead of an error bubble. This is the client-side half
/// of the honest-degradation pattern; the backend's own honesty ("not
/// configured" rather than a fabricated reply) is AssistantService's job.
///
/// Deliberately does not override [AiProvider.researchReply] — inherits
/// the honest "not available" default. Research Mode still has no
/// verified-citation pipeline behind it; Scenario 19's hard rule ("must
/// never invent a citation... must include source verification before it
/// ships") isn't satisfied by an LLM call alone, so that stays future
/// work rather than shipping a plausible-sounding but unverified answer.
class LiveAiProvider extends AiProvider {
  LiveAiProvider({required ApiClient apiClient, required AiProvider fallback})
    : _apiClient = apiClient,
      _fallback = fallback;

  final ApiClient _apiClient;
  final AiProvider _fallback;

  @override
  Future<String> generateReply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
    List<ChatMessage> history = const [],
  }) async {
    try {
      final envelope = await _apiClient.post(
        '/assistant/reply',
        (data) => data as Map<String, dynamic>,
        data: {
          'input': input,
          'companion': companion.name.toUpperCase(),
          'style': style.name.toUpperCase(),
          'history': history
              .map((m) => {'text': m.text, 'isFromUser': m.isFromUser})
              .toList(),
        },
      );
      final reply = envelope.data?['reply'] as String?;
      if (reply != null && reply.trim().isNotEmpty) return reply;
    } catch (_) {
      // Falls through to the fallback below — never surfaces a raw
      // network/server error to the chat UI.
    }
    return _fallback.generateReply(
      input: input,
      companion: companion,
      style: style,
      history: history,
    );
  }
}
