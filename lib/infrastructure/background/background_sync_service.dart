import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../firebase/firebase_config.dart';
import '../media/deduplication_service.dart';
import '../media/delta_sync_service.dart';
import '../media/local_preprocessor.dart';
import '../media/permission_service.dart';
import '../media/photo_manager_screenshot_source.dart';
import '../media/processing_queue.dart';

const String _periodicTaskUniqueName = 'project_sift_periodic_sync';
const String _oneOffTaskUniqueName = 'project_sift_one_off_sync';

/// Top-level background execution dispatcher for WorkManager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    const logger = AppLogger('BackgroundSyncWorker');
    logger.i('Starting background task: $taskName');

    try {
      // 1. Initialize Firebase if in background isolate
      await FirebaseConfig.initialize(useEmulators: false);

      // 2. Perform delta synchronization
      final source = PhotoManagerScreenshotSource();
      final dedup = DeduplicationService();
      final preprocessor = LocalPreprocessor();
      final permService = MediaPermissionService();

      final queue = ProcessingQueue(
        source: source,
        preprocessor: preprocessor,
        dedupService: dedup,
      );

      final deltaSync = DeltaSyncService(
        source: source,
        dedupService: dedup,
        processingQueue: queue,
        permissionService: permService,
      );

      final count = await deltaSync.performDeltaSync(force: true);
      logger.i(
          'Background sync successfully completed. Discovered $count new assets.');
      return true;
    } catch (e, st) {
      logger.e('Background sync task failed: $e', e, st);
      // Return true to avoid rapid infinite OS retry loop on failure
      return true;
    }
  });
}

/// Service managing periodic and one-off background synchronization scheduling.
class BackgroundSyncService {
  final Workmanager _workmanager;
  static const _logger = AppLogger('BackgroundSyncService');

  BackgroundSyncService({Workmanager? workmanager})
      : _workmanager = workmanager ?? Workmanager();

  /// Initializes the WorkManager engine.
  Future<void> initialize() async {
    // WorkManager is only supported on Android and iOS mobile platforms
    if (kIsWeb) return;

    try {
      await _workmanager.initialize(
        callbackDispatcher,
      );
      _logger.i('WorkManager background sync service initialized');
    } catch (e, st) {
      _logger.w('WorkManager initialization error: $e', e, st);
    }
  }

  /// Schedules periodic background sync (requested every ~6 hours).
  Future<void> schedulePeriodicSync({
    int frequencyHours = AppConstants.backgroundSyncFrequencyHours,
  }) async {
    if (kIsWeb) return;

    try {
      await _workmanager.registerPeriodicTask(
        _periodicTaskUniqueName,
        AppConstants.backgroundSyncTaskName,
        frequency: Duration(hours: frequencyHours),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
      _logger.i('Registered periodic sync task every $frequencyHours hours');
    } catch (e, st) {
      _logger.w('Failed to register periodic sync task: $e', e, st);
    }
  }

  /// Cancels periodic background sync.
  Future<void> cancelPeriodicSync() async {
    if (kIsWeb) return;

    try {
      await _workmanager.cancelByUniqueName(_periodicTaskUniqueName);
      _logger.i('Cancelled periodic background sync');
    } catch (e, st) {
      _logger.w('Failed to cancel periodic sync: $e', e, st);
    }
  }

  /// Dispatches an immediate one-off background sync task.
  Future<void> triggerOneOffSync() async {
    if (kIsWeb) return;

    try {
      await _workmanager.registerOneOffTask(
        _oneOffTaskUniqueName,
        AppConstants.backgroundSyncTaskName,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      _logger.i('Triggered one-off background sync task');
    } catch (e, st) {
      _logger.w('Failed to trigger one-off sync task: $e', e, st);
    }
  }
}
