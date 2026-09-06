import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/features/screenshots/domain/entities/processing_status.dart';
import 'package:project_sift/infrastructure/media/deduplication_service.dart';
import 'package:project_sift/infrastructure/media/local_preprocessor.dart';
import 'package:project_sift/infrastructure/media/models/processed_media.dart';
import 'package:project_sift/infrastructure/media/models/screenshot_candidate.dart';
import 'package:project_sift/infrastructure/media/processing_queue.dart';
import 'package:project_sift/infrastructure/media/screenshot_source.dart';

class MockScreenshotSource implements ScreenshotSource {
  final Map<String, File> files = {};

  @override
  Future<List<ScreenshotCandidate>> fetchScreenshotCandidates({
    int page = 0,
    int size = 50,
    DateTime? since,
  }) async =>
      [];

  @override
  Future<File?> getAssetFile(String assetId) async => files[assetId];

  @override
  Future<Uint8List?> getThumbnailBytes(String assetId,
          {int width = 250, int height = 250}) async =>
      null;

  @override
  Future<bool> assetExists(String assetId) async => files.containsKey(assetId);
}

class MockLocalPreprocessor extends LocalPreprocessor {
  final Map<String, ProcessedMedia> processedOutputs = {};

  @override
  Future<ProcessedMedia> processImageFile({
    required File sourceFile,
    required String assetId,
  }) async {
    final output = processedOutputs[assetId];
    if (output == null) {
      throw Exception('Mock preprocessor failure for $assetId');
    }
    return output;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProcessingQueue Unit Tests', () {
    late MockScreenshotSource source;
    late MockLocalPreprocessor preprocessor;
    late DeduplicationService dedupService;
    late ProcessingQueue queue;
    late Directory tempDir;

    setUp(() async {
      source = MockScreenshotSource();
      preprocessor = MockLocalPreprocessor();
      dedupService = DeduplicationService();
      tempDir = await Directory.systemTemp.createTemp('sift_test_');

      queue = ProcessingQueue(
        source: source,
        preprocessor: preprocessor,
        dedupService: dedupService,
      );
    });

    tearDown(() async {
      queue.dispose();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('should enqueue new candidates and avoid duplicates', () async {
      final candidate1 = ScreenshotCandidate(
        id: 'asset_1',
        title: 'Invoice.png',
        createDateTime: DateTime.now(),
        modifiedDateTime: DateTime.now(),
        width: 1080,
        height: 1920,
      );

      queue.enqueueCandidates([candidate1]);

      expect(queue.activeItems.containsKey('asset_1'), isTrue);
      expect(queue.activeItems['asset_1']!.processingStatus,
          isNot(ProcessingStatus.discovered));

      // Attempt duplicate enqueue
      queue.enqueueCandidates([candidate1]);
      expect(queue.activeItems.length, equals(1));
    });

    test('should process candidate to completion when file exists', () async {
      final dummyFile = File('${tempDir.path}/test_source.jpg');
      await dummyFile.writeAsString('test image content');
      source.files['asset_valid'] = dummyFile;

      final thumbFile = File('${tempDir.path}/test_thumb.jpg');
      await thumbFile.writeAsString('thumb content');

      preprocessor.processedOutputs['asset_valid'] = ProcessedMedia(
        compressedImageFile: dummyFile,
        thumbnailFile: thumbFile,
        contentHash: 'hash_abc_123',
        imageWidth: 1024,
        imageHeight: 1024,
        thumbnailWidth: 250,
        thumbnailHeight: 250,
        imageSizeBytes: 100,
        thumbnailSizeBytes: 20,
      );

      final candidate = ScreenshotCandidate(
        id: 'asset_valid',
        title: 'Valid.png',
        createDateTime: DateTime.now(),
        modifiedDateTime: DateTime.now(),
        width: 1080,
        height: 1920,
      );

      queue.enqueueCandidates([candidate]);

      // Wait briefly for queue async drain
      await Future.delayed(const Duration(milliseconds: 100));

      final processed = queue.activeItems['asset_valid'];
      expect(processed, isNotNull);
      expect(processed!.processingStatus, equals(ProcessingStatus.completed));
      expect(processed.contentHash, equals('hash_abc_123'));
    });
  });
}
