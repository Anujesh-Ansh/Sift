import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'infrastructure/background/background_sync_service.dart';
import 'infrastructure/firebase/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely handles local emulators / fallback configuration)
  await FirebaseConfig.initialize(
    useEmulators: false,
  );

  // Initialize WorkManager background periodic synchronization
  final backgroundSync = BackgroundSyncService();
  await backgroundSync.initialize();
  await backgroundSync.schedulePeriodicSync();

  runApp(
    const ProviderScope(
      child: ProjectSiftApp(),
    ),
  );
}
