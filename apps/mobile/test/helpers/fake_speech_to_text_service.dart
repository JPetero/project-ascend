import 'package:mobile/core/voice/speech_to_text_service.dart';

/// In-memory stand-in for [SpeechToTextService] — tests drive recognition
/// results via [emitResult] instead of a real platform speech plugin.
class FakeSpeechToTextService implements SpeechToTextService {
  FakeSpeechToTextService({this.availability = SpeechAvailability.available});

  SpeechAvailability availability;
  bool _isListening = false;
  void Function(String text, bool isFinal)? _onResult;
  void Function()? _onListeningEnded;

  int initializeCallCount = 0;
  int startListeningCallCount = 0;
  int stopListeningCallCount = 0;

  @override
  bool get isListening => _isListening;

  @override
  Future<SpeechAvailability> initialize({
    void Function()? onListeningEnded,
  }) async {
    initializeCallCount++;
    _onListeningEnded = onListeningEnded;
    return availability;
  }

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    startListeningCallCount++;
    _isListening = true;
    _onResult = onResult;
  }

  @override
  Future<void> stopListening() async {
    stopListeningCallCount++;
    _isListening = false;
  }

  /// Test hook — push a recognition update as if the OS speech engine
  /// reported it.
  void emitResult(String text, {required bool isFinal}) {
    if (isFinal) _isListening = false;
    _onResult?.call(text, isFinal);
  }

  /// Test hook — simulate the platform silently ending the listening
  /// session (timeout, no speech detected, a mid-session error) without
  /// ever delivering a final result.
  void simulateListeningEndedWithoutResult() {
    _isListening = false;
    _onListeningEnded?.call();
  }
}
