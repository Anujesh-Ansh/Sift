import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/features/screenshots/domain/entities/processing_status.dart';
import 'package:project_sift/features/screenshots/domain/entities/screenshot_item.dart';
import 'package:project_sift/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:project_sift/infrastructure/media/auto_deletion_service.dart';
import 'package:project_sift/infrastructure/media/deduplication_service.dart';
import 'package:project_sift/infrastructure/media/models/screenshot_candidate.dart';
import 'package:project_sift/infrastructure/media/screenshot_source.dart';

class MockSource implements ScreenshotSource {
  final Set<String> existingIds = {};
  final List<String> deletedAssets = [];

  @override
  Future<bool> assetExists(String assetId) async => existingIds.contains(assetId);

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

  @override
  Future<bool> deleteAsset(String assetId) async {
    existingIds.remove(assetId);
    deletedAssets.add(assetId);
    return true;
  }
}

class MockRepo implements ScreenshotRepository {
  final Map<String, ScreenshotItem> items = {};
  final List<String> deletedItemIds = [];

  @override
  Future<Set<String>> getIndexedAssetIds() async =>
      items.values.map((e) => e.sourceAssetId).toSet();

  @override
  Future<void> deleteScreenshot(String id) async {
    items.remove(id);
    deletedItemIds.add(id);
  }

  @override
  Future<ScreenshotItem?> getScreenshot(String id) async => items[id];

  @override
  Future<void> saveScreenshot(ScreenshotItem item) async {
    items[item.id] = item;
  }

  @override
  Future<void> updateReviewStatus(String id,
      {required ReviewStatus status,
      String? correctedCategory,
      List<String>? tags,
      String? note}) async {
    final existing = items[id];
    if (existing != null) {
      items[id] = existing.copyWith(
        reviewStatus: status,
        primaryCategory: correctedCategory ?? existing.primaryCategory,
      );
    }
  }

  @override
  Future<List<ScreenshotItem>> getScreenshotsPendingDeletion() async {
    return items.values
        .where((item) =>
            item.primaryCategory == 'Delete' || item.scheduledDeletionDate != null)
        .toList();
  }

  @override
  Stream<List<ScreenshotItem>> watchScreenshots({
    String? category,
    ReviewStatus? reviewStatus,
    int limit = 100,
  }) {
    return Stream.value(items.values.toList());
  }

  @override
  Stream<List<ScreenshotItem>> watchReviewQueue({int limit = 50}) {
    return Stream.value(items.values
        .where((e) => e.reviewStatus == ReviewStatus.pending)
        .toList());
  }
}

void main() {
  late MockRepo mockRepo;
  late MockSource mockSource;
  late DeduplicationService dedupService;
  late AutoDeletionService autoDeletionService;

  ScreenshotItem createItem({
    required String id,
    required String assetId,
    required String category,
    DateTime? scheduledDeletionDate,
  }) {
    return ScreenshotItem(
      id: id,
      title: 'Screenshot $id',
      primaryCategory: category,
      tags: const ['test'],
      extractedText: 'sample text',
      sourceAssetId: assetId,
      contentHash: 'hash_$id',
      sourceCreatedAt: DateTime.now().subtract(const Duration(days: 40)),
      indexedAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 35)),
      scheduledDeletionDate: scheduledDeletionDate,
      imageWidth: 1080,
      imageHeight: 1920,
      thumbnailWidth: 250,
      thumbnailHeight: 444,
      fileSizeBytes: 102400,
      processingStatus: ProcessingStatus.completed,
      reviewStatus: ReviewStatus.approved,
      modelVersion: 'gemini-2.5-flash',
      needsHumanContext: false,
    );
  }

  setUp(() {
    mockRepo = MockRepo();
    mockSource = MockSource();
    dedupService = DeduplicationService();
    autoDeletionService = AutoDeletionService(
      repository: mockRepo,
      screenshotSource: mockSource,
      deduplicationService: dedupService,
    );
  });

  group('AutoDeletionService Unit Tests', () {
    test('calculateScheduledDeletionDate returns 30 days ahead', () {
      final base = DateTime(2026, 1, 1, 12, 0);
      final scheduled = AutoDeletionService.calculateScheduledDeletionDate(base);
      expect(scheduled.difference(base).inDays, 30);
    });

    test('moveToDelete updates item category and schedules deletion 30 days ahead', () async {
      final item = createItem(id: 'item1', assetId: 'asset1', category: 'Receipts');
      await mockRepo.saveScreenshot(item);

      await autoDeletionService.moveToDelete(item);

      final updated = await mockRepo.getScreenshot('item1');
      expect(updated, isNotNull);
      expect(updated!.primaryCategory, 'Delete');
      expect(updated.scheduledDeletionDate, isNotNull);
      expect(updated.daysUntilDeletion, closeTo(30, 1));
    });

    test('restoreItem clears scheduled deletion date and updates category', () async {
      final item = createItem(
        id: 'item2',
        assetId: 'asset2',
        category: 'Delete',
        scheduledDeletionDate: DateTime.now().add(const Duration(days: 15)),
      );
      await mockRepo.saveScreenshot(item);

      await autoDeletionService.restoreItem(item, targetCategory: 'Work');

      final updated = await mockRepo.getScreenshot('item2');
      expect(updated, isNotNull);
      expect(updated!.primaryCategory, 'Work');
      expect(updated.scheduledDeletionDate, isNull);
    });

    test('purgeItem removes item from gallery, repo, and dedup cache', () async {
      final item = createItem(id: 'item3', assetId: 'asset3', category: 'Delete');
      mockSource.existingIds.add('asset3');
      await mockRepo.saveScreenshot(item);
      dedupService.recordAsset('asset3', 'hash_item3');

      final success = await autoDeletionService.purgeItem(item);

      expect(success, isTrue);
      expect(mockSource.deletedAssets, contains('asset3'));
      expect(mockRepo.deletedItemIds, contains('item3'));
      expect(mockRepo.items.containsKey('item3'), isFalse);
      expect(dedupService.isKnownAssetId('asset3'), isFalse);
    });

    test('purgeExpiredScreenshots purges only expired items and preserves unexpired items', () async {
      final now = DateTime.now();

      // Expired item (scheduled in the past)
      final expiredItem = createItem(
        id: 'expired1',
        assetId: 'asset_exp1',
        category: 'Delete',
        scheduledDeletionDate: now.subtract(const Duration(days: 2)),
      );

      // Unexpired item (scheduled 10 days in the future)
      final activeItem = createItem(
        id: 'active1',
        assetId: 'asset_act1',
        category: 'Delete',
        scheduledDeletionDate: now.add(const Duration(days: 10)),
      );

      mockSource.existingIds.addAll(['asset_exp1', 'asset_act1']);
      await mockRepo.saveScreenshot(expiredItem);
      await mockRepo.saveScreenshot(activeItem);

      final count = await autoDeletionService.purgeExpiredScreenshots();

      expect(count, 1);
      expect(mockRepo.deletedItemIds, contains('expired1'));
      expect(mockRepo.deletedItemIds.contains('active1'), isFalse);
      expect(mockRepo.items.containsKey('expired1'), isFalse);
      expect(mockRepo.items.containsKey('active1'), isTrue);
      expect(mockSource.deletedAssets, contains('asset_exp1'));
      expect(mockSource.deletedAssets.contains('asset_act1'), isFalse);
    });
  });
}
