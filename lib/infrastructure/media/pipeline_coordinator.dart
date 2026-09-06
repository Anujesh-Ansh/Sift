import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../features/screenshots/domain/entities/processing_status.dart';
import '../../features/screenshots/domain/entities/screenshot_item.dart';
import '../../features/screenshots/domain/repositories/screenshot_repository.dart';
import '../ai/screenshot_analyzer.dart';
import '../firebase/storage_service.dart';
import 'models/processed_media.dart';

/// Orchestrates the post-compression pipeline:
/// 1. Uploads media to Firebase Cloud Storage.
/// 2. Executes Gemini multimodal vision analysis.
/// 3. Applies human-in-the-loop routing based on `needsHumanContext`.
/// 4. Persists the enriched metadata document to Cloud Firestore.
class PipelineCoordinator {
  final StorageService _storageService;
  final ScreenshotAnalyzer _analyzer;
  final ScreenshotRepository _repository;
  final String Function() _getUserId;

  static const _logger = AppLogger('PipelineCoordinator');

  PipelineCoordinator({
    required StorageService storageService,
    required ScreenshotAnalyzer analyzer,
    required ScreenshotRepository repository,
    required String Function() getUserId,
  })  : _storageService = storageService,
        _analyzer = analyzer,
        _repository = repository,
        _getUserId = getUserId;

  Future<ScreenshotItem> processItem(
    ScreenshotItem item,
    ProcessedMedia media,
  ) async {
    final userId = _getUserId();
    _logger.i(
        'Starting pipeline coordination for item ${item.id} (user: $userId)');

    // 1. Multimodal AI Analysis (performed directly on local image bytes)
    _logger.d('Running Gemini multimodal analysis for ${item.id}');
    AnalysisResult analysis;
    try {
      final imageBytes = await media.compressedImageFile.readAsBytes();
      analysis = await _analyzer.analyzeScreenshot(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
      );
    } catch (e, st) {
      _logger.w(
          'AI analysis encountered error for ${item.id}: $e. Using fallback result.',
          e,
          st);
      analysis = AnalysisResult.fallback(
        title: item.title,
        rawResponse: 'Analysis error: $e',
      );
    }

    // 2. Upload media to Storage (with graceful offline / local-first fallback)
    _logger.d('Uploading compressed images to storage for ${item.id}');
    String imagePath = 'file://${media.compressedImageFile.path}';
    String thumbPath = 'file://${media.thumbnailFile.path}';
    try {
      final uploadedPaths = await _storageService.uploadScreenshotMedia(
        userId: userId,
        screenshotId: item.id,
        imageFile: media.compressedImageFile,
        thumbnailFile: media.thumbnailFile,
      );
      imagePath = uploadedPaths.imagePath;
      thumbPath = uploadedPaths.thumbnailPath;
    } catch (e) {
      _logger.w(
          'Cloud storage upload failed or unconfigured ($e). Falling back to local device paths.');
    }

    // 3. Human-In-The-Loop Routing
    final isReviewRequired = analysis.needsHumanContext;
    final finalItem = item.copyWith(
      title: analysis.title,
      primaryCategory: analysis.primaryCategory,
      tags: analysis.tags,
      extractedText: analysis.extractedText,
      needsHumanContext: analysis.needsHumanContext,
      reviewStatus:
          isReviewRequired ? ReviewStatus.pending : ReviewStatus.approved,
      processingStatus: isReviewRequired
          ? ProcessingStatus.reviewRequired
          : ProcessingStatus.completed,
      storagePath: imagePath,
      thumbnailStoragePath: thumbPath,
      localThumbnailPath: media.thumbnailFile.path,
      modelVersion: AppConstants.defaultGeminiModel,
      updatedAt: DateTime.now(),
    );

    // 4. Save to Repository (local store & cloud Firestore)
    _logger.i(
        'Saving enriched screenshot document ${item.id} (Status: ${finalItem.processingStatus.label})');
    try {
      await _repository.saveScreenshot(finalItem);
    } catch (e, st) {
      _logger.w('Repository save had error ($e).', e, st);
    }

    return finalItem;
  }
}
