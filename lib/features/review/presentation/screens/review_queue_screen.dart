import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../screenshots/domain/entities/processing_status.dart';
import '../../../screenshots/providers/screenshot_providers.dart';
import '../widgets/triage_card.dart';

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(reviewQueueStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Human Review Queue', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Queue',
            onPressed: () => ref.invalidate(reviewQueueStreamProvider),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: queueAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState();
          }

          if (_currentIndex >= items.length) {
            _currentIndex = 0;
          }

          final currentItem = items[_currentIndex];

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: TriageCard(
                  key: ValueKey(currentItem.id),
                  item: currentItem,
                  currentIndex: _currentIndex,
                  totalCount: items.length,
                  onApprove: () async {
                    final repo = ref.read(screenshotRepositoryProvider);
                    await repo.updateReviewStatus(
                      currentItem.id,
                      status: ReviewStatus.approved,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Screenshot approved!'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onCorrect: (cat, tags, note) async {
                    if (cat == 'Delete') {
                      final autoDel = ref.read(autoDeletionServiceProvider);
                      await autoDel.moveToDelete(currentItem.copyWith(
                        reviewStatus: ReviewStatus.corrected,
                        tags: tags,
                        userNote: note,
                        needsHumanContext: false,
                      ));
                    } else {
                      final repo = ref.read(screenshotRepositoryProvider);
                      await repo.updateReviewStatus(
                        currentItem.id,
                        status: ReviewStatus.corrected,
                        correctedCategory: cat,
                        tags: tags,
                        note: note,
                      );
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(cat == 'Delete'
                            ? 'Moved to Delete (auto-deletes in 30 days)'
                            : 'Classification updated!'),
                        backgroundColor: cat == 'Delete'
                            ? AppColors.error
                            : AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onSkip: () {
                    setState(() {
                      if (_currentIndex < items.length - 1) {
                        _currentIndex++;
                      } else {
                        _currentIndex = 0;
                      }
                    });
                  },
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text('Error loading queue: $e',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(reviewQueueStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Icon(
              Icons.done_all,
              size: 48,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('All Caught Up!', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Screenshots requiring human context or subjective categorization will appear here for 1-tap triage.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
