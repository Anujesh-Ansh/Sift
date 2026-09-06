import '../entities/processing_status.dart';
import '../entities/screenshot_item.dart';

/// Contract defining screenshot storage and querying operations in Firestore.
abstract class ScreenshotRepository {
  /// Watches the user's screenshots with optional category and review status filters.
  Stream<List<ScreenshotItem>> watchScreenshots({
    String? category,
    ReviewStatus? reviewStatus,
    int limit = 100,
  });

  /// Watches screenshots flagged with needs_human_context == true for the review queue.
  Stream<List<ScreenshotItem>> watchReviewQueue({int limit = 50});

  /// Fetches a single screenshot by its document ID.
  Future<ScreenshotItem?> getScreenshot(String id);

  /// Saves or updates a screenshot item in Firestore.
  Future<void> saveScreenshot(ScreenshotItem item);

  /// Updates triage/review decision for a screenshot.
  Future<void> updateReviewStatus(
    String id, {
    required ReviewStatus status,
    String? correctedCategory,
    List<String>? tags,
    String? note,
  });

  /// Permanently deletes a screenshot document from Firestore.
  Future<void> deleteScreenshot(String id);

  /// Retrieves all source asset IDs currently indexed for the user (used for delta sync).
  Future<Set<String>> getIndexedAssetIds();
}
