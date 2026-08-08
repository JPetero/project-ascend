import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entitlements/capability.dart';
import '../../../../core/entitlements/capability_provider.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../profile/domain/preferences_model.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../data/ai_provider.dart';
import '../../data/live_ai_provider.dart';
import '../../data/local_deterministic_ai_provider.dart';
import '../../domain/chat_message.dart';
import '../../domain/companion_animation_state.dart';

/// The single place the live provider gets swapped in — see
/// features/companion/data/ai_provider.dart. No other call site needs to
/// change. Gated behind `AppCapability.advancedAiConversations` (Build
/// Session 9 Part 15/16): a Free account never even attempts the
/// network call, matching Scenario 18's "free deterministic dialogue...
/// stays free" — LiveAiProvider's own fallback would land on the same
/// local provider anyway if it were reached, so this is a genuine
/// short-circuit, not a behavior difference.
final aiProviderProvider = Provider<AiProvider>((ref) {
  const local = LocalDeterministicAiProvider();
  final hasLiveAccess = ref.watch(
    capabilityProvider(AppCapability.advancedAiConversations),
  );
  if (!hasLiveAccess) return local;
  return LiveAiProvider(
    apiClient: ref.watch(apiClientProvider),
    fallback: local,
  );
});

class CompanionChatState {
  const CompanionChatState({
    this.messages = const [],
    this.animationState = CompanionAnimationState.idle,
  });

  final List<ChatMessage> messages;
  final CompanionAnimationState animationState;

  CompanionChatState copyWith({
    List<ChatMessage>? messages,
    CompanionAnimationState? animationState,
  }) {
    return CompanionChatState(
      messages: messages ?? this.messages,
      animationState: animationState ?? this.animationState,
    );
  }
}

class CompanionChatController extends StateNotifier<CompanionChatState> {
  CompanionChatController({required Ref ref})
    : _ref = ref,
      super(const CompanionChatState());

  final Ref _ref;
  int _messageCounter = 0;

  AiProvider get _provider => _ref.read(aiProviderProvider);

  Companion get _companion =>
      _ref.read(preferencesControllerProvider).asData?.value?.companion ??
      Companion.atlas;

  CoachingStyle get _style =>
      _ref.read(preferencesControllerProvider).asData?.value?.coachingStyle ??
      CoachingStyle.balanced;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final priorMessages = state.messages;

    final userMessage = ChatMessage(
      id: 'msg-${_messageCounter++}',
      text: text.trim(),
      isFromUser: true,
      sentAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      animationState: CompanionAnimationState.thinking,
    );

    // Simulated thinking delay so the "thinking" state is perceptible;
    // a real AI provider replaces this with actual request latency.
    await Future.delayed(const Duration(milliseconds: 400));

    // History is everything before this turn's user message — it's how
    // AiProvider.reply recognizes this input as the answer to its own
    // previous pain-clarifying follow-up question rather than a new,
    // unrelated mention.
    final responseText = await _provider.reply(
      input: text,
      companion: _companion,
      style: _style,
      history: priorMessages,
    );
    if (!mounted) return;

    final responseMessage = ChatMessage(
      id: 'msg-${_messageCounter++}',
      text: responseText,
      isFromUser: false,
      sentAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, responseMessage],
      animationState: CompanionAnimationState.talking,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      state = state.copyWith(animationState: CompanionAnimationState.idle);
    }
  }
}

final companionChatControllerProvider =
    StateNotifierProvider.autoDispose<
      CompanionChatController,
      CompanionChatState
    >((ref) {
      return CompanionChatController(ref: ref);
    });
