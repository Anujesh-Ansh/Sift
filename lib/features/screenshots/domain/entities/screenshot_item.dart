import 'processing_status.dart';

/// Primary domain entity representing an indexed or queued screenshot.
class ScreenshotItem {
  final String id;
  final String title;
  final String primaryCategory;
  final List<String> tags;
  final String extractedText;
  final String? userNote;
  final bool needsHumanContext;
  final ReviewStatus reviewStatus;
  final String? storagePath;
  final String? thumbnailStoragePath;
  final String? localThumbnailPath;
  final String sourceAssetId;
  final String contentHash;
  final DateTime sourceCreatedAt;
  final DateTime indexedAt;
  final DateTime updatedAt;
  final DateTime? scheduledDeletionDate;
  final int imageWidth;
  final int imageHeight;
  final int thumbnailWidth;
  final int thumbnailHeight;
  final int fileSizeBytes;
  final ProcessingStatus processingStatus;
  final String? errorMessage;
  final String modelVersion;
  final int schemaVersion;

  const ScreenshotItem({
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
    this.localThumbnailPath,
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

  ScreenshotItem copyWith({
    String? id,
    String? title,
    String? primaryCategory,
    List<String>? tags,
    String? extractedText,
    String? userNote,
    bool? needsHumanContext,
    ReviewStatus? reviewStatus,
    String? storagePath,
    String? thumbnailStoragePath,
    String? localThumbnailPath,
    String? sourceAssetId,
    String? contentHash,
    DateTime? sourceCreatedAt,
    DateTime? indexedAt,
    DateTime? updatedAt,
    DateTime? scheduledDeletionDate,
    bool clearScheduledDeletionDate = false,
    int? imageWidth,
    int? imageHeight,
    int? thumbnailWidth,
    int? thumbnailHeight,
    int? fileSizeBytes,
    ProcessingStatus? processingStatus,
    String? errorMessage,
    String? modelVersion,
    int? schemaVersion,
  }) {
    return ScreenshotItem(
      id: id ?? this.id,
      title: title ?? this.title,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      tags: tags ?? this.tags,
      extractedText: extractedText ?? this.extractedText,
      userNote: userNote ?? this.userNote,
      needsHumanContext: needsHumanContext ?? this.needsHumanContext,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      storagePath: storagePath ?? this.storagePath,
      thumbnailStoragePath: thumbnailStoragePath ?? this.thumbnailStoragePath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      sourceAssetId: sourceAssetId ?? this.sourceAssetId,
      contentHash: contentHash ?? this.contentHash,
      sourceCreatedAt: sourceCreatedAt ?? this.sourceCreatedAt,
      indexedAt: indexedAt ?? this.indexedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledDeletionDate: clearScheduledDeletionDate
          ? null
          : (scheduledDeletionDate ?? this.scheduledDeletionDate),
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      thumbnailWidth: thumbnailWidth ?? this.thumbnailWidth,
      thumbnailHeight: thumbnailHeight ?? this.thumbnailHeight,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      processingStatus: processingStatus ?? this.processingStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      modelVersion: modelVersion ?? this.modelVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  /// Remaining days before permanent deletion (for items in 'Delete' category).
  int? get daysUntilDeletion {
    if (scheduledDeletionDate == null) return null;
    final diff = scheduledDeletionDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
