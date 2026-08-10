import 'package:mobile/core/networking/api_client.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/feature_flags/data/feature_flags_repository.dart';

class FakeFeatureFlagsRepository extends FeatureFlagsRepository {
  FakeFeatureFlagsRepository({
    Map<String, bool> flags = const {},
    this.throwOnResolve = false,
  }) : flags = Map.of(flags),
       super(apiClient: _unusedApiClient());

  final Map<String, bool> flags;

  /// Simulates the `/feature-flags` request failing (API outage) —
  /// Build Session 13 Part 1.
  final bool throwOnResolve;

  @override
  Future<Map<String, bool>> resolve() async {
    if (throwOnResolve) {
      throw Exception('simulated feature-flags outage');
    }
    return Map.unmodifiable(flags);
  }
}

ApiClient _unusedApiClient() {
  return ApiClient(tokenStorage: SecureTokenStorage());
}
