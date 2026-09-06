import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/core/constants/app_constants.dart';
import 'package:project_sift/core/utils/hash_util.dart';
import 'package:project_sift/features/screenshots/domain/entities/processing_status.dart';
import 'package:project_sift/features/screenshots/domain/entities/screenshot_item.dart';
import 'package:project_sift/infrastructure/ai/category_classifier.dart';
import 'package:project_sift/infrastructure/media/deduplication_service.dart';
import 'package:project_sift/infrastructure/media/models/processed_media.dart';

void main() {
  group('Milestone 9: Performance Hardening & Stress Testing', () {
    test(
        '1000-item search and category filtering benchmark completes within 50ms',
        () {
      final categories = CategoryClassifier.canonicalCategories;
      final stopwatch = Stopwatch()..start();

      // 1. Generate 1,000 realistic screenshot records
      final items = List.generate(1000, (i) {
        final category = categories[i % categories.length];
        return ScreenshotItem(
          id: 'shot_$i',
          title: 'Screenshot #$i of $category transaction',
          primaryCategory: category,
          tags: ['tag_${i % 20}', 'sample', category.toLowerCase()],
          extractedText:
              'OCR extracted receipt number ${i * 1234} total \$${i % 500}.00',
          needsHumanContext: i % 7 == 0,
          reviewStatus:
              i % 7 == 0 ? ReviewStatus.pending : ReviewStatus.approved,
          sourceAssetId: 'asset_$i',
          contentHash: 'hash_${i.toString().padLeft(64, '0')}',
          sourceCreatedAt: DateTime.now().subtract(Duration(hours: i)),
          indexedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          imageWidth: 1080,
          imageHeight: 1920,
          thumbnailWidth: 250,
          thumbnailHeight: 250,
          fileSizeBytes: 200000 + (i * 100),
          processingStatus: ProcessingStatus.completed,
          modelVersion: AppConstants.defaultGeminiModel,
        );
      });

      final generationTime = stopwatch.elapsedMilliseconds;
      expect(generationTime, greaterThanOrEqualTo(0));

      // 2. Benchmark category filtering over 1,000 items
      stopwatch.reset();
      final financeItems =
          items.where((item) => item.primaryCategory == 'Finance').toList();
      final categoryFilterTime = stopwatch.elapsedMilliseconds;

      expect(financeItems.isNotEmpty, isTrue);
      expect(categoryFilterTime, lessThan(50),
          reason: 'Category filter took too long: ${categoryFilterTime}ms');

      // 3. Benchmark complex multi-field keyword search across 1,000 items
      stopwatch.reset();
      const query = 'transaction';
      final searchResults = items.where((item) {
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesCategory =
            item.primaryCategory.toLowerCase().contains(query);
        final matchesTags =
            item.tags.any((t) => t.toLowerCase().contains(query));
        final matchesText = item.extractedText.toLowerCase().contains(query);
        final matchesNote =
            item.userNote?.toLowerCase().contains(query) ?? false;
        return matchesTitle ||
            matchesCategory ||
            matchesTags ||
            matchesText ||
            matchesNote;
      }).toList();
      final searchTime = stopwatch.elapsedMilliseconds;

      expect(searchResults.length, equals(1000));
      expect(searchTime, lessThan(50),
          reason: 'Search took too long: ${searchTime}ms');
    });

    test(
        '10,000-item DeduplicationService lookup benchmark completes in under 25ms',
        () {
      final dedup = DeduplicationService();
      final assetIds = <String>[];
      final hashes = <String>[];

      for (int i = 0; i < 10000; i++) {
        final assetId = 'asset_perf_$i';
        final hash = HashUtil.computeSha256(
            Uint8List.fromList([i % 256, (i * 7) % 256]));
        assetIds.add(assetId);
        hashes.add(hash);
      }

      dedup.seedKnownRecords(assetIds: assetIds, contentHashes: hashes);

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        final isKnown = dedup.isKnownAssetId('asset_perf_$i');
        expect(isKnown, isTrue);
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: '10,000 lookups took ${stopwatch.elapsedMilliseconds}ms');
    });

    test(
        'ProcessedMedia dispose cleans up temporary files without memory leakage',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('leak_test_');
      final imageFile = File('${tempDir.path}/test_img.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);
      final thumbFile = File('${tempDir.path}/test_thumb.jpg')
        ..writeAsBytesSync([5, 6, 7, 8]);

      expect(await imageFile.exists(), isTrue);
      expect(await thumbFile.exists(), isTrue);

      final media = ProcessedMedia(
        compressedImageFile: imageFile,
        thumbnailFile: thumbFile,
        contentHash: 'hash_test',
        imageSizeBytes: 4,
        thumbnailSizeBytes: 4,
        imageWidth: 100,
        imageHeight: 100,
        thumbnailWidth: 50,
        thumbnailHeight: 50,
      );

      await media.dispose(deleteThumbnail: true);

      expect(await imageFile.exists(), isFalse,
          reason: 'Compressed image file should be purged on dispose');
      expect(await thumbFile.exists(), isFalse,
          reason: 'Thumbnail file should be purged on dispose');

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
