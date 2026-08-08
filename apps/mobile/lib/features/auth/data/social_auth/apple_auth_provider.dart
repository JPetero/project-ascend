import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/errors/app_exception.dart';
import 'social_identity.dart';

abstract class AppleAuthProvider {
  /// Whether the native Sign in with Apple flow should be offered on this
  /// platform. Android/web support exists in the plugin only via a web
  /// redirect flow (`webAuthenticationOptions`), which needs an Apple
  /// Services ID and redirect URI this app has no Apple Developer account
  /// to provision — so those platforms simply don't show the button
  /// rather than showing one that can never work.
  bool get isAvailable;

  Future<SocialIdentity?> signIn();
}

/// Wraps the real `sign_in_with_apple` plugin (Build Session 10 Part 10).
class SignInWithAppleAuthProvider implements AppleAuthProvider {
  @override
  bool get isAvailable => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Future<SocialIdentity?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AppException(
          message: 'Apple did not return a sign-in token. Please try again.',
          code: 'UNKNOWN',
        );
      }
      return SocialIdentity(idToken: idToken, firstName: credential.givenName);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      throw AppException(message: error.message, code: 'UNKNOWN');
    } on SignInWithAppleException catch (error) {
      throw AppException(message: error.toString(), code: 'UNKNOWN');
    }
  }
}
