import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
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

  static const _maxBootstrapAttempts = 3;

  Future<void> _bootstrap() async {
    final hasSession = await _tokenStorage.hasSession();
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    for (var attempt = 1; attempt <= _maxBootstrapAttempts; attempt++) {
      try {
        final user = await _repository.me();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return;
      } on AppException catch (error) {
        final isLastAttempt = attempt == _maxBootstrapAttempts;
        // Only a confirmed-invalid token (401) or exhausting our retries
        // ends the session. A transient network error alone must never
        // wipe out an otherwise-valid refresh token — that would silently
        // sign a user out just because their connection blipped at
        // startup.
        if (error.code == 'UNAUTHORIZED') {
          await _tokenStorage.clear();
        }
        if (error.code != 'NETWORK_ERROR' || isLastAttempt) {
          state = state.copyWith(status: AuthStatus.unauthenticated);
          return;
        }
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      } catch (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
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

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repository.forgotPassword(email);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repository.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> resendVerification() async {
    await _repository.resendVerification();
  }

  /// Revokes every session, including this device's — the server-side
  /// effect signs this device out too, so treat it exactly like [logout].
  Future<void> signOutEverywhere() async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repository.logoutAllSessions();
      await _database.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  /// Closes the account and signs out locally. Rethrows on failure (e.g.
  /// an incorrect password) so the caller can show the error — the local
  /// session must stay intact until the server confirms deletion.
  Future<void> deleteAccount(String password) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repository.deleteAccount(password);
      await _database.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
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
