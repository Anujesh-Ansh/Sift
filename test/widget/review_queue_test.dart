import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/features/review/presentation/screens/review_queue_screen.dart';
import 'package:project_sift/features/review/presentation/widgets/triage_card.dart';
import 'package:project_sift/features/screenshots/domain/entities/processing_status.dart';
import 'package:project_sift/features/screenshots/domain/entities/screenshot_item.dart';
import 'package:project_sift/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:project_sift/features/screenshots/providers/screenshot_providers.dart';

class MockRepo implements ScreenshotRepository {
  final List<String> approvedIds = [];

  @override
  Future<void> updateReviewStatus(
    String id, {
    required ReviewStatus status,
    String? correctedCategory,
    List<String>? tags,
    String? note,
  }) async {
    approvedIds.add(id);
  }

  @override
  Future<void> deleteScreenshot(String id) async {}

  @override
  Future<Set<String>> getIndexedAssetIds() async => {};

  @override
  Future<ScreenshotItem?> getScreenshot(String id) async => null;

  @override
  Future<void> saveScreenshot(ScreenshotItem item) async {}

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
  final testItem = ScreenshotItem(
    id: 'shot_triage_1',
    title: 'Vintage Dress Inspiration',
    primaryCategory: 'Aesthetic',
    tags: const ['vintage', 'dress'],
    extractedText: 'Summer collection',
    needsHumanContext: true,
    reviewStatus: ReviewStatus.pending,
    sourceAssetId: 'asset_triage_1',
    contentHash: 'hash_triage_1',
    sourceCreatedAt: DateTime.now(),
    indexedAt: DateTime.now(),
    updatedAt: DateTime.now(),
    imageWidth: 1080,
    imageHeight: 1920,
    thumbnailWidth: 250,
    thumbnailHeight: 250,
    fileSizeBytes: 1024,
    processingStatus: ProcessingStatus.reviewRequired,
    modelVersion: 'gemini-1.5-flash',
  );

  testWidgets('ReviewQueueScreen renders empty state when queue has no items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reviewQueueStreamProvider
              .overrideWith((ref) => Stream.value(<ScreenshotItem>[])),
        ],
        child: const MaterialApp(home: ReviewQueueScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('All Caught Up!'), findsOneWidget);
    expect(find.text('Human Review Queue'), findsOneWidget);
  });

  testWidgets(
      'ReviewQueueScreen renders TriageCard when items are pending review',
      (WidgetTester tester) async {
    final mockRepo = MockRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screenshotRepositoryProvider.overrideWithValue(mockRepo),
          reviewQueueStreamProvider
              .overrideWith((ref) => Stream.value([testItem])),
        ],
        child: const MaterialApp(home: ReviewQueueScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TriageCard), findsOneWidget);
    expect(find.text('Vintage Dress Inspiration'), findsOneWidget);
    expect(find.text('Triage 1 of 1'), findsOneWidget);
    expect(find.text('Approve AI'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Approve
    await tester.ensureVisible(find.text('Approve AI'));
    await tester.tap(find.text('Approve AI'));
    await tester.pumpAndSettle();

    expect(mockRepo.approvedIds, contains('shot_triage_1'));
  });
}
