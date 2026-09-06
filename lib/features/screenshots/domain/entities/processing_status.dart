/// Processing state machine stages for a screenshot.
enum ProcessingStatus {
  discovered,
  queued,
  compressing,
  uploaded,
  analyzing,
  indexed,
  reviewRequired,
  completed,
  failedRetryable,
  failedPermanent;

  String get label {
    switch (this) {
      case ProcessingStatus.discovered:
        return 'Discovered';
      case ProcessingStatus.queued:
        return 'Queued';
      case ProcessingStatus.compressing:
        return 'Compressing';
      case ProcessingStatus.uploaded:
        return 'Uploaded';
      case ProcessingStatus.analyzing:
        return 'Analyzing';
      case ProcessingStatus.indexed:
        return 'Indexed';
      case ProcessingStatus.reviewRequired:
        return 'Review Required';
      case ProcessingStatus.completed:
        return 'Completed';
      case ProcessingStatus.failedRetryable:
        return 'Failed (Retrying)';
      case ProcessingStatus.failedPermanent:
        return 'Failed';
    }
  }

  bool get isProcessing =>
      this == ProcessingStatus.queued ||
      this == ProcessingStatus.compressing ||
      this == ProcessingStatus.uploaded ||
      this == ProcessingStatus.analyzing;

  bool get isFailure =>
      this == ProcessingStatus.failedRetryable ||
      this == ProcessingStatus.failedPermanent;
}

/// Human review status for ambiguous/low-confidence classifications.
enum ReviewStatus {
  pending,
  approved,
  corrected,
  skipped;

  String get label {
    switch (this) {
      case ReviewStatus.pending:
        return 'Pending Review';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.corrected:
        return 'Corrected';
      case ReviewStatus.skipped:
        return 'Skipped';
    }
  }
}
