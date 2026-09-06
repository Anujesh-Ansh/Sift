import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/processing_status.dart';
import '../../domain/entities/screenshot_item.dart';
import '../../domain/repositories/screenshot_repository.dart';
import '../models/firestore_screenshot_dto.dart';

/// Production implementation of ScreenshotRepository with Local-First memory caching
/// and graceful offline Cloud Firestore synchronization.
class FirestoreScreenshotRepositoryImpl implements ScreenshotRepository {
  final FirebaseFirestore? _firestore;
  final String _userId;
  static const _logger = AppLogger('FirestoreScreenshotRepositoryImpl');

  // Shared in-memory store for instant local reactivity & offline fallback
  static final Map<String, ScreenshotItem> _localStore = {};
  static final StreamController<void> _updatesController =
      StreamController<void>.broadcast();

  static FirebaseFirestore? _safeGetFirestore([FirebaseFirestore? custom]) {
    if (custom != null) return custom;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirestoreScreenshotRepositoryImpl({
    FirebaseFirestore? firestore,
    required String userId,
  })  : _firestore = _safeGetFirestore(firestore),
        _userId = userId;

  CollectionReference<Map<String, dynamic>>? get _screenshotsCol {
    final fs = _firestore;
    if (fs == null) return null;
    try {
      return fs.collection('users').doc(_userId).collection('screenshots');
    } catch (_) {
      return null;
    }
  }

  List<ScreenshotItem> _filterLocal({
    String? category,
    ReviewStatus? reviewStatus,
    int limit = 100,
  }) {
    var items = _localStore.values.toList();
    if (category != null && category.isNotEmpty && category != 'All') {
      items = items.where((i) => i.primaryCategory == category).toList();
    }
    if (reviewStatus != null) {
      items = items.where((i) => i.reviewStatus == reviewStatus).toList();
    }
    items.sort((a, b) => b.sourceCreatedAt.compareTo(a.sourceCreatedAt));
    return items.take(limit).toList();
  }

  @override
  Stream<List<ScreenshotItem>> watchScreenshots({
    String? category,
    ReviewStatus? reviewStatus,
    int limit = 100,
  }) {
    final controller = StreamController<List<ScreenshotItem>>();

    void emitCurrent() {
      if (!controller.isClosed) {
        controller.add(_filterLocal(
          category: category,
          reviewStatus: reviewStatus,
          limit: limit,
        ));
      }
    }

    // 1. Emit local cache immediately
    emitCurrent();

    // 2. Listen to local cache updates
    final localSub = _updatesController.stream.listen((_) => emitCurrent());

    // 3. Listen to Firestore when available
    StreamSubscription? firestoreSub;
    final col = _screenshotsCol;
    if (col != null) {
      try {
        Query<Map<String, dynamic>> query = col;
        if (category != null && category.isNotEmpty && category != 'All') {
          query = query.where('primary_category', isEqualTo: category);
        }
        if (reviewStatus != null) {
          query = query.where('review_status', isEqualTo: reviewStatus.name);
        }
        query = query.orderBy('source_created_at', descending: true).limit(limit);

        firestoreSub = query.snapshots().listen((snapshot) {
          for (final doc in snapshot.docs) {
            final item = FirestoreScreenshotDto.fromFirestore(doc).toDomain();
            _localStore[item.id] = item;
          }
          emitCurrent();
        }, onError: (e) {
          _logger.w(
              'Firestore stream encountered error ($e). Continuing with local cache.');
          emitCurrent();
        });
      } catch (e) {
        _logger.w(
            'Firestore query setup skipped or unavailable ($e). Using local cache.');
      }
    }

    controller.onCancel = () {
      localSub.cancel();
      firestoreSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<ScreenshotItem>> watchReviewQueue({int limit = 50}) {
    final controller = StreamController<List<ScreenshotItem>>();

    void emitCurrent() {
      if (!controller.isClosed) {
        final items = _localStore.values
            .where((i) =>
                i.needsHumanContext && i.reviewStatus == ReviewStatus.pending)
            .toList();
        items.sort((a, b) => b.sourceCreatedAt.compareTo(a.sourceCreatedAt));
        controller.add(items.take(limit).toList());
      }
    }

    emitCurrent();
    final localSub = _updatesController.stream.listen((_) => emitCurrent());

    StreamSubscription? firestoreSub;
    final col = _screenshotsCol;
    if (col != null) {
      try {
        final query = col
            .where('needs_human_context', isEqualTo: true)
            .where('review_status', isEqualTo: ReviewStatus.pending.name)
            .orderBy('source_created_at', descending: true)
            .limit(limit);

        firestoreSub = query.snapshots().listen((snapshot) {
          for (final doc in snapshot.docs) {
            final item = FirestoreScreenshotDto.fromFirestore(doc).toDomain();
            _localStore[item.id] = item;
          }
          emitCurrent();
        }, onError: (e) {
          _logger.w(
              'Firestore review stream error ($e). Continuing with local cache.');
          emitCurrent();
        });
      } catch (e) {
        _logger.w('Firestore review query unavailable ($e). Using local cache.');
      }
    }

    controller.onCancel = () {
      localSub.cancel();
      firestoreSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<ScreenshotItem?> getScreenshot(String id) async {
    if (_localStore.containsKey(id)) {
      return _localStore[id];
    }
    final col = _screenshotsCol;
    if (col == null) return null;
    try {
      final doc = await col.doc(id).get();
      if (!doc.exists) return null;
      final item = FirestoreScreenshotDto.fromFirestore(doc).toDomain();
      _localStore[id] = item;
      return item;
    } catch (e, st) {
      _logger.w('Error fetching screenshot $id from Firestore: $e', e, st);
      return _localStore[id];
    }
  }

  static bool _firestoreWriteDisabled = false;

  @override
  Future<void> saveScreenshot(ScreenshotItem item) async {
    // 1. Immediately update local store
    _localStore[item.id] = item;
    _updatesController.add(null);
    _logger.i('Saved screenshot ${item.id} to local repository cache');

    final col = _screenshotsCol;
    if (_firestoreWriteDisabled || col == null) return;

    // 2. Asynchronously synchronize to Cloud Firestore with 3s timeout
    try {
      final dto = FirestoreScreenshotDto.fromDomain(item);
      await col
          .doc(item.id)
          .set(
            dto.toMap(),
            SetOptions(merge: true),
          )
          .timeout(const Duration(seconds: 3));
      _logger.d('Successfully synchronized screenshot ${item.id} to Firestore');
    } catch (e, st) {
      _firestoreWriteDisabled = true;
      _logger.w(
          'Firestore cloud sync skipped or failed ($e). Activating local-first storage mode.',
          e,
          st);
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
    // 1. Update local cache
    final existing = _localStore[id];
    if (existing != null) {
      _localStore[id] = existing.copyWith(
        reviewStatus: status,
        needsHumanContext: status == ReviewStatus.pending,
        primaryCategory: correctedCategory ?? existing.primaryCategory,
        tags: tags ?? existing.tags,
        userNote: note ?? existing.userNote,
        updatedAt: DateTime.now(),
      );
      _updatesController.add(null);
    }

    // 2. Synchronize to Firestore
    final col = _screenshotsCol;
    if (col != null) {
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

        await col.doc(id).update(updates);
        _logger.i('Updated review status for screenshot $id: ${status.name}');
      } catch (e, st) {
        _logger.w('Cloud review status update skipped ($e). Saved locally.', e, st);
      }
    }
  }

  @override
  Future<void> deleteScreenshot(String id) async {
    _localStore.remove(id);
    _updatesController.add(null);

    final col = _screenshotsCol;
    if (col != null) {
      try {
        await col.doc(id).delete();
        _logger.i('Deleted screenshot document $id from Firestore');
      } catch (e, st) {
        _logger.w('Cloud delete skipped ($e). Deleted locally.', e, st);
      }
    }
  }

  @override
  Future<Set<String>> getIndexedAssetIds() async {
    final localIds = _localStore.values
        .map((doc) => doc.sourceAssetId)
        .whereType<String>()
        .toSet();

    final col = _screenshotsCol;
    if (col != null) {
      try {
        final snapshot = await col.get();
        final cloudIds = snapshot.docs
            .map((doc) => doc.data()['source_asset_id'] as String?)
            .whereType<String>()
            .toSet();
        return {...localIds, ...cloudIds};
      } catch (e) {
        return localIds;
      }
    }
    return localIds;
  }

  @override
  Future<List<ScreenshotItem>> getScreenshotsPendingDeletion() async {
    final col = _screenshotsCol;
    if (col != null) {
      try {
        final snapshot = await col
            .where('primary_category', isEqualTo: 'Delete')
            .get();
        for (final doc in snapshot.docs) {
          final item = FirestoreScreenshotDto.fromFirestore(doc).toDomain();
          _localStore[item.id] = item;
        }
      } catch (e) {
        _logger.w('Cloud query for pending deletions skipped ($e). Using local store.');
      }
    }

    return _localStore.values.where((i) {
      return i.primaryCategory == 'Delete' ||
          i.scheduledDeletionDate != null;
    }).toList();
  }
}
