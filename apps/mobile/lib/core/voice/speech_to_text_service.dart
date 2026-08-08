import 'package:speech_to_text/speech_to_text.dart' as stt;

enum SpeechAvailability { available, unavailable }

/// On-device speech recognition for Atlas/Nova voice input (Build
/// Session 9 Part 14) — an interface (not just a class) so tests can
/// supply a fake instead of depending on a real platform speech plugin,
/// same reasoning as `LiveLocationService`/`LocalNotificationSchedulingService`.
abstract class SpeechToTextService {
  /// Requests the OS speech-recognition/microphone permission and checks
  /// device support — only ever called from [CompanionVoiceController]
  /// in direct response to the user tapping the mic button, never at app
  /// launch or automatically (see atlas-nova-bible.md's "no
  /// always-listening behavior by default" rule).
  Future<SpeechAvailability> initialize();

  /// Starts listening; [onResult] is called every time the recognized
  /// text updates, with [isFinal] true once the platform is confident
  /// this is the complete utterance for this listening session.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
  });

  Future<void> stopListening();

  bool get isListening;
}

/// Wraps `package:speech_to_text`. All recognition happens on-device —
/// no audio is ever sent to Ascend's own servers. This plugin's actual
/// device behavior (microphone access, real transcription accuracy) is
/// not verifiable from an automated test run in this environment; see
/// build-session-9.md's disclosed physical-device-testing gap.
class PluginSpeechToTextService implements SpeechToTextService {
  final _speech = stt.SpeechToText();

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<SpeechAvailability> initialize() async {
    final available = await _speech.initialize();
    return available
        ? SpeechAvailability.available
        : SpeechAvailability.unavailable;
  }

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) {
    return _speech.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
    );
  }

  @override
  Future<void> stopListening() => _speech.stop();
}
