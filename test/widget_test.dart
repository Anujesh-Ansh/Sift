import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/app/app.dart';
import 'package:project_sift/features/auth/data/firebase_auth_repository.dart';
import 'package:project_sift/features/auth/domain/auth_user.dart';
import 'package:project_sift/features/auth/providers/auth_provider.dart';

import 'package:project_sift/features/screenshots/domain/entities/screenshot_item.dart';
import 'package:project_sift/features/screenshots/providers/screenshot_providers.dart';

class FakeAuthRepository implements AuthRepository {
  final _user = const AuthUser(id: 'test_user_123', email: 'test@sift.app');

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_user);

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> signInAnonymously() async => _user;

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('ProjectSiftApp renders HomeScreen with Project Sift branding',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          screenshotsStreamProvider
              .overrideWith((ref) => Stream.value(<ScreenshotItem>[])),
          reviewQueueStreamProvider
              .overrideWith((ref) => Stream.value(<ScreenshotItem>[])),
        ],
        child: const ProjectSiftApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Project Sift'), findsOneWidget);
    expect(find.text('No Screenshots Found'), findsOneWidget);
  });
}
