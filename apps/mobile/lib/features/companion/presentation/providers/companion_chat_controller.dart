import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/preferences_model.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../data/local_companion_response_service.dart';
import '../../domain/chat_message.dart';
import '../../domain/companion_animation_state.dart';

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
  CompanionChatController({
    required Ref ref,
    LocalCompanionResponseService? responseService,
  }) : _ref = ref,
       _responseService =
           responseService ?? const LocalCompanionResponseService(),
       super(const CompanionChatState());

  final Ref _ref;
  final LocalCompanionResponseService _responseService;
  int _messageCounter = 0;

  Companion get _companion =>
      _ref.read(preferencesControllerProvider).asData?.value?.companion ??
      Companion.atlas;

  CoachingStyle get _style =>
      _ref.read(preferencesControllerProvider).asData?.value?.coachingStyle ??
      CoachingStyle.balanced;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

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
    // a real AI gateway will replace this with an actual request latency.
    await Future.delayed(const Duration(milliseconds: 400));

    final responseText = _responseService.respond(
      text,
      companion: _companion,
      style: _style,
    );
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
