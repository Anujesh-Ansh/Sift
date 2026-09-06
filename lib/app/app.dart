import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/providers/auth_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class ProjectSiftApp extends ConsumerStatefulWidget {
  const ProjectSiftApp({super.key});

  @override
  ConsumerState<ProjectSiftApp> createState() => _ProjectSiftAppState();
}

class _ProjectSiftAppState extends ConsumerState<ProjectSiftApp> {
  @override
  void initState() {
    super.initState();
    // Auto-authenticate anonymous user if not yet signed in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authRepo = ref.read(authRepositoryProvider);
      if (authRepo.currentUser == null) {
        authRepo.signInAnonymously().ignore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.home,
    );
  }
}
