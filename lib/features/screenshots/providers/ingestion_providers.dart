import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../infrastructure/media/deduplication_service.dart';
import '../../../infrastructure/media/delta_sync_service.dart';
import '../../../infrastructure/media/local_preprocessor.dart';
import '../../../infrastructure/media/permission_service.dart';
import '../../../infrastructure/media/photo_manager_screenshot_source.dart';
import '../../../infrastructure/media/processing_queue.dart';
import '../../../infrastructure/media/screenshot_source.dart';
import '../domain/entities/screenshot_item.dart';
import '../../../infrastructure/background/background_sync_service.dart';
import 'gemini_providers.dart';

final mediaPermissionServiceProvider = Provider<MediaPermissionService>((ref) {
  return MediaPermissionService();
});

final screenshotSourceProvider = Provider<ScreenshotSource>((ref) {
  return PhotoManagerScreenshotSource();
});

final deduplicationServiceProvider = Provider<DeduplicationService>((ref) {
  return DeduplicationService();
});

final localPreprocessorProvider = Provider<LocalPreprocessor>((ref) {
  return LocalPreprocessor();
});

final processingQueueProvider = Provider<ProcessingQueue>((ref) {
  final source = ref.watch(screenshotSourceProvider);
  final preprocessor = ref.watch(localPreprocessorProvider);
  final dedup = ref.watch(deduplicationServiceProvider);
  final coordinator = ref.watch(pipelineCoordinatorProvider);

  final queue = ProcessingQueue(
    source: source,
    preprocessor: preprocessor,
    dedupService: dedup,
    onProcessItem: (item, media) => coordinator.processItem(item, media),
  );

  ref.onDispose(() => queue.dispose());
  return queue;
});

final deltaSyncServiceProvider = Provider<DeltaSyncService>((ref) {
  final source = ref.watch(screenshotSourceProvider);
  final dedup = ref.watch(deduplicationServiceProvider);
  final queue = ref.watch(processingQueueProvider);
  final perm = ref.watch(mediaPermissionServiceProvider);

  final service = DeltaSyncService(
    source: source,
    dedupService: dedup,
    processingQueue: queue,
    permissionService: perm,
  );

  service.startObserving();
  ref.onDispose(() => service.stopObserving());
  return service;
});

final activeQueueStreamProvider =
    StreamProvider<Map<String, ScreenshotItem>>((ref) {
  final queue = ref.watch(processingQueueProvider);
  return queue.queueStream;
});

final mediaPermissionStatusProvider =
    FutureProvider<MediaPermissionState>((ref) {
  final service = ref.watch(mediaPermissionServiceProvider);
  return service.checkPermission();
});

final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  return BackgroundSyncService();
});
