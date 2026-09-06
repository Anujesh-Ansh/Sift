/// Base failure abstraction for Project Sift domain logic.
abstract class Failure {
  final String message;
  final Object? cause;

  const Failure(this.message, [this.cause]);

  @override
  String toString() =>
      '$runtimeType: $message ${cause != null ? '($cause)' : ''}';
}

/// Ingestion or media permission failures
class MediaPermissionFailure extends Failure {
  const MediaPermissionFailure(super.message, [super.cause]);
}

class MediaSourceFailure extends Failure {
  const MediaSourceFailure(super.message, [super.cause]);
}

class CompressionFailure extends Failure {
  const CompressionFailure(super.message, [super.cause]);
}

/// Firebase failures
class FirebaseStorageFailure extends Failure {
  const FirebaseStorageFailure(super.message, [super.cause]);
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message, [super.cause]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.cause]);
}

/// Gemini AI failures
class AiAnalysisFailure extends Failure {
  final bool isRetryable;
  const AiAnalysisFailure(String message,
      {this.isRetryable = true, Object? cause})
      : super(message, cause);
}

class AiParsingFailure extends Failure {
  const AiParsingFailure(super.message, [super.cause]);
}
