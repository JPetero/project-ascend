import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/features/auth/data/social_auth/apple_auth_provider.dart';
import 'package:mobile/features/auth/data/social_auth/google_auth_provider.dart';
import 'package:mobile/features/auth/data/social_auth/social_identity.dart';

/// In-memory test double for [GoogleAuthProvider] — never touches the
/// real `google_sign_in` plugin, so widget tests can drive every outcome
/// (success, cancellation, failure) deterministically.
class FakeGoogleAuthProvider implements GoogleAuthProvider {
  SocialIdentity? nextResult = const SocialIdentity(
    idToken: 'fake-google-id-token',
  );
  AppException? nextError;
  bool signInCalled = false;

  @override
  Future<SocialIdentity?> signIn() async {
    signInCalled = true;
    if (nextError != null) throw nextError!;
    return nextResult;
  }
}

/// In-memory test double for [AppleAuthProvider].
class FakeAppleAuthProvider implements AppleAuthProvider {
  bool available = true;
  SocialIdentity? nextResult = const SocialIdentity(
    idToken: 'fake-apple-id-token',
    firstName: 'Ada',
  );
  AppException? nextError;
  bool signInCalled = false;

  @override
  bool get isAvailable => available;

  @override
  Future<SocialIdentity?> signIn() async {
    signInCalled = true;
    if (nextError != null) throw nextError!;
    return nextResult;
  }
}
