import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/infrastructure/media/deduplication_service.dart';

void main() {
  group('DeduplicationService Unit Tests', () {
    late DeduplicationService service;

    setUp(() {
      service = DeduplicationService();
    });

    test('should report unknown asset as not known', () {
      expect(service.isKnownAssetId('asset_1'), isFalse);
      expect(service.isKnownHash('hash_1'), isFalse);
    });

    test('should record and identify known asset and hash', () {
      service.recordAsset('asset_1', 'hash_abc');
      expect(service.isKnownAssetId('asset_1'), isTrue);
      expect(service.isKnownHash('hash_abc'), isTrue);
      expect(service.totalIndexedAssets, equals(1));
    });

    test('should seed existing records correctly', () {
      service.seedKnownRecords(
        assetIds: ['asset_10', 'asset_20'],
        contentHashes: ['hash_10', 'hash_20'],
      );
      expect(service.isKnownAssetId('asset_10'), isTrue);
      expect(service.isKnownAssetId('asset_20'), isTrue);
      expect(service.isKnownHash('hash_10'), isTrue);
      expect(service.isKnownHash('hash_20'), isTrue);
      expect(service.isKnownAssetId('asset_30'), isFalse);
    });

    test('should compute deterministic SHA-256 hash', () {
      final bytes1 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bytes2 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bytes3 = Uint8List.fromList([5, 4, 3, 2, 1]);

      final hash1 = service.computeContentHash(bytes1);
      final hash2 = service.computeContentHash(bytes2);
      final hash3 = service.computeContentHash(bytes3);

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
      expect(hash1.length, equals(64)); // 256 bits = 64 hex chars
    });

    test('should remove assets on demand', () {
      service.recordAsset('asset_to_delete', 'hash_to_delete');
      expect(service.isKnownAssetId('asset_to_delete'), isTrue);

      service.removeAsset('asset_to_delete', 'hash_to_delete');
      expect(service.isKnownAssetId('asset_to_delete'), isFalse);
      expect(service.isKnownHash('hash_to_delete'), isFalse);
    });
  });
}
