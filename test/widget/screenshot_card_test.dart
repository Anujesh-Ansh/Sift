import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/features/screenshots/domain/entities/processing_status.dart';
import 'package:project_sift/features/screenshots/domain/entities/screenshot_item.dart';
import 'package:project_sift/features/screenshots/presentation/widgets/screenshot_card.dart';

void main() {
  testWidgets('ScreenshotCard renders title, category, tags, and handles tap',
      (WidgetTester tester) async {
    bool wasTapped = false;

    final item = ScreenshotItem(
      id: 'shot_1',
      title: 'Stripe Payment Receipt',
      primaryCategory: 'Finance',
      tags: const ['stripe', 'receipt', 'taxes'],
      extractedText: 'Amount \$99.00',
      needsHumanContext: false,
      reviewStatus: ReviewStatus.approved,
      sourceAssetId: 'asset_1',
      contentHash: 'hash_1',
      sourceCreatedAt: DateTime.now(),
      indexedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imageWidth: 1080,
      imageHeight: 1920,
      thumbnailWidth: 250,
      thumbnailHeight: 250,
      fileSizeBytes: 2048,
      processingStatus: ProcessingStatus.completed,
      modelVersion: 'gemini-1.5-flash',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: ScreenshotCard(
                item: item,
                onTap: () => wasTapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Stripe Payment Receipt'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('#stripe'), findsOneWidget);
    expect(find.text('#receipt'), findsOneWidget);

    await tester.tap(find.byType(ScreenshotCard));
    expect(wasTapped, isTrue);
  });

  testWidgets(
      'ScreenshotCard renders Review badge when needsHumanContext is true',
      (WidgetTester tester) async {
    final item = ScreenshotItem(
      id: 'shot_2',
      title: 'Vintage Dress Inspiration',
      primaryCategory: 'Aesthetic',
      tags: const ['vintage'],
      extractedText: '',
      needsHumanContext: true,
      reviewStatus: ReviewStatus.pending,
      sourceAssetId: 'asset_2',
      contentHash: 'hash_2',
      sourceCreatedAt: DateTime.now(),
      indexedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imageWidth: 1080,
      imageHeight: 1920,
      thumbnailWidth: 250,
      thumbnailHeight: 250,
      fileSizeBytes: 2048,
      processingStatus: ProcessingStatus.reviewRequired,
      modelVersion: 'gemini-1.5-flash',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: ScreenshotCard(
                item: item,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Review'), findsOneWidget);
  });
}
