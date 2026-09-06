import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../providers/ingestion_providers.dart';

class ProcessingIndicatorBanner extends ConsumerWidget {
  const ProcessingIndicatorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeQueue = ref.watch(activeQueueStreamProvider);

    return activeQueue.when(
      data: (items) {
        final processingItems = items.values
            .where((item) => item.processingStatus.isProcessing)
            .toList();

        if (processingItems.isEmpty) {
          return const SizedBox.shrink();
        }

        final count = processingItems.length;
        final currentStage = processingItems.first.processingStatus.label;

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Processing $count screenshot${count > 1 ? 's' : ''} ($currentStage)...',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
