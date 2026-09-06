import 'package:flutter/widgets.dart';
import '../../core/logging/app_logger.dart';
import 'deduplication_service.dart';
import 'models/screenshot_candidate.dart';
import 'permission_service.dart';
import 'processing_queue.dart';
import 'screenshot_source.dart';

/// Coordinates foreground delta synchronization triggered on AppLifecycleState.resumed.
class DeltaSyncService with WidgetsBindingObserver {
  final ScreenshotSource _source;
  final DeduplicationService _dedupService;
  final ProcessingQueue _processingQueue;
  final MediaPermissionService _permissionService;

  static const _logger = AppLogger('DeltaSyncService');

  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  static const Duration _syncDebounceDuration = Duration(seconds: 15);

  DeltaSyncService({
    required ScreenshotSource source,
    required DeduplicationService dedupService,
    required ProcessingQueue processingQueue,
    required MediaPermissionService permissionService,
  })  : _source = source,
        _dedupService = dedupService,
        _processingQueue = processingQueue,
        _permissionService = permissionService;

  /// Starts listening to app lifecycle state transitions.
  void startObserving() {
    WidgetsBinding.instance.addObserver(this);
    _logger.i('DeltaSyncService observer registered.');
  }

  /// Stops listening to lifecycle events.
  void stopObserving() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logger.d('App resumed: triggering delta sync check.');
      performDeltaSync().ignore();
    }
  }

  /// Manual trigger for syncing screenshots on user demand.
  Future<int> syncNow() => performDeltaSync(force: true);

  /// Performs a paginated delta sync query.
  Future<int> performDeltaSync({bool force = false}) async {
    if (_isSyncing) {
      _logger.d('Sync already in progress, skipping.');
      return 0;
    }

    final now = DateTime.now();
    if (!force &&
        _lastSyncTime != null &&
        now.difference(_lastSyncTime!) < _syncDebounceDuration) {
      _logger.d('Delta sync debounced.');
      return 0;
    }

    _isSyncing = true;
    _lastSyncTime = now;

    try {
      final permission = await _permissionService.checkPermission();
      if (!permission.hasAccess) {
        _logger.w('Media permission not granted. Cannot perform delta sync.');
        return 0;
      }

      _logger.i('Starting foreground delta sync...');

      final List<ScreenshotCandidate> allNewCandidates = [];
      int page = 0;
      const pageSize = 10;
      const maxScreenshotsToSync = 10; // Testing cap: only the latest 10 screenshots

      while (allNewCandidates.length < maxScreenshotsToSync) {
        final remaining = maxScreenshotsToSync - allNewCandidates.length;
        final fetchSize = remaining < pageSize ? remaining : pageSize;
        final batch = await _source.fetchScreenshotCandidates(
          page: page,
          size: fetchSize,
        );

        if (batch.isEmpty) break;

        for (final c in batch) {
          if (!_dedupService.isKnownAssetId(c.id)) {
            allNewCandidates.add(c);
            if (allNewCandidates.length >= maxScreenshotsToSync) break;
          }
        }

        // If batch has fewer items than requested or reached cap, stop fetching
        if (batch.length < fetchSize || allNewCandidates.length >= maxScreenshotsToSync) break;
        page++;
      }

      if (allNewCandidates.isNotEmpty) {
        _logger.i(
            'Found ${allNewCandidates.length} new screenshots to enqueue across ${page + 1} page(s).');
        _processingQueue.enqueueCandidates(allNewCandidates);
      } else {
        _logger.d('No new screenshots detected.');
      }

      return allNewCandidates.length;
    } catch (e, st) {
      _logger.e('Failed during delta sync', e, st);
      return 0;
    } finally {
      _isSyncing = false;
    }
  }
}
