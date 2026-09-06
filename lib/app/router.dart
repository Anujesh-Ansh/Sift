import 'package:flutter/material.dart';
import '../features/review/presentation/screens/review_queue_screen.dart';
import '../features/screenshots/presentation/screens/home_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String review = '/review';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case review:
        return MaterialPageRoute(
          builder: (_) => const ReviewQueueScreen(),
          settings: settings,
        );
      case AppRouter.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
