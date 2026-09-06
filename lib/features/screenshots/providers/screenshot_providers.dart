import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../infrastructure/firebase/storage_service.dart';
import '../../../infrastructure/media/deletion_reconciliation_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/repositories/firestore_screenshot_repository_impl.dart';
import '../domain/entities/screenshot_item.dart';
import '../domain/repositories/screenshot_repository.dart';
import 'ingestion_providers.dart';

final storageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});

final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider) ?? 'anonymous';
  return FirestoreScreenshotRepositoryImpl(userId: userId);
});

final deletionReconciliationServiceProvider =
    Provider<DeletionReconciliationService>((ref) {
  final source = ref.watch(screenshotSourceProvider);
  final repo = ref.watch(screenshotRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  final dedup = ref.watch(deduplicationServiceProvider);

  return DeletionReconciliationService(
    source: source,
    repository: repo,
    storageService: storage,
    dedupService: dedup,
  );
});

final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'All');

final screenshotsStreamProvider =
    StreamProvider.autoDispose<List<ScreenshotItem>>((ref) {
  final repo = ref.watch(screenshotRepositoryProvider);
  final category = ref.watch(selectedCategoryFilterProvider);
  return repo.watchScreenshots(category: category == 'All' ? null : category);
});

final reviewQueueStreamProvider =
    StreamProvider.autoDispose<List<ScreenshotItem>>((ref) {
  final repo = ref.watch(screenshotRepositoryProvider);
  return repo.watchReviewQueue();
});
