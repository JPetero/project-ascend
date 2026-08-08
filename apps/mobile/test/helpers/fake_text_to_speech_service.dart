import 'package:mobile/core/voice/text_to_speech_service.dart';

/// In-memory stand-in for [TextToSpeechService].
class FakeTextToSpeechService implements TextToSpeechService {
  final List<String> spoken = [];
  int stopCallCount = 0;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
  }
}
