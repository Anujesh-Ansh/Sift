import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/app_logger.dart';

/// Contract for uploading and managing screenshot media in cloud object storage.
abstract class StorageService {
  Future<({String imagePath, String thumbnailPath})> uploadScreenshotMedia({
    required String userId,
    required String screenshotId,
    required File imageFile,
    required File thumbnailFile,
  });

  Future<String?> getDownloadUrl(String storagePath);

  Future<void> deleteScreenshotMedia({
    required String userId,
    required String screenshotId,
  });
}

/// Production Firebase Cloud Storage implementation.
class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage;
  static const _logger = AppLogger('FirebaseStorageService');

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<({String imagePath, String thumbnailPath})> uploadScreenshotMedia({
    required String userId,
    required String screenshotId,
    required File imageFile,
    required File thumbnailFile,
  }) async {
    try {
      final imagePath = 'users/$userId/screenshots/$screenshotId/image.jpg';
      final thumbPath = 'users/$userId/screenshots/$screenshotId/thumbnail.jpg';

      _logger.d('Uploading media to $imagePath and $thumbPath');

      // 1. Upload compressed main image
      final imageRef = _storage.ref(imagePath);
      await imageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'screenshotId': screenshotId, 'userId': userId},
        ),
      );

      // 2. Upload thumbnail
      final thumbRef = _storage.ref(thumbPath);
      await thumbRef.putFile(
        thumbnailFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'screenshotId': screenshotId, 'userId': userId},
        ),
      );

      _logger.i('Successfully uploaded media for $screenshotId');
      return (imagePath: imagePath, thumbnailPath: thumbPath);
    } catch (e, st) {
      _logger.e('Failed to upload screenshot media for $screenshotId', e, st);
      throw FirebaseStorageFailure('Failed to upload media to storage', e);
    }
  }

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      return await ref.getDownloadURL();
    } catch (e, st) {
      _logger.w('Failed to get download URL for $storagePath', e, st);
      return null;
    }
  }

  @override
  Future<void> deleteScreenshotMedia({
    required String userId,
    required String screenshotId,
  }) async {
    try {
      final imagePath = 'users/$userId/screenshots/$screenshotId/image.jpg';
      final thumbPath = 'users/$userId/screenshots/$screenshotId/thumbnail.jpg';

      await _storage.ref(imagePath).delete().catchError((_) {});
      await _storage.ref(thumbPath).delete().catchError((_) {});

      _logger.i('Deleted storage objects for screenshot $screenshotId');
    } catch (e, st) {
      _logger.w(
          'Could not delete storage objects for $screenshotId: $e', e, st);
    }
  }
}
