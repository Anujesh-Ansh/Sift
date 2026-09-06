import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/hash_util.dart';
import 'models/processed_media.dart';

/// Preprocesses raw screenshot media into optimized JPEG images and thumbnails.
class LocalPreprocessor {
  static const _logger = AppLogger('LocalPreprocessor');

  /// Preprocesses a raw source file: resizes, compresses, and generates a thumbnail.
  Future<ProcessedMedia> processImageFile({
    required File sourceFile,
    required String assetId,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedImagePath =
          '${tempDir.path}/${assetId}_opt_$timestamp.jpg';
      final thumbnailPath = '${tempDir.path}/${assetId}_thumb_$timestamp.jpg';

      _logger.d(
          'Compressing image: ${sourceFile.path} (target max dim: ${AppConstants.maxImageDimension})');

      // 1. Compress main image
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        sourceFile.path,
        compressedImagePath,
        minWidth: AppConstants.maxImageDimension,
        minHeight: AppConstants.maxImageDimension,
        quality: AppConstants.imageJpegQuality,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        throw const CompressionFailure(
            'FlutterImageCompress failed to produce main image');
      }

      final compressedFile = File(compressedXFile.path);
      final compressedBytes = await compressedFile.readAsBytes();
      final contentHash = HashUtil.computeSha256(compressedBytes);

      // 2. Generate thumbnail
      final thumbnailXFile = await FlutterImageCompress.compressAndGetFile(
        sourceFile.path,
        thumbnailPath,
        minWidth: AppConstants.thumbnailDimension,
        minHeight: AppConstants.thumbnailDimension,
        quality: AppConstants.thumbnailJpegQuality,
        format: CompressFormat.jpeg,
      );

      if (thumbnailXFile == null) {
        throw const CompressionFailure(
            'FlutterImageCompress failed to produce thumbnail');
      }

      final thumbFile = File(thumbnailXFile.path);

      _logger.i(
          'Successfully compressed $assetId. Image: ${compressedBytes.length}B, Hash: ${contentHash.substring(0, 10)}...');

      return ProcessedMedia(
        compressedImageFile: compressedFile,
        thumbnailFile: thumbFile,
        contentHash: contentHash,
        imageWidth: AppConstants.maxImageDimension,
        imageHeight: AppConstants.maxImageDimension,
        thumbnailWidth: AppConstants.thumbnailDimension,
        thumbnailHeight: AppConstants.thumbnailDimension,
        imageSizeBytes: compressedBytes.length,
        thumbnailSizeBytes: await thumbFile.length(),
      );
    } catch (e, st) {
      _logger.e('Error preprocessing image for asset: $assetId', e, st);
      throw CompressionFailure('Failed to compress media for $assetId', e);
    }
  }

  /// Direct fallback for raw Uint8List bytes (useful in unit tests & mock scenarios).
  Future<ProcessedMedia> processBytes({
    required Uint8List rawBytes,
    required String assetId,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedImagePath =
          '${tempDir.path}/${assetId}_bopt_$timestamp.jpg';
      final thumbnailPath = '${tempDir.path}/${assetId}_bthumb_$timestamp.jpg';

      final compressedBytes = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: AppConstants.maxImageDimension,
        minHeight: AppConstants.maxImageDimension,
        quality: AppConstants.imageJpegQuality,
        format: CompressFormat.jpeg,
      );

      final thumbBytes = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth: AppConstants.thumbnailDimension,
        minHeight: AppConstants.thumbnailDimension,
        quality: AppConstants.thumbnailJpegQuality,
        format: CompressFormat.jpeg,
      );

      final compressedFile =
          await File(compressedImagePath).writeAsBytes(compressedBytes);
      final thumbFile = await File(thumbnailPath).writeAsBytes(thumbBytes);
      final contentHash = HashUtil.computeSha256(compressedBytes);

      return ProcessedMedia(
        compressedImageFile: compressedFile,
        thumbnailFile: thumbFile,
        contentHash: contentHash,
        imageWidth: AppConstants.maxImageDimension,
        imageHeight: AppConstants.maxImageDimension,
        thumbnailWidth: AppConstants.thumbnailDimension,
        thumbnailHeight: AppConstants.thumbnailDimension,
        imageSizeBytes: compressedBytes.length,
        thumbnailSizeBytes: thumbBytes.length,
      );
    } catch (e, st) {
      _logger.e('Failed to process bytes for asset: $assetId', e, st);
      throw CompressionFailure('Failed to compress raw bytes for $assetId', e);
    }
  }
}
