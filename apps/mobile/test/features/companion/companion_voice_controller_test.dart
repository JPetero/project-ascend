import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/voice/speech_to_text_service.dart';
import 'package:mobile/features/companion/presentation/providers/companion_voice_controller.dart';

import '../../helpers/fake_speech_to_text_service.dart';
import '../../helpers/fake_text_to_speech_service.dart';

void main() {
  late FakeSpeechToTextService speechToText;
  late FakeTextToSpeechService textToSpeech;
  late List<String> finalTranscripts;

  CompanionVoiceController buildController() {
    return CompanionVoiceController(
      speechToText: speechToText,
      textToSpeech: textToSpeech,
      onFinalTranscript: finalTranscripts.add,
    );
  }

  setUp(() {
    speechToText = FakeSpeechToTextService();
    textToSpeech = FakeTextToSpeechService();
    finalTranscripts = [];
  });

  test(
    'startListening moves through requestingPermission to listening when available',
    () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.startListening();

      expect(controller.state.listeningStatus, VoiceListeningStatus.listening);
      expect(speechToText.startListeningCallCount, 1);
    },
  );

  test(
    'startListening reports unavailable honestly when the device cannot',
    () async {
      speechToText.availability = SpeechAvailability.unavailable;
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.startListening();

      expect(
        controller.state.listeningStatus,
        VoiceListeningStatus.unavailable,
      );
      expect(speechToText.startListeningCallCount, 0);
    },
  );

  test('a partial result updates the transcript without finishing', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.startListening();

    speechToText.emitResult('log a', isFinal: false);

    expect(controller.state.partialTranscript, 'log a');
    expect(controller.state.listeningStatus, VoiceListeningStatus.listening);
    expect(finalTranscripts, isEmpty);
  });

  test('a final result clears the transcript, returns to idle, and hands the '
      'text to onFinalTranscript', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.startListening();

    speechToText.emitResult('log a meal', isFinal: true);

    expect(controller.state.listeningStatus, VoiceListeningStatus.idle);
    expect(controller.state.partialTranscript, isEmpty);
    expect(finalTranscripts, ['log a meal']);
  });

  test('a blank final result is not handed to onFinalTranscript', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.startListening();

    speechToText.emitResult('   ', isFinal: true);

    expect(finalTranscripts, isEmpty);
  });

  test('stopListening returns to idle', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.startListening();

    await controller.stopListening();

    expect(controller.state.listeningStatus, VoiceListeningStatus.idle);
    expect(speechToText.stopListeningCallCount, 1);
  });

  test('setSpeakRepliesEnabled(false) stops any in-progress speech', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    controller.setSpeakRepliesEnabled(true);

    controller.setSpeakRepliesEnabled(false);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.speakRepliesEnabled, isFalse);
    expect(textToSpeech.stopCallCount, 1);
  });

  test('speak() is a no-op when speakRepliesEnabled is off', () async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await controller.speak('hello');

    expect(textToSpeech.spoken, isEmpty);
  });

  test('speak() speaks and toggles isSpeaking when enabled', () async {
    final controller = buildController();
    addTearDown(controller.dispose);
    controller.setSpeakRepliesEnabled(true);

    final future = controller.speak('nice work today');
    expect(controller.state.isSpeaking, isTrue);
    await future;

    expect(controller.state.isSpeaking, isFalse);
    expect(textToSpeech.spoken, ['nice work today']);
  });
}
