/// Canonical taxonomy of screenshot categories for Project Sift.
class CategoryClassifier {
  CategoryClassifier._();

  /// Canonical list of broad categories defined in the Architecture Blueprint.
  static const List<String> canonicalCategories = [
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
    'Delete',
  ];

  static const String fallbackCategory = 'Other';
  static const String deleteCategory = 'Delete';

  /// Normalizes a raw category string from AI output or user input.
  /// Matches case-insensitively against custom categories, canonical categories, and mapped synonyms.
  static String normalize(String? rawCategory, [List<String>? customCategories]) {
    if (rawCategory == null || rawCategory.trim().isEmpty) {
      return fallbackCategory;
    }

    final trimmed = rawCategory.trim();

    // 1. Check custom categories first
    if (customCategories != null) {
      for (final custom in customCategories) {
        if (custom.toLowerCase() == trimmed.toLowerCase()) {
          return custom;
        }
      }
    }

    // 2. Check canonical categories
    for (final canonical in canonicalCategories) {
      if (canonical.toLowerCase() == trimmed.toLowerCase()) {
        return canonical;
      }
    }

    // Secondary semantic mapping for common synonyms
    final lower = trimmed.toLowerCase();
    if (lower.contains('bank') ||
        lower.contains('receipt') ||
        lower.contains('invoice') ||
        lower.contains('crypto') ||
        lower.contains('payment')) {
      return 'Finance';
    }
    if (lower.contains('shop') ||
        lower.contains('store') ||
        lower.contains('cart') ||
        lower.contains('product')) {
      return 'Shopping';
    }
    if (lower.contains('chat') ||
        lower.contains('message') ||
        lower.contains('sms') ||
        lower.contains('whatsapp') ||
        lower.contains('telegram')) {
      return 'Communication';
    }
    if (lower.contains('code') ||
        lower.contains('dev') ||
        lower.contains('software') ||
        lower.contains('github') ||
        lower.contains('tech')) {
      return 'Technology';
    }
    if (lower.contains('recipe') ||
        lower.contains('restaurant') ||
        lower.contains('meal')) {
      return 'Food';
    }
    if (lower.contains('flight') ||
        lower.contains('hotel') ||
        lower.contains('trip')) {
      return 'Travel';
    }
    if (lower.contains('insta') ||
        lower.contains('twitter') ||
        lower.contains('reddit') ||
        lower.contains('post')) {
      return 'Social';
    }
    if (lower.contains('pdf') ||
        lower.contains('form') ||
        lower.contains('scan')) {
      return 'Documents';
    }
    if (lower.contains('study') ||
        lower.contains('course') ||
        lower.contains('lecture') ||
        lower.contains('book')) {
      return 'Education';
    }
    if (lower.contains('art') ||
        lower.contains('wallpaper') ||
        lower.contains('design') ||
        lower.contains('fashion')) {
      return 'Aesthetic';
    }
    if (lower.contains('trash') ||
        lower.contains('delete') ||
        lower.contains('junk') ||
        lower.contains('remove') ||
        lower.contains('disposable') ||
        lower.contains('temporary')) {
      return deleteCategory;
    }

    return fallbackCategory;
  }

  /// Whether the given category is a recognized canonical category (excluding 'Other').
  static bool isRecognized(String? category) {
    if (category == null) return false;
    final normalized = normalize(category);
    return normalized != fallbackCategory;
  }
}
