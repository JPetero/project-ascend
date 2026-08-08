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

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
