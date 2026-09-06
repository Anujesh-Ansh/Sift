import 'dart:io';
import 'dart:typed_data';
import 'models/screenshot_candidate.dart';

/// Abstract media source decoupling the app from the gallery implementation.
abstract class ScreenshotSource {
  /// Fetches paginated screenshot candidates discovered on the device.
  Future<List<ScreenshotCandidate>> fetchScreenshotCandidates({
    int page = 0,
    int size = 50,
    DateTime? since,
  });

  /// Retrieves the temporary file for the given source asset.
  Future<File?> getAssetFile(String assetId);

  /// Retrieves thumbnail bytes for fast UI rendering or fingerprinting.
  Future<Uint8List?> getThumbnailBytes(
    String assetId, {
    int width = 250,
    int height = 250,
  });

  /// Checks whether a previously indexed asset still exists on device.
  Future<bool> assetExists(String assetId);

  /// Permanently deletes an asset from device storage/gallery.
  /// Returns true if deletion succeeded.
  Future<bool> deleteAsset(String assetId);
}
