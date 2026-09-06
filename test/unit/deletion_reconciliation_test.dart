import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/features/screenshots/domain/entities/processing_status.dart';
import 'package:project_sift/features/screenshots/domain/entities/screenshot_item.dart';
import 'package:project_sift/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:project_sift/infrastructure/firebase/storage_service.dart';
import 'package:project_sift/infrastructure/media/deduplication_service.dart';
import 'package:project_sift/infrastructure/media/deletion_reconciliation_service.dart';
import 'package:project_sift/infrastructure/media/models/screenshot_candidate.dart';
import 'package:project_sift/infrastructure/media/screenshot_source.dart';

class MockSource implements ScreenshotSource {
  final Set<String> existingIds = {};

  @override
  Future<bool> assetExists(String assetId) async =>
      existingIds.contains(assetId);

  @override
  Future<List<ScreenshotCandidate>> fetchScreenshotCandidates(
          {int page = 0, int size = 50, DateTime? since}) async =>
      [];

  @override
  Future<File?> getAssetFile(String assetId) async => null;

  @override
  Future<Uint8List?> getThumbnailBytes(String assetId,
          {int width = 250, int height = 250}) async =>
      null;
}

class MockRepo implements ScreenshotRepository {
  final Set<String> storedIds = {};
  final List<String> deletedIds = [];

  @override
  Future<Set<String>> getIndexedAssetIds() async => Set.from(storedIds);

  @override
  Future<void> deleteScreenshot(String id) async {
    storedIds.remove(id);
    deletedIds.add(id);
  }

  @override
  Future<ScreenshotItem?> getScreenshot(String id) async => null;

  @override
  Future<void> saveScreenshot(ScreenshotItem item) async {}

  @override
  Future<void> updateReviewStatus(String id,
      {required ReviewStatus status,
      String? correctedCategory,
      List<String>? tags,
      String? note}) async {}

  @override
  Stream<List<ScreenshotItem>> watchReviewQueue({int limit = 50}) =>
      const Stream.empty();

  @override
  Stream<List<ScreenshotItem>> watchScreenshots(
          {String? category, ReviewStatus? reviewStatus, int limit = 100}) =>
      const Stream.empty();
}

class MockStorage implements StorageService {
  final List<String> deletedScreenshots = [];

  @override
  Future<void> deleteScreenshotMedia(
      {required String userId, required String screenshotId}) async {
    deletedScreenshots.add(screenshotId);
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async => null;

  @override
  Future<({String imagePath, String thumbnailPath})> uploadScreenshotMedia({
    required String userId,
    required String screenshotId,
    required File imageFile,
    required File thumbnailFile,
  }) async =>
      (imagePath: '', thumbnailPath: '');
}

void main() {
  group('DeletionReconciliationService Tests', () {
    late MockSource source;
    late MockRepo repo;
    late MockStorage storage;
    late DeduplicationService dedup;
    late DeletionReconciliationService reconciliationService;

    setUp(() {
      source = MockSource();
      repo = MockRepo();
      storage = MockStorage();
      dedup = DeduplicationService();

      reconciliationService = DeletionReconciliationService(
        source: source,
        repository: repo,
        storageService: storage,
        dedupService: dedup,
      );
    });

    test(
        'should clean up storage, firestore, and dedup cache when asset deleted from device',
        () async {
      // Setup: 2 assets indexed in cloud, but only asset_1 exists on device
      repo.storedIds.addAll(['asset_1', 'asset_deleted']);
      source.existingIds.add('asset_1');
      dedup.recordAsset('asset_deleted', 'hash_del');

      final purgedCount = await reconciliationService.reconcileDeletedAssets(
          userId: 'user_test_1');

      expect(purgedCount, equals(1));
      expect(repo.deletedIds, contains('asset_deleted'));
      expect(storage.deletedScreenshots, contains('asset_deleted'));
      expect(dedup.isKnownAssetId('asset_deleted'), isFalse);
      expect(repo.storedIds.contains('asset_1'), isTrue);
    });

    test('should do nothing when all indexed assets still exist on device',
        () async {
      repo.storedIds.addAll(['asset_1', 'asset_2']);
      source.existingIds.addAll(['asset_1', 'asset_2']);

      final purgedCount = await reconciliationService.reconcileDeletedAssets(
          userId: 'user_test_1');

      expect(purgedCount, equals(0));
      expect(repo.deletedIds, isEmpty);
      expect(storage.deletedScreenshots, isEmpty);
    });
  });
}
