import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/processing_status.dart';
import '../../domain/entities/screenshot_item.dart';
import '../../domain/repositories/screenshot_repository.dart';
import '../models/firestore_screenshot_dto.dart';

/// Production implementation of ScreenshotRepository querying Cloud Firestore.
class FirestoreScreenshotRepositoryImpl implements ScreenshotRepository {
  final FirebaseFirestore _firestore;
  final String _userId;
  static const _logger = AppLogger('FirestoreScreenshotRepositoryImpl');

  FirestoreScreenshotRepositoryImpl({
    FirebaseFirestore? firestore,
    required String userId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userId = userId;

  CollectionReference<Map<String, dynamic>> get _screenshotsCol =>
      _firestore.collection('users').doc(_userId).collection('screenshots');

  @override
  Stream<List<ScreenshotItem>> watchScreenshots({
    String? category,
    ReviewStatus? reviewStatus,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _screenshotsCol;

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('primary_category', isEqualTo: category);
    }

    if (reviewStatus != null) {
      query = query.where('review_status', isEqualTo: reviewStatus.name);
    }

    query = query.orderBy('source_created_at', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FirestoreScreenshotDto.fromFirestore(doc).toDomain();
      }).toList();
    }).handleError((e, st) {
      _logger.e('Error watching screenshots stream', e, st);
      throw FirestoreFailure('Error streaming screenshots from Firestore', e);
    });
  }

  @override
  Stream<List<ScreenshotItem>> watchReviewQueue({int limit = 50}) {
    final query = _screenshotsCol
        .where('needs_human_context', isEqualTo: true)
        .where('review_status', isEqualTo: ReviewStatus.pending.name)
        .orderBy('source_created_at', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FirestoreScreenshotDto.fromFirestore(doc).toDomain();
      }).toList();
    }).handleError((e, st) {
      _logger.e('Error streaming review queue', e, st);
      throw FirestoreFailure('Error streaming review queue', e);
    });
  }

  @override
  Future<ScreenshotItem?> getScreenshot(String id) async {
    try {
      final doc = await _screenshotsCol.doc(id).get();
      if (!doc.exists) return null;
      return FirestoreScreenshotDto.fromFirestore(doc).toDomain();
    } catch (e, st) {
      _logger.e('Error fetching screenshot $id', e, st);
      throw FirestoreFailure('Failed to fetch screenshot $id', e);
    }
  }

  @override
  Future<void> saveScreenshot(ScreenshotItem item) async {
    try {
      final dto = FirestoreScreenshotDto.fromDomain(item);
      await _screenshotsCol.doc(item.id).set(
            dto.toMap(),
            SetOptions(merge: true),
          );
      _logger.d('Saved screenshot ${item.id} to Firestore');
    } catch (e, st) {
      _logger.e('Failed to save screenshot ${item.id}', e, st);
      throw FirestoreFailure('Failed to save screenshot ${item.id}', e);
    }
  }

  @override
  Future<void> updateReviewStatus(
    String id, {
    required ReviewStatus status,
    String? correctedCategory,
    List<String>? tags,
    String? note,
  }) async {
    try {
      final updates = <String, dynamic>{
        'review_status': status.name,
        'needs_human_context': status == ReviewStatus.pending,
        'updated_at': Timestamp.now(),
      };

      if (correctedCategory != null && correctedCategory.isNotEmpty) {
        updates['primary_category'] = correctedCategory;
      }

      if (tags != null) {
        updates['tags'] = tags;
      }

      if (note != null) {
        updates['user_note'] = note;
      }

      await _screenshotsCol.doc(id).update(updates);
      _logger.i('Updated review status for screenshot $id: ${status.name}');
    } catch (e, st) {
      _logger.e('Failed to update review status for $id', e, st);
      throw FirestoreFailure('Failed to update review status for $id', e);
    }
  }

  @override
  Future<void> deleteScreenshot(String id) async {
    try {
      await _screenshotsCol.doc(id).delete();
      _logger.i('Deleted screenshot document $id from Firestore');
    } catch (e, st) {
      _logger.e('Failed to delete screenshot $id', e, st);
      throw FirestoreFailure('Failed to delete screenshot $id', e);
    }
  }

  @override
  Future<Set<String>> getIndexedAssetIds() async {
    try {
      final snapshot = await _screenshotsCol.get();

      final assetIds = snapshot.docs
          .map((doc) => doc.data()['source_asset_id'] as String?)
          .whereType<String>()
          .toSet();

      _logger.d(
          'Retrieved ${assetIds.length} indexed asset IDs for deduplication');
      return assetIds;
    } catch (e, st) {
      _logger.w('Failed to get indexed asset IDs: $e', e, st);
      return {};
    }
  }
}
