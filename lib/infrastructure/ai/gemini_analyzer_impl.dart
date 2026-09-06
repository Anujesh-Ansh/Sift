import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/logging/app_logger.dart';
import 'ai_response_parser.dart';
import 'screenshot_analyzer.dart';

/// Production Gemini Multimodal Vision implementation using google_generative_ai SDK.
class GeminiAnalyzerImpl implements ScreenshotAnalyzer {
  final GenerativeModel _model;
  static const _logger = AppLogger('GeminiAnalyzerImpl');

  static const _analysisPrompt = '''
You are an intelligent screenshot analyzer for Project Sift.
Analyze the provided screenshot image and return a strictly valid JSON object conforming to this exact schema:
{
  "title": "Short concise descriptive title of the screenshot (max 8 words)",
  "primary_category": "One of: Finance, Shopping, Work, Communication, Travel, Food, Entertainment, Education, Technology, Health, Documents, Social, Reference, Aesthetic, Other",
  "tags": ["3 to 8 lowercase micro-tags for deep search and filtering"],
  "extracted_text": "Accurate transcription of key visible text, headings, amounts, or labels in the screenshot",
  "needs_human_context": boolean (true if the screenshot contains subjective inspiration, ambiguous content, personal moodboards, or multiple conflicting categories; false if unambiguous)
}
Respond ONLY with the raw JSON object. Do not include markdown code fences or explanatory text.
''';

  GeminiAnalyzerImpl({
    required String apiKey,
    String modelName = AppConstants.defaultGeminiModel,
    GenerativeModel? model,
  }) : _model = model ??
            GenerativeModel(
              model: modelName,
              apiKey: apiKey,
              generationConfig: GenerationConfig(
                responseMimeType: 'application/json',
                temperature: 0.2,
              ),
            );

  @override
  Future<AnalysisResult> analyzeScreenshot({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      _logger.d(
          'Sending ${imageBytes.lengthInBytes} bytes to Gemini for multimodal analysis');

      final content = [
        Content.multi([
          TextPart(_analysisPrompt),
          DataPart(mimeType, imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.trim().isEmpty) {
        _logger.w(
            'Gemini returned an empty response. Falling back to default result.');
        return AnalysisResult.fallback();
      }

      _logger.i(
          'Received successful response from Gemini (${responseText.length} chars)');
      return AiResponseParser.parse(responseText);
    } on GenerativeAIException catch (e, st) {
      _logger.e('GenerativeAIException during analysis: ${e.message}', e, st);
      final isQuota = e.message.toLowerCase().contains('quota') ||
          e.message.toLowerCase().contains('rate limit') ||
          e.message.toLowerCase().contains('429');
      throw AiAnalysisFailure(
        'Gemini analysis error: ${e.message}',
        isRetryable: isQuota,
        cause: e,
      );
    } catch (e, st) {
      _logger.e('Unexpected error during Gemini analysis: $e', e, st);
      if (e is Failure) rethrow;
      throw AiAnalysisFailure('Failed to analyze screenshot: $e', cause: e);
    }
  }
}
