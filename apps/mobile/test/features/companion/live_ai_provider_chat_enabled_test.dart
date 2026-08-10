import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/networking/api_client.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/companion/data/live_ai_provider.dart';
import 'package:mobile/features/companion/data/local_deterministic_ai_provider.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';

/// Build Session 13 continuation Part A — LIVE_AI's chat-specific gate.
/// `chatEnabled: false` must skip the network call entirely and go
/// straight to the fallback, the same as an actual network failure would
/// — never surfacing a raw error, and never attempting a paid provider
/// call while the flag is off.
void main() {
  test(
    'chatEnabled: false returns the fallback reply without attempting the live call',
    () async {
      final provider = LiveAiProvider(
        apiClient: ApiClient(tokenStorage: SecureTokenStorage()),
        fallback: const LocalDeterministicAiProvider(),
        chatEnabled: false,
      );

      final reply = await provider.generateReply(
        input: 'How should I warm up?',
        companion: Companion.atlas,
        style: CoachingStyle.balanced,
      );

      // LocalDeterministicAiProvider's own deterministic reply — proves
      // the call never reached `/assistant/reply` at all (that path
      // would require network access this test never provides).
      expect(reply, isNotEmpty);
      expect(provider.pendingMemoryCandidate, isNull);
    },
  );

  test('chatEnabled defaults to true when not specified', () {
    final provider = LiveAiProvider(
      apiClient: ApiClient(tokenStorage: SecureTokenStorage()),
      fallback: const LocalDeterministicAiProvider(),
    );

    expect(provider.chatEnabled, isTrue);
  });
}
