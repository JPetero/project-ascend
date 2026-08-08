import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/voice/speech_to_text_service.dart';
import '../../../../core/voice/text_to_speech_service.dart';
import 'companion_chat_controller.dart';

final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  return PluginSpeechToTextService();
});

final textToSpeechServiceProvider = Provider<TextToSpeechService>((ref) {
  return PluginTextToSpeechService();
});

enum VoiceListeningStatus { idle, requestingPermission, listening, unavailable }

class CompanionVoiceState {
  const CompanionVoiceState({
    this.listeningStatus = VoiceListeningStatus.idle,
    this.partialTranscript = '',
    this.speakRepliesEnabled = false,
    this.isSpeaking = false,
  });

  final VoiceListeningStatus listeningStatus;
  final String partialTranscript;
  final bool speakRepliesEnabled;
  final bool isSpeaking;

  CompanionVoiceState copyWith({
    VoiceListeningStatus? listeningStatus,
    String? partialTranscript,
    bool? speakRepliesEnabled,
    bool? isSpeaking,
  }) {
    return CompanionVoiceState(
      listeningStatus: listeningStatus ?? this.listeningStatus,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      speakRepliesEnabled: speakRepliesEnabled ?? this.speakRepliesEnabled,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

/// Atlas/Nova voice V1 (Build Session 9 Part 14) — real, on-device speech
/// input and output layered on top of the existing text chat pipeline,
/// not a replacement for it: a finished voice utterance is just handed
/// to [CompanionChatController.sendMessage] as ordinary text, so it goes
/// through the exact same safety gate every typed message does (see
/// `AiProvider.reply`'s doc comment). Gated behind
/// `AppCapability.premiumCompanionVoices` at the call site (the mic
/// button/speak-replies toggle), matching atlas-nova-bible.md's "explicit
/// user activation... no always-listening behavior by default" rule —
/// nothing here starts listening or speaking on its own.
class CompanionVoiceController extends StateNotifier<CompanionVoiceState> {
  CompanionVoiceController({
    required SpeechToTextService speechToText,
    required TextToSpeechService textToSpeech,
    required void Function(String text) onFinalTranscript,
  }) : _speechToText = speechToText,
       _textToSpeech = textToSpeech,
       _onFinalTranscript = onFinalTranscript,
       super(const CompanionVoiceState());

  final SpeechToTextService _speechToText;
  final TextToSpeechService _textToSpeech;
  final void Function(String text) _onFinalTranscript;

  Future<void> startListening() async {
    state = state.copyWith(
      listeningStatus: VoiceListeningStatus.requestingPermission,
      partialTranscript: '',
    );
    final availability = await _speechToText.initialize();
    if (!mounted) return;
    if (availability != SpeechAvailability.available) {
      state = state.copyWith(listeningStatus: VoiceListeningStatus.unavailable);
      return;
    }

    state = state.copyWith(listeningStatus: VoiceListeningStatus.listening);
    await _speechToText.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        state = state.copyWith(partialTranscript: text);
        if (isFinal) {
          state = state.copyWith(
            listeningStatus: VoiceListeningStatus.idle,
            partialTranscript: '',
          );
          if (text.trim().isNotEmpty) _onFinalTranscript(text.trim());
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stopListening();
    if (mounted) {
      state = state.copyWith(listeningStatus: VoiceListeningStatus.idle);
    }
  }

  void setSpeakRepliesEnabled(bool value) {
    state = state.copyWith(speakRepliesEnabled: value);
    if (!value) unawaited(stopSpeaking());
  }

  /// Called only from this provider's own `ref.listen` on the chat
  /// controller, and only for a newly-arrived companion reply — never
  /// for user messages, and never when [CompanionVoiceState.speakRepliesEnabled]
  /// is off.
  Future<void> speak(String text) async {
    if (!state.speakRepliesEnabled || text.trim().isEmpty) return;
    state = state.copyWith(isSpeaking: true);
    await _textToSpeech.speak(text);
    if (mounted) state = state.copyWith(isSpeaking: false);
  }

  Future<void> stopSpeaking() async {
    await _textToSpeech.stop();
    if (mounted) state = state.copyWith(isSpeaking: false);
  }
}

final companionVoiceControllerProvider = StateNotifierProvider.autoDispose<
  CompanionVoiceController,
  CompanionVoiceState
>((ref) {
  final controller = CompanionVoiceController(
    speechToText: ref.watch(speechToTextServiceProvider),
    textToSpeech: ref.watch(textToSpeechServiceProvider),
    onFinalTranscript: (text) {
      ref.read(companionChatControllerProvider.notifier).sendMessage(text);
    },
  );

  ref.listen<CompanionChatState>(companionChatControllerProvider, (
    previous,
    next,
  ) {
    final previousCount = previous?.messages.length ?? 0;
    if (next.messages.length <= previousCount) return;
    final latest = next.messages.last;
    if (!latest.isFromUser) controller.speak(latest.text);
  });

  return controller;
});
