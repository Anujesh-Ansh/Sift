import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/processing_status.dart';
import '../../domain/entities/screenshot_item.dart';

class ScreenshotCard extends StatelessWidget {
  final ScreenshotItem item;
  final VoidCallback onTap;

  const ScreenshotCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDimensions = item.imageWidth > 0 && item.imageHeight > 0;
    final aspectRatio = hasDimensions
        ? (item.imageWidth / item.imageHeight).clamp(0.6, 1.4)
        : 0.8;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: item.needsHumanContext
                ? AppColors.warning.withValues(alpha: 0.5)
                : AppColors.darkBorder,
            width: item.needsHumanContext ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail container with aspect ratio
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(),
                  // Category tag overlay
                  Positioned(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs + 2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        item.primaryCategory,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ),
                  ),
                  // Review Required badge
                  if (item.needsHumanContext ||
                      item.processingStatus == ProcessingStatus.reviewRequired)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.9),
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.help_outline,
                              size: 10,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Review',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // In-flight processing overlay
                  if (item.processingStatus.isProcessing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              item.processingStatus.label,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Metadata section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.isNotEmpty ? item.title : 'Untitled Screenshot',
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: item.tags.take(3).map((tag) {
                        return Text(
                          '#$tag',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textTertiaryDark,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (item.localThumbnailPath != null &&
        item.localThumbnailPath!.isNotEmpty) {
      final file = File(item.localThumbnailPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.darkBackground,
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          color: AppColors.textTertiaryDark,
          size: 32,
        ),
      ),
    );
  }
}
