# Project Sift — Local Development Guide

Welcome to the development guide for **Project Sift**. This document provides detailed setup instructions, toolchain prerequisites, code style rules, testing workflows, and debugging tips.

---

## 🛠️ Toolchain Prerequisites

Ensure your workstation meets the following minimum requirements:

- **Flutter SDK**: `3.26.0` or newer (Recommended: `3.47.2`)
  ```bash
  flutter --version
  ```
- **Dart SDK**: `3.6.0` or newer (Recommended: `3.7.2`)
- **Android Studio / Command Line Tools**:
  - Android SDK Platform 34 (Android 14)
  - Android Build Tools 34.0.0+
  - Android Gradle Plugin (AGP) 8.11+
  - Gradle 8.14+
- **Xcode** (for macOS/iOS developers):
  - Xcode 15+
  - CocoaPods 1.14+
- **Firebase CLI**:
  ```bash
  npm install -g firebase-tools
  firebase --version
  ```

---

## 🚀 Repository Setup

### 1. Clone & Fetch Dependencies
```bash
git clone https://github.com/Anujesh-Ansh/Sift.git
cd Sift
flutter pub get
```

### 2. Configure Firebase
Project Sift requires Firebase Authentication, Cloud Firestore, and Firebase Cloud Storage.

1. Create a Firebase Project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Anonymous Authentication** (or Email/Password) in Firebase Authentication.
3. Create a **Cloud Firestore** database (test mode or production mode with rules).
4. Create a **Cloud Storage** bucket.
5. Add Android and/or iOS apps in the Firebase console:
   - Android package: `com.example.project_sift` (or your configured application ID).
   - Download `google-services.json` and save to `android/app/google-services.json`.
   - Download `GoogleService-Info.plist` and save to `ios/Runner/GoogleService-Info.plist`.
6. Deploy local security rules and indexes:
   ```bash
   firebase login
   firebase use <your-project-id>
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

### 3. Gemini API Key Configuration
Get an API key from [Google AI Studio](https://aistudio.google.com/).

You have two ways to provide the API key:
- **Option A (In-App Settings)**: Launch the app, navigate to **Settings**, and paste your API key into the Gemini API Key field. It will be stored securely in `SharedPreferences`.
- **Option B (Compile-time / Launch flag)**: Pass `--dart-define`:
  ```bash
  flutter run --dart-define=GEMINI_API_KEY="AIzaSyYourActualKeyHere"
  ```

---

## 🧪 Testing Suites

Project Sift emphasizes test-driven resilience across all layers.

### Run All Tests
```bash
flutter test
```

### Run Performance Benchmarks Only
```bash
flutter test test/performance/large_library_stress_test.dart
```

### Run Specific Test Groups
```bash
# AI response parser & JSON repair tests
flutter test test/unit/ai_response_parser_test.dart

# 15-category classification taxonomy tests
flutter test test/unit/category_classifier_test.dart

# Device-to-cloud deletion reconciliation tests
flutter test test/unit/deletion_reconciliation_test.dart

# Background sync & Workmanager tests
flutter test test/unit/background_sync_test.dart

# UI widget tests
flutter test test/widget/screenshot_card_test.dart
flutter test test/widget/review_queue_test.dart
```

### Static Analysis & Formatting
Before committing any changes, you must verify code cleanliness:
```bash
# Format code
dart format .

# Check for warnings or lint violations
flutter analyze
```

---

## 🏗️ Architecture & Conventions

### 1. State Management (Riverpod)
- We use **Riverpod 2.x** with declarative, immutable providers.
- Feature-level controllers extend `StateNotifier` or `AutoDisposeNotifier`.
- Presentation widgets extend `ConsumerWidget` or `ConsumerStatefulWidget`.
- Never store mutable global variables outside of Riverpod provider state.

### 2. Error Handling & Logging
- Use the structured logger: `AppLogger.info()`, `AppLogger.warn()`, `AppLogger.error()`.
- Never use raw `print()` statements in production code.
- Always catch domain exceptions using typed `DomainException` subclasses from `lib/core/errors/`.

### 3. Git Commit Conventions
Per project policy:
- Keep commits **focused, atomic, and small**.
- Follow conventional commits with a touch of character:
  - `feat(scope): ... 🚀`
  - `fix(scope): ... 🐛`
  - `test(scope): ... 🧪`
  - `docs(scope): ... 📚`
  - `refactor(scope): ... 🧹`

---

## 📱 Platform Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
- `READ_MEDIA_IMAGES` (API 33+)
- `READ_EXTERNAL_STORAGE` (API <= 32)
- `INTERNET`
- `WAKE_LOCK` / `RECEIVE_BOOT_COMPLETED` (for Workmanager background tasks)

### iOS (`ios/Runner/Info.plist`)
- `NSPhotoLibraryUsageDescription`: "Project Sift requires photo library access to index and categorize your screenshots."
- `UIBackgroundModes`: `fetch`, `processing`

---

## 🐞 Troubleshooting

| Issue | Solution |
| :--- | :--- |
| `MissingPluginException` on mobile features during `flutter test` | Widget and unit tests mock native channel interactions or test domain logic in isolation. Ensure `TestWidgetsFlutterBinding.ensureInitialized()` is called. |
| Gemini API error: `API_KEY_INVALID` or 403 | Verify your Gemini API key in Google AI Studio and ensure it is entered without trailing spaces in Settings or `--dart-define`. |
| Firebase `permission-denied` in Firestore/Storage | Ensure the user is authenticated via `FirebaseAuth` and that `firestore.rules` and `storage.rules` are deployed. |
| Background tasks not running on Android | Android battery optimization can defer background jobs. In device settings, disable battery optimization for Sift or trigger foreground sync via `syncNow()`. |
