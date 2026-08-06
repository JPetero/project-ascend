import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/auth_identity_repository.dart';
import '../../domain/auth_identity.dart';

final authIdentityRepositoryProvider = Provider<AuthIdentityRepository>((ref) {
  return AuthIdentityRepository(apiClient: ref.watch(apiClientProvider));
});

final authIdentitiesProvider = FutureProvider.autoDispose<List<AuthIdentity>>((
  ref,
) {
  return ref.watch(authIdentityRepositoryProvider).listMine();
});
