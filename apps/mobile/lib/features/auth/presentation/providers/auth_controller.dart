import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final bool isSubmitting;

  AuthState copyWith({AuthStatus? status, AuthUser? user, bool? isSubmitting}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required SecureTokenStorage tokenStorage,
    required AppDatabase database,
  }) : _repository = repository,
       _tokenStorage = tokenStorage,
       _database = database,
       super(const AuthState()) {
    _bootstrap();
  }

  final AuthRepository _repository;
  final SecureTokenStorage _tokenStorage;
  final AppDatabase _database;

  Future<void> _bootstrap() async {
    final hasSession = await _tokenStorage.hasSession();
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _repository.me();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _tokenStorage.clear();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> register({
    required String firstName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final user = await _repository.register(
        firstName: firstName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        acceptedTerms: acceptedTerms,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    await _database.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called when [ApiClient] reports a failed token refresh.
  Future<void> handleSessionExpired() async {
    if (state.status != AuthStatus.authenticated) return;
    await _tokenStorage.clear();
    await _database.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final controller = AuthController(
      repository: ref.watch(authRepositoryProvider),
      tokenStorage: ref.watch(secureTokenStorageProvider),
      database: ref.watch(appDatabaseProvider),
    );

    ref.listen<int>(sessionExpiredNotifierProvider, (previous, next) {
      if (previous != null && next != previous) {
        controller.handleSessionExpired();
      }
    });

    return controller;
  },
);
