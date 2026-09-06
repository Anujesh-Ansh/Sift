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
      // Initialize Firebase with native configuration (from google-services.json)
      // or fallback to real project options
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
          _logger.i('Native Firebase initialized successfully with google-services.json');
        } catch (nativeErr) {
          _logger.w('Native Firebase init failed ($nativeErr), using project options fallback.');
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: 'AIzaSyBa2enJuztZVHQUFm2I-nrtNFGbmVHKDDc',
              appId: '1:602817670221:android:49f3ab302c48c60a00c004',
              messagingSenderId: '602817670221',
              projectId: 'gen-lang-client-0460033455',
              storageBucket: 'gen-lang-client-0460033455.firebasestorage.app',
            ),
          );
        }
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
