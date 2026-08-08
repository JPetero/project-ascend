/// A provider-issued identity obtained from a native Google/Apple sign-in
/// flow (Build Session 10 Parts 9/10), ready to hand to the backend's
/// GoogleTokenVerifier/AppleTokenVerifier — never anything the backend
/// didn't ask for, never a password or secret.
class SocialIdentity {
  const SocialIdentity({required this.idToken, this.firstName});

  /// The raw provider-issued ID token (a JWT). Verified server-side —
  /// never trusted or decoded on-device.
  final String idToken;

  /// Only ever set by Apple, and only on the very first authorization
  /// between this app and the user's Apple ID — Apple never repeats it
  /// on later sign-ins.
  final String? firstName;
}
