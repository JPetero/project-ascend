import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entitlements/capability.dart';
import '../../../../core/entitlements/capability_provider.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../feature_flags/domain/ascend_feature.dart';
import '../../../feature_flags/presentation/providers/feature_flags_provider.dart';
import '../../../profile/domain/preferences_model.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../data/ai_provider.dart';
import '../../data/live_ai_provider.dart';
import '../../data/local_deterministic_ai_provider.dart';
import '../../domain/chat_message.dart';
import '../../domain/companion_animation_state.dart';
import '../../domain/companion_memory_note.dart';
import 'companion_memory_controller.dart';

/// The single place the live provider gets swapped in — see
/// features/companion/data/ai_provider.dart. No other call site needs to
/// change. Gated behind `AppCapability.advancedAiConversations` (Build
/// Session 9 Part 15/16): a Free account never even attempts the
/// network call, matching Scenario 18's "free deterministic dialogue...
/// stays free" — LiveAiProvider's own fallback would land on the same
/// local provider anyway if it were reached, so this is a genuine
/// short-circuit, not a behavior difference.
///
/// The LIVE_AI feature flag (Build Session 13 continuation Part A) is
/// threaded into [LiveAiProvider.chatEnabled] rather than gating which
/// concrete provider gets constructed here — [LiveAiProvider] is the
/// same instance ResearchModeScreen calls `researchReply` on, and that
/// path is independently gated by its own RESEARCH_MODE flag server-side
/// and client-side; LIVE_AI disabled must silence live *chat* replies
/// without also silencing Research Mode.
final aiProviderProvider = Provider<AiProvider>((ref) {
  const local = LocalDeterministicAiProvider();
  final hasLiveAccess = ref.watch(
    capabilityProvider(AppCapability.advancedAiConversations),
  );
  if (!hasLiveAccess) return local;
  return LiveAiProvider(
    apiClient: ref.watch(apiClientProvider),
    fallback: local,
    chatEnabled: ref.watch(featureEnabledProvider(AscendFeature.liveAi)),
  );
});

class CompanionChatState {
  const CompanionChatState({
    this.messages = const [],
    this.animationState = CompanionAnimationState.idle,
    this.pendingMemory,
    this.dismissedPendingMemoryKeys = const {},
  });

  final List<ChatMessage> messages;
  final CompanionAnimationState animationState;

  /// A SENSITIVE-category fact the assistant just noticed but did not
  /// auto-save (Build Session 12 Part 4) — non-null only while the
  /// "Remember this?" prompt should be showing.
  final PendingCompanionMemory? pendingMemory;

  /// Every candidate the user has already said "Not now" to in this
  /// chat session, keyed by [PendingCompanionMemory.dedupeKey] — so the
  /// exact same fact is never re-prompted after a refusal.
  final Set<String> dismissedPendingMemoryKeys;

  CompanionChatState copyWith({
    List<ChatMessage>? messages,
    CompanionAnimationState? animationState,
    PendingCompanionMemory? pendingMemory,
    bool clearPendingMemory = false,
    Set<String>? dismissedPendingMemoryKeys,
  }) {
    return CompanionChatState(
      messages: messages ?? this.messages,
      animationState: animationState ?? this.animationState,
      pendingMemory: clearPendingMemory
          ? null
          : (pendingMemory ?? this.pendingMemory),
      dismissedPendingMemoryKeys:
          dismissedPendingMemoryKeys ?? this.dismissedPendingMemoryKeys,
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
    final provider = _provider;
    final responseText = await provider.reply(
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

    // Build Session 12 Part 4 — a SENSITIVE-category candidate this turn
    // surfaced but did not auto-save. Never re-shown for a fact the user
    // already dismissed once this session (see dismissPendingMemory).
    final candidate = provider is LiveAiProvider
        ? provider.pendingMemoryCandidate
        : null;
    final showPendingMemory =
        candidate != null &&
        !state.dismissedPendingMemoryKeys.contains(candidate.dedupeKey);

    state = state.copyWith(
      messages: [...state.messages, responseMessage],
      animationState: CompanionAnimationState.talking,
      pendingMemory: showPendingMemory ? candidate : null,
      clearPendingMemory: !showPendingMemory,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      state = state.copyWith(animationState: CompanionAnimationState.idle);
    }
  }

  /// The user tapped "Remember" on the sensitive-memory prompt.
  Future<void> confirmPendingMemory() async {
    final candidate = state.pendingMemory;
    if (candidate == null) return;
    state = state.copyWith(clearPendingMemory: true);
    await _ref
        .read(companionMemoryRepositoryProvider)
        .confirmPendingMemory(candidate);
    // Best-effort refresh of the "manage memory" list — a failure here
    // must never look like the confirmation itself failed.
    unawaited(_ref.read(companionMemoryControllerProvider.notifier).refresh());
  }

  /// The user tapped "Not now" — clears the prompt and remembers not to
  /// ask again for this exact fact during this chat session.
  void dismissPendingMemory() {
    final candidate = state.pendingMemory;
    if (candidate == null) return;
    state = state.copyWith(
      clearPendingMemory: true,
      dismissedPendingMemoryKeys: {
        ...state.dismissedPendingMemoryKeys,
        candidate.dedupeKey,
      },
    );
  }
}

final companionChatControllerProvider =
    StateNotifierProvider.autoDispose<
      CompanionChatController,
      CompanionChatState
    >((ref) {
      return CompanionChatController(ref: ref);
    });
