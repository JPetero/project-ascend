class AuthUser {
  const AuthUser({required this.id, required this.email, this.emailVerifiedAt});

  final String id;
  final String email;
  // Null until the user confirms an email-verification link (Build
  // Session 9 Part 4).
  final DateTime? emailVerifiedAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.parse(json['emailVerifiedAt'] as String)
          : null,
    );
  }
}
