import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/features/screenshots/data/models/firestore_screenshot_dto.dart';
import 'package:project_sift/features/screenshots/domain/entities/processing_status.dart';
import 'package:project_sift/features/screenshots/domain/entities/screenshot_item.dart';

void main() {
  group('FirestoreScreenshotDto Serialization Tests', () {
    final now = DateTime(2026, 9, 6, 12, 0, 0);

    final domainItem = ScreenshotItem(
      id: 'sc_test_123',
      title: 'Amazon Receipt Order',
      primaryCategory: 'Shopping',
      tags: const ['amazon', 'order', 'receipt', 'books'],
      extractedText: 'Order #112-3456\nTotal: \$24.99',
      userNote: 'Book purchase for project',
      needsHumanContext: false,
      reviewStatus: ReviewStatus.approved,
      storagePath: 'users/u123/screenshots/sc_test_123/image.jpg',
      thumbnailStoragePath: 'users/u123/screenshots/sc_test_123/thumbnail.jpg',
      sourceAssetId: 'ph_999',
      contentHash: 'hash_sha256_abcdef',
      sourceCreatedAt: now,
      indexedAt: now,
      updatedAt: now,
      imageWidth: 1024,
      imageHeight: 2048,
      thumbnailWidth: 250,
      thumbnailHeight: 500,
      fileSizeBytes: 120500,
      processingStatus: ProcessingStatus.completed,
      modelVersion: 'gemini-1.5-flash',
      schemaVersion: 1,
    );

    test('should correctly convert domain to DTO and Map', () {
      final dto = FirestoreScreenshotDto.fromDomain(domainItem);
      final map = dto.toMap();

      expect(map['title'], equals('Amazon Receipt Order'));
      expect(map['primary_category'], equals('Shopping'));
      expect(map['tags'], equals(['amazon', 'order', 'receipt', 'books']));
      expect(map['needs_human_context'], isFalse);
      expect(map['review_status'], equals('approved'));
      expect(map['processing_status'], equals('completed'));
      expect(map['source_created_at'], isA<Timestamp>());
      expect(map['schema_version'], equals(1));
    });

    test('should correctly deserialize Map back to domain item', () {
      final dto = FirestoreScreenshotDto.fromDomain(domainItem);
      final map = dto.toMap();

      final reconstructedDto =
          FirestoreScreenshotDto.fromMap('sc_test_123', map);
      final reconstructedItem = reconstructedDto.toDomain();

      expect(reconstructedItem.id, equals(domainItem.id));
      expect(reconstructedItem.title, equals(domainItem.title));
      expect(reconstructedItem.primaryCategory,
          equals(domainItem.primaryCategory));
      expect(reconstructedItem.tags, equals(domainItem.tags));
      expect(reconstructedItem.extractedText, equals(domainItem.extractedText));
      expect(reconstructedItem.userNote, equals(domainItem.userNote));
      expect(reconstructedItem.reviewStatus, equals(domainItem.reviewStatus));
      expect(reconstructedItem.processingStatus,
          equals(domainItem.processingStatus));
      expect(reconstructedItem.imageWidth, equals(domainItem.imageWidth));
      expect(reconstructedItem.fileSizeBytes, equals(domainItem.fileSizeBytes));
    });

    test(
        'should handle fallback defaults gracefully on missing/malformed map values',
        () {
      final emptyMap = <String, dynamic>{};
      final dto = FirestoreScreenshotDto.fromMap('sc_fallback', emptyMap);
      final item = dto.toDomain();

      expect(item.id, equals('sc_fallback'));
      expect(item.title, equals('Untitled Screenshot'));
      expect(item.primaryCategory, equals('Other'));
      expect(item.tags, isEmpty);
      expect(item.extractedText, equals(''));
      expect(item.needsHumanContext, isFalse);
      expect(item.reviewStatus, equals(ReviewStatus.pending));
      expect(item.processingStatus, equals(ProcessingStatus.discovered));
    });
  });
}
