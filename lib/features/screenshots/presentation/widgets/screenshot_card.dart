import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
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
                        color: item.primaryCategory == 'Delete'
                            ? AppColors.error.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.65),
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(
                          color: item.primaryCategory == 'Delete'
                              ? AppColors.error
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.primaryCategory == 'Delete') ...[
                            const Icon(
                              Icons.delete_outline,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            item.primaryCategory,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Delete Category / Retention countdown badge
                  if (item.primaryCategory == 'Delete')
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: AppSpacing.roundedSm,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.daysUntilDeletion != null
                                  ? '${item.daysUntilDeletion}d left'
                                  : '30d left',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Review Required badge
                  else if (item.needsHumanContext ||
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

  static final Map<String, Uint8List?> _thumbnailMemoryCache = {};

  Widget _buildThumbnail() {
    if (item.localThumbnailPath != null &&
        item.localThumbnailPath!.isNotEmpty) {
      final file = File(item.localThumbnailPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAssetThumbnail(),
        );
      }
    }

    return _buildAssetThumbnail();
  }

  Widget _buildAssetThumbnail() {
    if (item.sourceAssetId.isEmpty) {
      return _buildPlaceholder();
    }

    if (_thumbnailMemoryCache.containsKey(item.sourceAssetId)) {
      final cachedBytes = _thumbnailMemoryCache[item.sourceAssetId];
      if (cachedBytes != null) {
        return Image.memory(
          cachedBytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
      return _buildPlaceholder();
    }

    return FutureBuilder<Uint8List?>(
      future: _fetchAssetThumbnailBytes(item.sourceAssetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          );
        }
        return _buildPlaceholder();
      },
    );
  }

  Future<Uint8List?> _fetchAssetThumbnailBytes(String assetId) async {
    try {
      final asset = await AssetEntity.fromId(assetId);
      final bytes = await asset?.thumbnailDataWithSize(
        const ThumbnailSize(300, 300),
        quality: 80,
      );
      _thumbnailMemoryCache[assetId] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
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
