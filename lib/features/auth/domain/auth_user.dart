/// Simplified domain representation of an authenticated user.
class AuthUser {
  final String id;
  final String? email;
  final bool isAnonymous;

  const AuthUser({
    required this.id,
    this.email,
    this.isAnonymous = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
