import 'package:mobile/core/networking/api_client.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/feature_flags/data/feature_flags_repository.dart';

class FakeFeatureFlagsRepository extends FeatureFlagsRepository {
  FakeFeatureFlagsRepository({Map<String, bool> flags = const {}})
    : flags = Map.of(flags),
      super(apiClient: _unusedApiClient());

  final Map<String, bool> flags;

  @override
  Future<Map<String, bool>> resolve() async => Map.unmodifiable(flags);
}

ApiClient _unusedApiClient() {
  return ApiClient(tokenStorage: SecureTokenStorage());
}
