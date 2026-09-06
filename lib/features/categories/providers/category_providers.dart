import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config_service.dart';
import '../../../infrastructure/ai/category_classifier.dart';

/// StateNotifier that manages user-defined custom categories with disk persistence.
class CategoryNotifier extends StateNotifier<List<String>> {
  CategoryNotifier() : super(const []) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final custom = await AppConfigService.getCustomCategories();
    if (custom.isNotEmpty) {
      state = custom;
    }
  }

  /// Adds a new custom category.
  /// Returns null on success or an error message if invalid or duplicate.
  Future<String?> addCategory(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      return 'Category name cannot be empty.';
    }

    final lower = name.toLowerCase();

    // Check if canonical
    final isCanonical = CategoryClassifier.canonicalCategories
        .any((c) => c.toLowerCase() == lower);
    if (isCanonical) {
      return 'Category "$name" already exists as a system category.';
    }

    // Check if already in custom
    final alreadyExists = state.any((c) => c.toLowerCase() == lower);
    if (alreadyExists) {
      return 'Category "$name" already exists.';
    }

    final updated = [...state, name];
    state = updated;
    await AppConfigService.saveCustomCategories(updated);
    return null;
  }

  /// Removes a custom category.
  Future<void> removeCategory(String name) async {
    final updated = state.where((c) => c != name).toList();
    state = updated;
    await AppConfigService.saveCustomCategories(updated);
  }
}

/// Provider for user-defined custom categories.
final customCategoriesProvider =
    StateNotifierProvider<CategoryNotifier, List<String>>((ref) {
  return CategoryNotifier();
});

/// Provider for all available categories (canonical + custom), ordered logically.
final allCategoriesProvider = Provider<List<String>>((ref) {
  final custom = ref.watch(customCategoriesProvider);

  // List canonical without 'Other' and 'Delete'
  final base = CategoryClassifier.canonicalCategories
      .where((c) => c != 'Other' && c != 'Delete')
      .toList();

  return [
    ...base,
    ...custom,
    CategoryClassifier.fallbackCategory, // Other
    CategoryClassifier.deleteCategory,   // Delete
  ];
});
