import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthUser> signInAnonymously();
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  static const _logger = AppLogger('FirebaseAuthRepository');

  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth
        .authStateChanges()
        .map((user) => user != null ? _mapFirebaseUser(user) : null);
  }

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    return user != null ? _mapFirebaseUser(user) : null;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
            'Anonymous sign in succeeded but user was null');
      }
      _logger.i('User signed in anonymously: ${user.uid}');
      return _mapFirebaseUser(user);
    } catch (e, st) {
      _logger.e('Failed to sign in anonymously', e, st);
      throw AuthFailure('Failed to sign in anonymously', e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  AuthUser _mapFirebaseUser(User user) {
    return AuthUser(
      id: user.uid,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }
}
