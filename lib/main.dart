import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'infrastructure/firebase/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely handles local emulators / fallback configuration)
  await FirebaseConfig.initialize(
    useEmulators: false,
  );

  runApp(
    const ProviderScope(
      child: ProjectSiftApp(),
    ),
  );
}
