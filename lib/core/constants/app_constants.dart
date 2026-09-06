/// Global application constants and taxonomies for Project Sift.
class AppConstants {
  AppConstants._();

  static const String appName = 'Project Sift';
  static const int schemaVersion = 1;
  static const String defaultGeminiModel = 'gemini-1.5-flash';

  // Target image compression constraints
  static const int maxImageDimension = 1024;
  static const int imageJpegQuality = 60;
  static const int thumbnailDimension = 250;
  static const int thumbnailJpegQuality = 70;

  // Background sync configuration
  static const String backgroundSyncTaskName = 'com.sift.app.periodic_sync';
  static const int backgroundSyncFrequencyHours = 6;

  // Bounded concurrency
  static const int maxConcurrentCompression = 2;
  static const int maxConcurrentUploadAndAnalysis = 2;

  // Predefined broad categories for Gemini classification
  static const List<String> primaryCategories = [
    'Finance',
    'Shopping',
    'Work',
    'Communication',
    'Travel',
    'Food',
    'Entertainment',
    'Education',
    'Technology',
    'Health',
    'Documents',
    'Social',
    'Reference',
    'Aesthetic',
    'Other',
  ];
}
