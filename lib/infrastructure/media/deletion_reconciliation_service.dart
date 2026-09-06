import '../../core/logging/app_logger.dart';
import '../../features/screenshots/domain/repositories/screenshot_repository.dart';
import '../firebase/storage_service.dart';
import 'deduplication_service.dart';
import 'screenshot_source.dart';

/// Reconciles device gallery deletions with cloud storage and Firestore records.
class DeletionReconciliationService {
  final ScreenshotSource _source;
  final ScreenshotRepository _repository;
  final StorageService _storageService;
  final DeduplicationService _dedupService;

  static const _logger = AppLogger('DeletionReconciliationService');

  DeletionReconciliationService({
    required ScreenshotSource source,
    required ScreenshotRepository repository,
    required StorageService storageService,
    required DeduplicationService dedupService,
  })  : _source = source,
        _repository = repository,
        _storageService = storageService,
        _dedupService = dedupService;

  /// Performs a reconciliation check, removing cloud records whose source assets no longer exist.
  Future<int> reconcileDeletedAssets({required String userId}) async {
    try {
      _logger.i('Starting media deletion reconciliation for user $userId...');

      final indexedAssetIds = await _repository.getIndexedAssetIds();
      if (indexedAssetIds.isEmpty) {
        _logger.d('No indexed records found for reconciliation.');
        return 0;
      }

      int deletedCount = 0;

      for (final assetId in indexedAssetIds) {
        final exists = await _source.assetExists(assetId);
        if (!exists) {
          _logger.w(
              'Asset $assetId no longer exists on device. Cleaning up cloud records...');

          // 1. Delete Storage media
          await _storageService.deleteScreenshotMedia(
            userId: userId,
            screenshotId: assetId,
          );

          // 2. Delete Firestore metadata document
          await _repository.deleteScreenshot(assetId);

          // 3. Purge from local deduplication cache
          _dedupService.removeAsset(assetId);

          deletedCount++;
        }
      }

      _logger
          .i('Reconciliation finished. Purged $deletedCount deleted assets.');
      return deletedCount;
    } catch (e, st) {
      _logger.e('Error during deletion reconciliation', e, st);
      return 0;
    }
  }
}
