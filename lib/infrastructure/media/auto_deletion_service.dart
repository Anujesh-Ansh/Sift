import '../../core/logging/app_logger.dart';
import '../../features/screenshots/domain/entities/screenshot_item.dart';
import '../../features/screenshots/domain/repositories/screenshot_repository.dart';
import 'deduplication_service.dart';
import 'screenshot_source.dart';

/// Service responsible for managing the 30-day lifecycle of screenshots moved to 'Delete'.
/// Automatically purges expired items from device gallery, Cloud Firestore, and deduplication memory.
class AutoDeletionService {
  final ScreenshotRepository _repository;
  final ScreenshotSource _screenshotSource;
  final DeduplicationService _deduplicationService;
  static const _logger = AppLogger('AutoDeletionService');

  static const int retentionDays = 30;

  AutoDeletionService({
    required ScreenshotRepository repository,
    required ScreenshotSource screenshotSource,
    required DeduplicationService deduplicationService,
  })  : _repository = repository,
        _screenshotSource = screenshotSource,
        _deduplicationService = deduplicationService;

  /// Calculates the scheduled deletion date for an item marked for deletion.
  static DateTime calculateScheduledDeletionDate([DateTime? fromDate]) {
    final start = fromDate ?? DateTime.now();
    return start.add(const Duration(days: retentionDays));
  }

  /// Scans and purges all screenshots whose scheduledDeletionDate has passed (or >= 30 days old in Delete category).
  /// Returns the count of successfully purged items.
  Future<int> purgeExpiredScreenshots() async {
    try {
      _logger.i('Starting 30-day auto-deletion purge scan...');
      final pending = await _repository.getScreenshotsPendingDeletion();
      final now = DateTime.now();
      int purgedCount = 0;

      for (final item in pending) {
        // Determine if item is expired
        final targetDate = item.scheduledDeletionDate ??
            item.updatedAt.add(const Duration(days: retentionDays));

        if (now.isAfter(targetDate) || now.isAtSameMomentAs(targetDate)) {
          _logger.i('Item ${item.id} is expired (scheduled: $targetDate). Purging...');
          final success = await purgeItem(item);
          if (success) purgedCount++;
        }
      }

      _logger.i('Auto-deletion purge completed. Removed $purgedCount expired items.');
      return purgedCount;
    } catch (e, st) {
      _logger.e('Error during auto-deletion purge', e, st);
      return 0;
    }
  }

  /// Permanently deletes an item from:
  /// 1. System media gallery (via ScreenshotSource)
  /// 2. Firestore database / local repository
  /// 3. DeduplicationService cache
  Future<bool> purgeItem(ScreenshotItem item, {bool deleteFromGallery = true}) async {
    try {
      // 1. Delete from physical gallery/storage
      if (deleteFromGallery) {
        try {
          final deletedFromStorage = await _screenshotSource.deleteAsset(item.sourceAssetId);
          _logger.d('Device gallery deletion for ${item.sourceAssetId}: $deletedFromStorage');
        } catch (e) {
          _logger.w('Gallery deletion failed or asset already removed: ${item.sourceAssetId} ($e)');
        }
      }

      // 2. Remove from database
      await _repository.deleteScreenshot(item.id);

      // 3. Remove from deduplication index so it could be re-indexed if ever re-added
      _deduplicationService.removeAsset(item.sourceAssetId, item.contentHash);

      _logger.i('Successfully purged screenshot ${item.id} (${item.title})');
      return true;
    } catch (e, st) {
      _logger.e('Failed to purge screenshot ${item.id}', e, st);
      return false;
    }
  }

  /// Restores an item from 'Delete' category back to a specified category (default 'Uncategorized').
  Future<void> restoreItem(ScreenshotItem item, {String targetCategory = 'Uncategorized'}) async {
    final updated = item.copyWith(
      primaryCategory: targetCategory,
      clearScheduledDeletionDate: true,
      updatedAt: DateTime.now(),
    );
    await _repository.saveScreenshot(updated);
    _logger.i('Restored screenshot ${item.id} to $targetCategory');
  }

  /// Moves an item to 'Delete' category, setting scheduledDeletionDate to now + 30 days.
  Future<void> moveToDelete(ScreenshotItem item) async {
    final scheduledDate = calculateScheduledDeletionDate();
    final updated = item.copyWith(
      primaryCategory: 'Delete',
      scheduledDeletionDate: scheduledDate,
      updatedAt: DateTime.now(),
    );
    await _repository.saveScreenshot(updated);
    _logger.i('Moved screenshot ${item.id} to Delete. Scheduled for: $scheduledDate');
  }
}
