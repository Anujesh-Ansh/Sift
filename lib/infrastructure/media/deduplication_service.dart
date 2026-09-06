import 'dart:typed_data';
import '../../core/utils/hash_util.dart';

/// Manages duplicate detection across discovered media assets.
class DeduplicationService {
  final Set<String> _knownAssetIds = {};
  final Set<String> _knownContentHashes = {};

  /// Preloads already indexed asset IDs and content hashes from local cache or Firestore.
  void seedKnownRecords({
    Iterable<String>? assetIds,
    Iterable<String>? contentHashes,
  }) {
    if (assetIds != null) _knownAssetIds.addAll(assetIds);
    if (contentHashes != null) _knownContentHashes.addAll(contentHashes);
  }

  /// Checks whether an asset ID has already been indexed or queued.
  bool isKnownAssetId(String assetId) => _knownAssetIds.contains(assetId);

  /// Checks whether an asset content hash already exists.
  bool isKnownHash(String hash) => _knownContentHashes.contains(hash);

  /// Records an asset ID and its hash once queued or processed.
  void recordAsset(String assetId, String contentHash) {
    _knownAssetIds.add(assetId);
    _knownContentHashes.add(contentHash);
  }

  /// Computes a fast SHA-256 fingerprint from asset thumbnail or header bytes.
  String computeContentHash(Uint8List bytes) {
    return HashUtil.computeSha256(bytes);
  }

  /// Generates a deterministic fingerprint string based on metadata.
  String generateMetadataFingerprint({
    required String assetId,
    required DateTime createDateTime,
    required int width,
    required int height,
  }) {
    final rawKey =
        '$assetId-${createDateTime.millisecondsSinceEpoch}-$width-$height';
    return HashUtil.generateScreenshotId(
        rawKey, createDateTime.millisecondsSinceEpoch);
  }

  /// Removes an asset reference (e.g. when deleted from storage and cloud).
  void removeAsset(String assetId, [String? contentHash]) {
    _knownAssetIds.remove(assetId);
    if (contentHash != null) {
      _knownContentHashes.remove(contentHash);
    }
  }

  int get totalIndexedAssets => _knownAssetIds.length;
}
