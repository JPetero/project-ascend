import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/networking/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../domain/auth_user.dart';
import '../domain/device_session.dart';
import '../domain/token_pair.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureTokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  /// Freeform label sent with login/register so "Your devices" (Build
  /// Session 10 Part 11) can show a sensible icon — purely informational,
  /// never used for any security decision.
  String? get _currentPlatform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  Future<AuthUser> register({
    required String firstName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) async {
    final envelope = await _apiClient.post(
      '/auth/register',
      (data) => data as Map<String, dynamic>,
      data: {
        'firstName': firstName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'acceptedTerms': acceptedTerms,
        'platform': _currentPlatform,
      },
    );

    return _persistSessionAndReturnUser(envelope.data!);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final envelope = await _apiClient.post(
      '/auth/login',
      (data) => data as Map<String, dynamic>,
      data: {
        'email': email,
        'password': password,
        'platform': _currentPlatform,
      },
    );

    return _persistSessionAndReturnUser(envelope.data!);
  }

  Future<AuthUser> me() async {
    final envelope = await _apiClient.get(
      '/auth/me',
      (data) => data as Map<String, dynamic>,
    );
    return AuthUser.fromJson(envelope.data!);
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      '/auth/forgot-password',
      (data) => data,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _apiClient.post(
      '/auth/reset-password',
      (data) => data,
      data: {
        'token': token,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _apiClient.post(
      '/auth/change-password',
      (data) => data,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  Future<void> verifyEmail(String token) async {
    await _apiClient.post(
      '/auth/verify-email',
      (data) => data,
      data: {'token': token},
    );
  }

  Future<void> resendVerification() async {
    await _apiClient.post('/auth/resend-verification', (data) => data);
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _apiClient.post(
          '/auth/logout',
          (data) => data,
          data: {'refreshToken': refreshToken},
        );
      } catch (_) {
        // Logout is best-effort server-side; the local session is always cleared.
      }
    }
    await _tokenStorage.clear();
  }

  /// Revokes every refresh token for this account, including this
  /// device's — the server-side effect ends every session at once, so
  /// the caller must treat this exactly like [logout] locally too.
  Future<void> logoutAllSessions() async {
    await _apiClient.post('/auth/logout-all', (data) => data);
    await _tokenStorage.clear();
  }

  /// "Your devices" (Build Session 10 Part 11) — every active session,
  /// including this one (see [DeviceSession.current]).
  Future<List<DeviceSession>> getSessions() async {
    final envelope = await _apiClient.get(
      '/auth/sessions',
      (data) => (data as List<dynamic>)
          .map((item) => DeviceSession.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return envelope.data!;
  }

  /// Signs out one specific device. May target this device itself — the
  /// caller (see [DeviceSessionsController.revoke]) is responsible for
  /// clearing local tokens and warning the user first when that's the
  /// case, since the server allows it without complaint.
  Future<void> revokeSession(String familyId) async {
    await _apiClient.delete('/auth/sessions/$familyId', (data) => data);
  }

  /// Signs out every device except this one. Returns how many were
  /// revoked so the UI can confirm what just happened.
  Future<int> revokeOtherSessions() async {
    final envelope = await _apiClient.delete(
      '/auth/sessions/others',
      (data) => data as Map<String, dynamic>,
    );
    return envelope.data!['revokedCount'] as int;
  }

  Future<void> deleteAccount(String password) async {
    await _apiClient.delete(
      '/auth/account',
      (data) => data,
      data: {'password': password},
    );
    await _tokenStorage.clear();
  }

  Future<AuthUser> _persistSessionAndReturnUser(
    Map<String, dynamic> payload,
  ) async {
    final tokens = TokenPair.fromJson(
      payload['tokens'] as Map<String, dynamic>,
    );
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return AuthUser.fromJson(payload['user'] as Map<String, dynamic>);
  }
}
