import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import 'social_identity.dart';

abstract class GoogleAuthProvider {
  Future<SocialIdentity?> signIn();
}

/// Wraps the real `google_sign_in` plugin (Build Session 10 Part 9).
///
/// Requires a real Google Cloud OAuth client id, supplied via
/// `--dart-define=GOOGLE_CLIENT_ID=...` (see [AppConfig]) — this
/// repository has no such client provisioned, so without that define the
/// plugin itself fails with a real, honest [GoogleSignInException]
/// rather than anything faked here.
class GoogleSignInAuthProvider implements GoogleAuthProvider {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: AppConfig.googleClientId.isEmpty
          ? null
          : AppConfig.googleClientId,
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
    );
    _initialized = true;
  }

  @override
  Future<SocialIdentity?> signIn() async {
    await _ensureInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AppException(
        message: 'Google sign-in is not supported on this device.',
        code: 'UNKNOWN',
      );
    }

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AppException(
          message: 'Google did not return a sign-in token. Please try again.',
          code: 'UNKNOWN',
        );
      }
      return SocialIdentity(idToken: idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw AppException(
        message:
            error.description ?? 'Google sign-in failed. Please try again.',
        code: 'UNKNOWN',
      );
    }
  }
}
