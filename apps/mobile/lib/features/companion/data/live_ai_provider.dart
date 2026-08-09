import '../../../core/networking/api_client.dart';
import '../../profile/domain/preferences_model.dart';
import '../domain/chat_message.dart';
import '../domain/companion_memory_note.dart';
import '../domain/research_answer.dart';
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
/// [researchReply] (Build Session 10 Part 16) follows the same
/// degradation pattern, calling `POST /research/query` — see
/// `BraveSearchResearchProvider`'s doc comment for why that pipeline
/// never risks Scenario 19's "must never invent a citation" rule: it's
/// pure retrieval against a curated trusted-domain allowlist, with no
/// generative summarization step to hallucinate from. Any failure (not
/// configured, not Premium, offline, server error) falls back to
/// [AiProvider.researchReply]'s honest "not available" default rather
/// than surfacing a raw error.
class LiveAiProvider extends AiProvider {
  LiveAiProvider({required ApiClient apiClient, required AiProvider fallback})
    : _apiClient = apiClient,
      _fallback = fallback;

  final ApiClient _apiClient;
  final AiProvider _fallback;

  /// Set when the backend's last `/assistant/reply` response included a
  /// SENSITIVE-category `pendingMemory` (Build Session 12 Part 4) —
  /// `AiProvider.reply()`'s return type is a plain `String`, shared by
  /// every provider, so this is a narrow side-channel read by
  /// `CompanionChatController` via an `is LiveAiProvider` check right
  /// after calling `reply()`, rather than widening that shared contract
  /// for one provider's feature. Always reset at the start of each
  /// `generateReply` call so a stale candidate from an earlier turn is
  /// never mistaken for this turn's.
  PendingCompanionMemory? pendingMemoryCandidate;

  /// Tracks the backend conversation this provider instance's turns
  /// belong to (Build Session 12 Part 8) — sent back on every subsequent
  /// call so a whole chat session appends to one saved conversation
  /// instead of every turn silently starting a new one. Self-contained:
  /// since [aiProviderProvider] keeps the same `LiveAiProvider` instance
  /// alive for an entire chat session, no other class needs to read or
  /// set this for that to work. Null again (a fresh conversation) once a
  /// new `LiveAiProvider` is created (e.g. after an app restart), or
  /// whenever the backend didn't return one (history disabled, or this
  /// call fell back to the local provider).
  String? conversationId;

  @override
  Future<String> generateReply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
    List<ChatMessage> history = const [],
  }) async {
    pendingMemoryCandidate = null;
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
          if (conversationId != null) 'conversationId': conversationId,
        },
      );
      final reply = envelope.data?['reply'] as String?;
      final rawPendingMemory =
          envelope.data?['pendingMemory'] as Map<String, dynamic>?;
      if (rawPendingMemory != null) {
        pendingMemoryCandidate = PendingCompanionMemory.fromJson(
          rawPendingMemory,
        );
      }
      conversationId = envelope.data?['conversationId'] as String?;
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

  @override
  Future<ResearchAnswer> researchReply({required String query}) async {
    try {
      final envelope = await _apiClient.post(
        '/research/query',
        (data) => data as Map<String, dynamic>,
        data: {'query': query},
      );
      final body = envelope.data;
      if (body == null) {
        return super.researchReply(query: query);
      }
      final rawSources = body['sources'] as List<dynamic>? ?? const [];
      return ResearchAnswer(
        isAvailable: true,
        conciseAnswer: body['conciseAnswer'] as String?,
        deeperExplanation: body['deeperExplanation'] as String?,
        uncertaintyNote: body['uncertaintyNote'] as String?,
        contradictoryEvidenceNote: body['contradictoryEvidenceNote'] as String?,
        sources: rawSources
            .cast<Map<String, dynamic>>()
            .map(ResearchSource.fromJson)
            .toList(),
      );
    } catch (_) {
      // Not configured, not Premium, offline, or a server error — never
      // surfaces a raw error to the Research Mode screen.
      return super.researchReply(query: query);
    }
  }
}
