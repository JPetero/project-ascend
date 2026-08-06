/// One sign-in provider linked to the current Ascend account — the
/// Flutter-side read model for Scenario 2/3 (see
/// packages/docs/product/user-scenario-bible.md). Every account has at
/// least an EMAIL row; Google/Apple rows appear once linking is live.
class AuthIdentity {
  const AuthIdentity({
    required this.provider,
    required this.providerEmail,
    required this.createdAt,
  });

  final String provider;
  final String? providerEmail;
  final DateTime createdAt;

  factory AuthIdentity.fromJson(Map<String, dynamic> json) {
    return AuthIdentity(
      provider: json['provider'] as String,
      providerEmail: json['providerEmail'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
