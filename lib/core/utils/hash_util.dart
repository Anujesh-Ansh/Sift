import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Utilities for hashing and content deduplication.
class HashUtil {
  HashUtil._();

  /// Computes a hex-encoded SHA-256 hash of the given byte array.
  static String computeSha256(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a deterministic screenshot ID based on source asset attributes.
  static String generateScreenshotId(
      String sourceAssetId, int createTimeMillis) {
    final rawKey = '$sourceAssetId-$createTimeMillis';
    final hash = sha256.convert(rawKey.codeUnits).toString();
    return 'sc_${hash.substring(0, 16)}';
  }
}
