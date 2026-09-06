import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/features/screenshots/domain/entities/processing_status.dart';
import 'package:project_sift/features/screenshots/domain/entities/screenshot_item.dart';
import 'package:project_sift/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:project_sift/infrastructure/ai/screenshot_analyzer.dart';
import 'package:project_sift/infrastructure/firebase/storage_service.dart';
import 'package:project_sift/infrastructure/media/models/processed_media.dart';
import 'package:project_sift/infrastructure/media/pipeline_coordinator.dart';

class MockStorageService implements StorageService {
  int uploadCallCount = 0;

  @override
  Future<({String imagePath, String thumbnailPath})> uploadScreenshotMedia({
    required String userId,
    required String screenshotId,
    required File imageFile,
    required File thumbnailFile,
  }) async {
    uploadCallCount++;
    return (
      imagePath: 'users/$userId/screenshots/$screenshotId/image.jpg',
      thumbnailPath: 'users/$userId/screenshots/$screenshotId/thumbnail.jpg',
    );
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async =>
      'https://storage.mock/$storagePath';

  @override
  Future<void> deleteScreenshotMedia(
      {required String userId, required String screenshotId}) async {}
}

class MockAnalyzer implements ScreenshotAnalyzer {
  AnalysisResult stubResult;

  MockAnalyzer(this.stubResult);

  @override
  Future<AnalysisResult> analyzeScreenshot({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    return stubResult;
  }
}

class MockScreenshotRepository implements ScreenshotRepository {
  ScreenshotItem? savedItem;

  @override
  Future<void> saveScreenshot(ScreenshotItem item) async {
    savedItem = item;
  }

  @override
  Future<void> deleteScreenshot(String id) async {}

  @override
  Future<Set<String>> getIndexedAssetIds() async => {};

  @override
  Future<ScreenshotItem?> getScreenshot(String id) async => savedItem;

  @override
  Future<void> updateReviewStatus(
    String id, {
    required ReviewStatus status,
    String? correctedCategory,
    List<String>? tags,
    String? note,
  }) async {}

  @override
  Stream<List<ScreenshotItem>> watchReviewQueue({int limit = 50}) =>
      const Stream.empty();

  @override
  Stream<List<ScreenshotItem>> watchScreenshots(
          {String? category, ReviewStatus? reviewStatus, int limit = 100}) =>
      const Stream.empty();

  @override
  Future<List<ScreenshotItem>> getScreenshotsPendingDeletion() async => [];
}

void main() {
  group('PipelineCoordinator Unit Tests', () {
    late Directory tempDir;
    late File mockImageFile;
    late File mockThumbFile;
    late MockStorageService mockStorage;
    late MockScreenshotRepository mockRepo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pipeline_test_');
      mockImageFile = File('${tempDir.path}/img.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      mockThumbFile = File('${tempDir.path}/thumb.jpg')
        ..writeAsBytesSync([4, 5, 6]);
      mockStorage = MockStorageService();
      mockRepo = MockScreenshotRepository();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
        'should route unambiguous screenshot to completed state and save to firestore',
        () async {
      final mockAnalyzer = MockAnalyzer(
        const AnalysisResult(
          title: 'AWS Cloud Architecture',
          primaryCategory: 'Technology',
          tags: ['aws', 'cloud', 'architecture'],
          extractedText: 'VPC Subnet Route Table',
          needsHumanContext: false,
        ),
      );

      final coordinator = PipelineCoordinator(
        storageService: mockStorage,
        analyzer: mockAnalyzer,
        repository: mockRepo,
        getUserId: () => 'user_test_42',
      );

      final initialItem = ScreenshotItem(
        id: 'shot_101',
        title: 'Initial',
        primaryCategory: 'Other',
        tags: const [],
        extractedText: '',
        needsHumanContext: false,
        reviewStatus: ReviewStatus.pending,
        sourceAssetId: 'asset_101',
        contentHash: 'hash_abc',
        sourceCreatedAt: DateTime.now(),
        indexedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageWidth: 1080,
        imageHeight: 1920,
        thumbnailWidth: 250,
        thumbnailHeight: 250,
        fileSizeBytes: 1024,
        processingStatus: ProcessingStatus.uploaded,
        modelVersion: 'gemini-1.5-flash',
      );

      final media = ProcessedMedia(
        compressedImageFile: mockImageFile,
        thumbnailFile: mockThumbFile,
        contentHash: 'hash_abc',
        imageSizeBytes: 1024,
        thumbnailSizeBytes: 200,
        imageWidth: 1080,
        imageHeight: 1920,
        thumbnailWidth: 250,
        thumbnailHeight: 250,
      );

      final result = await coordinator.processItem(initialItem, media);

      expect(mockStorage.uploadCallCount, equals(1));
      expect(result.primaryCategory, equals('Technology'));
      expect(result.tags, contains('aws'));
      expect(result.needsHumanContext, isFalse);
      expect(result.processingStatus, equals(ProcessingStatus.completed));
      expect(result.reviewStatus, equals(ReviewStatus.approved));
      expect(result.storagePath,
          equals('users/user_test_42/screenshots/shot_101/image.jpg'));
      expect(mockRepo.savedItem, isNotNull);
      expect(mockRepo.savedItem!.id, equals('shot_101'));
    });

    test(
        'should route ambiguous screenshot to reviewRequired and pending status',
        () async {
      final mockAnalyzer = MockAnalyzer(
        const AnalysisResult(
          title: 'Vintage Dress Moodboard',
          primaryCategory: 'Aesthetic',
          tags: ['fashion', 'vintage', 'moodboard'],
          extractedText: '',
          needsHumanContext: true,
        ),
      );

      final coordinator = PipelineCoordinator(
        storageService: mockStorage,
        analyzer: mockAnalyzer,
        repository: mockRepo,
        getUserId: () => 'user_test_42',
      );

      final initialItem = ScreenshotItem(
        id: 'shot_102',
        title: 'Initial',
        primaryCategory: 'Other',
        tags: const [],
        extractedText: '',
        needsHumanContext: false,
        reviewStatus: ReviewStatus.pending,
        sourceAssetId: 'asset_102',
        contentHash: 'hash_xyz',
        sourceCreatedAt: DateTime.now(),
        indexedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageWidth: 1080,
        imageHeight: 1920,
        thumbnailWidth: 250,
        thumbnailHeight: 250,
        fileSizeBytes: 1024,
        processingStatus: ProcessingStatus.uploaded,
        modelVersion: 'gemini-1.5-flash',
      );

      final media = ProcessedMedia(
        compressedImageFile: mockImageFile,
        thumbnailFile: mockThumbFile,
        contentHash: 'hash_xyz',
        imageSizeBytes: 1024,
        thumbnailSizeBytes: 200,
        imageWidth: 1080,
        imageHeight: 1920,
        thumbnailWidth: 250,
        thumbnailHeight: 250,
      );

      final result = await coordinator.processItem(initialItem, media);

      expect(mockStorage.uploadCallCount, equals(1));
      expect(result.needsHumanContext, isTrue);
      expect(result.processingStatus, equals(ProcessingStatus.reviewRequired));
      expect(result.reviewStatus, equals(ReviewStatus.pending));
      expect(mockRepo.savedItem!.processingStatus,
          equals(ProcessingStatus.reviewRequired));
    });
  });
}
