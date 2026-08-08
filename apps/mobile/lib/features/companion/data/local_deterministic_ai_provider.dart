import '../../profile/domain/preferences_model.dart';
import '../domain/chat_message.dart';
import 'ai_provider.dart';
import 'local_companion_response_service.dart';

/// Wraps the existing fully-local, deterministic dialogue generator
/// behind the provider-independent [AiProvider] interface — the only
/// implementation this session (see packages/docs/product/
/// parking-lot.md's "Live AI provider integration" entry). A future
/// live provider extends [AiProvider] directly and is swapped in via
/// `aiProviderProvider` with no change to any call site.
class LocalDeterministicAiProvider extends AiProvider {
  const LocalDeterministicAiProvider({
    LocalCompanionResponseService responseService =
        const LocalCompanionResponseService(),
  }) : _responseService = responseService;

  final LocalCompanionResponseService _responseService;

  @override
  Future<String> generateReply({
    required String input,
    required Companion companion,
    required CoachingStyle style,
    List<ChatMessage> history = const [],
  }) async {
    return _responseService.respond(input, companion: companion, style: style);
  }
}
