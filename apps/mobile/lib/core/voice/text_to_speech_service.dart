import 'package:flutter_tts/flutter_tts.dart' as tts;

/// On-device speech synthesis for Atlas/Nova "speak replies aloud" (Build
/// Session 9 Part 14) — an interface so tests can supply a fake instead
/// of depending on a real platform TTS engine.
abstract class TextToSpeechService {
  Future<void> speak(String text);

  Future<void> stop();
}

/// Wraps `package:flutter_tts`. Speech is synthesized entirely on-device
/// by the OS's own TTS engine — no text is ever sent to Ascend's own
/// servers for this. Not verifiable from an automated test run in this
/// environment; see build-session-9.md's disclosed physical-device-
/// testing gap.
class PluginTextToSpeechService implements TextToSpeechService {
  final _tts = tts.FlutterTts();
  bool _awaitCompletionConfigured = false;

  @override
  Future<void> speak(String text) async {
    // Without this, flutter_tts's speak() future resolves as soon as
    // playback is *requested*, not when it finishes — the caller
    // (CompanionVoiceController.speak) would flip `isSpeaking` back to
    // false while the device is still talking, hiding the Stop button
    // mid-speech. Only needs to be set once per engine instance.
    if (!_awaitCompletionConfigured) {
      await _tts.awaitSpeakCompletion(true);
      _awaitCompletionConfigured = true;
    }
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
