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
  Future<void> dispose() async {
    try {
      if (await compressedImageFile.exists()) {
        await compressedImageFile.delete();
      }
    } catch (_) {}
  }
}
