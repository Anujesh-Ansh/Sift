import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_user.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Stream provider for user authentication state changes
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Provider for the current user's ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value?.id;
});
