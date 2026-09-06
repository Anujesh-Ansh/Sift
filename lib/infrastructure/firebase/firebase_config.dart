import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/logging/app_logger.dart';

/// Centralized Firebase initialization and emulator connector.
class FirebaseConfig {
  static const _logger = AppLogger('FirebaseConfig');
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Initializes Firebase and optionally connects to local emulators.
  static Future<void> initialize({
    bool useEmulators = false,
    String emulatorHost = 'localhost',
  }) async {
    if (_initialized) return;

    try {
      // In development / sandbox, if no google-services is provided, initialize with fallback options
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'mock-api-key-for-emulator-or-sandbox',
            appId: '1:100000000000:android:mockappid',
            messagingSenderId: '100000000000',
            projectId: 'project-sift-sandbox',
            storageBucket: 'project-sift-sandbox.appspot.com',
          ),
        );
      }

      if (useEmulators) {
        _logger.i(
            'Connecting Firebase services to local emulators at $emulatorHost...');
        // Emulators
        FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
        FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
      }

      _initialized = true;
      _logger.i('Firebase initialized successfully.');
    } catch (e, st) {
      _logger.w('Firebase initialization handled: $e', e, st);
    }
  }
}
