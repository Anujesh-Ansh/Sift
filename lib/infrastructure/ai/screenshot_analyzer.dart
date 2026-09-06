import 'dart:typed_data';

/// Encapsulates the structured AI analysis output for a screenshot.
class AnalysisResult {
  final String title;
  final String primaryCategory;
  final List<String> tags;
  final String extractedText;
  final bool needsHumanContext;
  final String? rawResponse;

  const AnalysisResult({
    required this.title,
    required this.primaryCategory,
    required this.tags,
    required this.extractedText,
    required this.needsHumanContext,
    this.rawResponse,
  });

  /// Safe fallback result when AI analysis fails completely or is unavailable.
  factory AnalysisResult.fallback({
    String title = 'Unclassified Screenshot',
    String? rawResponse,
  }) {
    return AnalysisResult(
      title: title,
      primaryCategory: 'Other',
      tags: const ['unclassified', 'review_needed'],
      extractedText: '',
      needsHumanContext: true,
      rawResponse: rawResponse,
    );
  }

  AnalysisResult copyWith({
    String? title,
    String? primaryCategory,
    List<String>? tags,
    String? extractedText,
    bool? needsHumanContext,
    String? rawResponse,
  }) {
    return AnalysisResult(
      title: title ?? this.title,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      tags: tags ?? this.tags,
      extractedText: extractedText ?? this.extractedText,
      needsHumanContext: needsHumanContext ?? this.needsHumanContext,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }

  @override
  String toString() =>
      'AnalysisResult(title: "$title", category: $primaryCategory, tags: $tags, needsHumanContext: $needsHumanContext)';
}

/// Abstract contract for multimodal screenshot understanding.
abstract class ScreenshotAnalyzer {
  Future<AnalysisResult> analyzeScreenshot({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  });
}
