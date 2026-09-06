import 'dart:typed_data';

/// Represents a newly discovered media asset candidate from the gallery.
class ScreenshotCandidate {
  final String id;
  final String title;
  final DateTime createDateTime;
  final DateTime modifiedDateTime;
  final int width;
  final int height;
  final Uint8List? thumbnailBytes;

  const ScreenshotCandidate({
    required this.id,
    required this.title,
    required this.createDateTime,
    required this.modifiedDateTime,
    required this.width,
    required this.height,
    this.thumbnailBytes,
  });
}
