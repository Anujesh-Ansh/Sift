import 'dart:async';
import 'dart:collection';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/hash_util.dart';
import '../../features/screenshots/domain/entities/processing_status.dart';
import '../../features/screenshots/domain/entities/screenshot_item.dart';
import 'deduplication_service.dart';
import 'local_preprocessor.dart';
import 'models/processed_media.dart';
import 'models/screenshot_candidate.dart';
import 'screenshot_source.dart';

typedef ItemProcessor = Future<void> Function(
  ScreenshotItem item,
  ProcessedMedia media,
);

/// State machine coordinating discovery, compression, and pipeline execution.
class ProcessingQueue {
  final ScreenshotSource _source;
  final LocalPreprocessor _preprocessor;
  final DeduplicationService _dedupService;
  final ItemProcessor? _onProcessItem;

  static const _logger = AppLogger('ProcessingQueue');

  final Queue<ScreenshotCandidate> _pendingQueue = Queue();
  final Map<String, ScreenshotItem> _activeItems = {};
  final Map<String, int> _retryCounts = {};

  int _activeWorkers = 0;
  bool _isProcessing = false;

  final _streamController =
      StreamController<Map<String, ScreenshotItem>>.broadcast();

  ProcessingQueue({
    required ScreenshotSource source,
    required LocalPreprocessor preprocessor,
    required DeduplicationService dedupService,
    ItemProcessor? onProcessItem,
  })  : _source = source,
        _preprocessor = preprocessor,
        _dedupService = dedupService,
        _onProcessItem = onProcessItem;

  Stream<Map<String, ScreenshotItem>> get queueStream =>
      _streamController.stream;
  Map<String, ScreenshotItem> get activeItems => Map.unmodifiable(_activeItems);
  int get queueLength => _pendingQueue.length;

  /// Enqueues new candidate screenshots into the processing queue.
  void enqueueCandidates(List<ScreenshotCandidate> candidates) {
    for (final candidate in candidates) {
      if (_dedupService.isKnownAssetId(candidate.id)) {
        _logger.d('Skipping candidate ${candidate.id}: already known.');
        continue;
      }

      final itemId = HashUtil.generateScreenshotId(
        candidate.id,
        candidate.createDateTime.millisecondsSinceEpoch,
      );

      final item = ScreenshotItem(
        id: itemId,
        title: candidate.title,
        primaryCategory: 'Other',
        tags: const [],
        extractedText: '',
        needsHumanContext: false,
        reviewStatus: ReviewStatus.pending,
        sourceAssetId: candidate.id,
        contentHash: '',
        sourceCreatedAt: candidate.createDateTime,
        indexedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageWidth: candidate.width,
        imageHeight: candidate.height,
        thumbnailWidth: 0,
        thumbnailHeight: 0,
        fileSizeBytes: 0,
        processingStatus: ProcessingStatus.queued,
        modelVersion: AppConstants.defaultGeminiModel,
      );

      _activeItems[candidate.id] = item;
      _pendingQueue.add(candidate);
      _dedupService.recordAsset(candidate.id, itemId);
    }

    _notifyListeners();
    _drainQueue();
  }

  /// Triggers worker loop respecting bounded concurrency.
  void _drainQueue() {
    if (_isProcessing &&
        _activeWorkers >= AppConstants.maxConcurrentCompression) {
      return;
    }

    _isProcessing = true;

    while (_activeWorkers < AppConstants.maxConcurrentCompression &&
        _pendingQueue.isNotEmpty) {
      final candidate = _pendingQueue.removeFirst();
      _activeWorkers++;
      _processCandidate(candidate).whenComplete(() {
        _activeWorkers--;
        _drainQueue();
      });
    }

    if (_activeWorkers == 0 && _pendingQueue.isEmpty) {
      _isProcessing = false;
    }
  }

  Future<void> _processCandidate(ScreenshotCandidate candidate) async {
    final currentItem = _activeItems[candidate.id];
    if (currentItem == null) return;

    // Transition to compressing
    _updateItemStatus(candidate.id, ProcessingStatus.compressing);

    ProcessedMedia? media;
    try {
      final sourceFile = await _source.getAssetFile(candidate.id);
      if (sourceFile == null || !await sourceFile.exists()) {
        throw Exception('Source media file not accessible on device');
      }

      media = await _preprocessor.processImageFile(
        sourceFile: sourceFile,
        assetId: candidate.id,
      );

      // Check content hash duplicate
      if (_dedupService.isKnownHash(media.contentHash)) {
        _logger.w('Duplicate content hash detected for asset ${candidate.id}');
      } else {
        _dedupService.recordAsset(candidate.id, media.contentHash);
      }

      final updatedItem = currentItem.copyWith(
        contentHash: media.contentHash,
        fileSizeBytes: media.imageSizeBytes,
        thumbnailWidth: media.thumbnailWidth,
        thumbnailHeight: media.thumbnailHeight,
        localThumbnailPath: media.thumbnailFile.path,
        processingStatus: ProcessingStatus.uploaded,
      );
      _activeItems[candidate.id] = updatedItem;
      _notifyListeners();

      // Dispatch to pipeline callback (Firebase + Gemini)
      if (_onProcessItem != null) {
        await _onProcessItem(updatedItem, media);
      }

      _updateItemStatus(candidate.id, ProcessingStatus.completed);
      _logger.i('Pipeline completed for screenshot ${candidate.id}');
    } catch (e, st) {
      _logger.e('Error processing candidate ${candidate.id}', e, st);
      _handleFailure(candidate, e.toString());
    } finally {
      await media?.dispose();
    }
  }

  void _handleFailure(ScreenshotCandidate candidate, String error) {
    final retries = _retryCounts[candidate.id] ?? 0;
    if (retries < 3) {
      _retryCounts[candidate.id] = retries + 1;
      _updateItemStatus(candidate.id, ProcessingStatus.failedRetryable, error);
      // Requeue after short backoff
      Future.delayed(Duration(seconds: 2 * (retries + 1)), () {
        _pendingQueue.add(candidate);
        _drainQueue();
      });
    } else {
      _updateItemStatus(candidate.id, ProcessingStatus.failedPermanent, error);
    }
  }

  void _updateItemStatus(String assetId, ProcessingStatus status,
      [String? error]) {
    final item = _activeItems[assetId];
    if (item != null) {
      _activeItems[assetId] = item.copyWith(
        processingStatus: status,
        errorMessage: error,
        updatedAt: DateTime.now(),
      );
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    if (!_streamController.isClosed) {
      _streamController.add(Map.unmodifiable(_activeItems));
    }
  }

  void dispose() {
    _streamController.close();
  }
}
