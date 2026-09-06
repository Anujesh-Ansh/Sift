import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/processing_status.dart';
import '../../domain/entities/screenshot_item.dart';

/// Data Transfer Object mapping ScreenshotItem to/from Cloud Firestore documents.
class FirestoreScreenshotDto {
  final String id;
  final String title;
  final String primaryCategory;
  final List<String> tags;
  final String extractedText;
  final String? userNote;
  final bool needsHumanContext;
  final String reviewStatus;
  final String? storagePath;
  final String? thumbnailStoragePath;
  final String sourceAssetId;
  final String contentHash;
  final Timestamp sourceCreatedAt;
  final Timestamp indexedAt;
  final Timestamp updatedAt;
  final Timestamp? scheduledDeletionDate;
  final int imageWidth;
  final int imageHeight;
  final int thumbnailWidth;
  final int thumbnailHeight;
  final int fileSizeBytes;
  final String processingStatus;
  final String? errorMessage;
  final String modelVersion;
  final int schemaVersion;

  const FirestoreScreenshotDto({
    required this.id,
    required this.title,
    required this.primaryCategory,
    required this.tags,
    required this.extractedText,
    this.userNote,
    required this.needsHumanContext,
    required this.reviewStatus,
    this.storagePath,
    this.thumbnailStoragePath,
    required this.sourceAssetId,
    required this.contentHash,
    required this.sourceCreatedAt,
    required this.indexedAt,
    required this.updatedAt,
    this.scheduledDeletionDate,
    required this.imageWidth,
    required this.imageHeight,
    required this.thumbnailWidth,
    required this.thumbnailHeight,
    required this.fileSizeBytes,
    required this.processingStatus,
    this.errorMessage,
    required this.modelVersion,
    this.schemaVersion = 1,
  });

  factory FirestoreScreenshotDto.fromDomain(ScreenshotItem item) {
    return FirestoreScreenshotDto(
      id: item.id,
      title: item.title,
      primaryCategory: item.primaryCategory,
      tags: item.tags,
      extractedText: item.extractedText,
      userNote: item.userNote,
      needsHumanContext: item.needsHumanContext,
      reviewStatus: item.reviewStatus.name,
      storagePath: item.storagePath,
      thumbnailStoragePath: item.thumbnailStoragePath,
      sourceAssetId: item.sourceAssetId,
      contentHash: item.contentHash,
      sourceCreatedAt: Timestamp.fromDate(item.sourceCreatedAt),
      indexedAt: Timestamp.fromDate(item.indexedAt),
      updatedAt: Timestamp.fromDate(item.updatedAt),
      scheduledDeletionDate: item.scheduledDeletionDate != null
          ? Timestamp.fromDate(item.scheduledDeletionDate!)
          : null,
      imageWidth: item.imageWidth,
      imageHeight: item.imageHeight,
      thumbnailWidth: item.thumbnailWidth,
      thumbnailHeight: item.thumbnailHeight,
      fileSizeBytes: item.fileSizeBytes,
      processingStatus: item.processingStatus.name,
      errorMessage: item.errorMessage,
      modelVersion: item.modelVersion,
      schemaVersion: item.schemaVersion,
    );
  }

  ScreenshotItem toDomain({String? localThumbnailPath}) {
    return ScreenshotItem(
      id: id,
      title: title,
      primaryCategory: primaryCategory,
      tags: tags,
      extractedText: extractedText,
      userNote: userNote,
      needsHumanContext: needsHumanContext,
      reviewStatus: _parseReviewStatus(reviewStatus),
      storagePath: storagePath,
      thumbnailStoragePath: thumbnailStoragePath,
      localThumbnailPath: localThumbnailPath,
      sourceAssetId: sourceAssetId,
      contentHash: contentHash,
      sourceCreatedAt: sourceCreatedAt.toDate(),
      indexedAt: indexedAt.toDate(),
      updatedAt: updatedAt.toDate(),
      scheduledDeletionDate: scheduledDeletionDate?.toDate(),
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      thumbnailWidth: thumbnailWidth,
      thumbnailHeight: thumbnailHeight,
      fileSizeBytes: fileSizeBytes,
      processingStatus: _parseProcessingStatus(processingStatus),
      errorMessage: errorMessage,
      modelVersion: modelVersion,
      schemaVersion: schemaVersion,
    );
  }

  factory FirestoreScreenshotDto.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return FirestoreScreenshotDto.fromMap(snapshot.id, data);
  }

  factory FirestoreScreenshotDto.fromMap(
      String docId, Map<String, dynamic> data) {
    return FirestoreScreenshotDto(
      id: docId,
      title: data['title'] as String? ?? 'Untitled Screenshot',
      primaryCategory: data['primary_category'] as String? ?? 'Other',
      tags:
          (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      extractedText: data['extracted_text'] as String? ?? '',
      userNote: data['user_note'] as String?,
      needsHumanContext: data['needs_human_context'] as bool? ?? false,
      reviewStatus: data['review_status'] as String? ?? 'pending',
      storagePath: data['storage_path'] as String?,
      thumbnailStoragePath: data['thumbnail_storage_path'] as String?,
      sourceAssetId: data['source_asset_id'] as String? ?? '',
      contentHash: data['content_hash'] as String? ?? '',
      sourceCreatedAt: data['source_created_at'] is Timestamp
          ? data['source_created_at'] as Timestamp
          : Timestamp.now(),
      indexedAt: data['indexed_at'] is Timestamp
          ? data['indexed_at'] as Timestamp
          : Timestamp.now(),
      updatedAt: data['updated_at'] is Timestamp
          ? data['updated_at'] as Timestamp
          : Timestamp.now(),
      scheduledDeletionDate: data['scheduled_deletion_date'] is Timestamp
          ? data['scheduled_deletion_date'] as Timestamp
          : (data['scheduled_deletion_date'] is String
              ? Timestamp.fromDate(
                  DateTime.parse(data['scheduled_deletion_date']))
              : null),
      imageWidth: (data['image_width'] as num?)?.toInt() ?? 0,
      imageHeight: (data['image_height'] as num?)?.toInt() ?? 0,
      thumbnailWidth: (data['thumbnail_width'] as num?)?.toInt() ?? 0,
      thumbnailHeight: (data['thumbnail_height'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (data['file_size_bytes'] as num?)?.toInt() ?? 0,
      processingStatus: data['processing_status'] as String? ?? 'discovered',
      errorMessage: data['error_message'] as String?,
      modelVersion: data['model_version'] as String? ?? 'gemini-1.5-flash',
      schemaVersion: (data['schema_version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'primary_category': primaryCategory,
      'tags': tags,
      'extracted_text': extractedText,
      'user_note': userNote,
      'needs_human_context': needsHumanContext,
      'review_status': reviewStatus,
      'storage_path': storagePath,
      'thumbnail_storage_path': thumbnailStoragePath,
      'source_asset_id': sourceAssetId,
      'content_hash': contentHash,
      'source_created_at': sourceCreatedAt,
      'indexed_at': indexedAt,
      'updated_at': updatedAt,
      'scheduled_deletion_date': scheduledDeletionDate,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'thumbnail_width': thumbnailWidth,
      'thumbnail_height': thumbnailHeight,
      'file_size_bytes': fileSizeBytes,
      'processing_status': processingStatus,
      'error_message': errorMessage,
      'model_version': modelVersion,
      'schema_version': schemaVersion,
    };
  }

  static ReviewStatus _parseReviewStatus(String status) {
    return ReviewStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => ReviewStatus.pending,
    );
  }

  static ProcessingStatus _parseProcessingStatus(String status) {
    return ProcessingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => ProcessingStatus.discovered,
    );
  }
}
