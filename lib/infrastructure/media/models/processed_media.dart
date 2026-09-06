import 'dart:io';

/// Output from LocalPreprocessor containing compressed files and metrics.
class ProcessedMedia {
  final File compressedImageFile;
  final File thumbnailFile;
  final String contentHash;
  final int imageWidth;
  final int imageHeight;
  final int thumbnailWidth;
  final int thumbnailHeight;
  final int imageSizeBytes;
  final int thumbnailSizeBytes;

  const ProcessedMedia({
    required this.compressedImageFile,
    required this.thumbnailFile,
    required this.contentHash,
    required this.imageWidth,
    required this.imageHeight,
    required this.thumbnailWidth,
    required this.thumbnailHeight,
    required this.imageSizeBytes,
    required this.thumbnailSizeBytes,
  });

  /// Releases temporary disk files when no longer needed.
  /// Set [deleteThumbnail] to true to also purge the local thumbnail file.
  Future<void> dispose({bool deleteThumbnail = false}) async {
    try {
      if (await compressedImageFile.exists()) {
        await compressedImageFile.delete();
      }
      if (deleteThumbnail && await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    } catch (_) {}
  }
}
