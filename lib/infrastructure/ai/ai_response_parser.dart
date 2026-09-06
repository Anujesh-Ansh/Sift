import 'dart:convert';
import '../../core/logging/app_logger.dart';
import 'category_classifier.dart';
import 'screenshot_analyzer.dart';

/// Resilient parser for structured multimodal AI responses.
/// Tolerates markdown fences, partial JSON, unescaped characters, and missing fields.
class AiResponseParser {
  static const _logger = AppLogger('AiResponseParser');

  /// Parses raw LLM text into an [AnalysisResult].
  /// Never throws an exception; gracefully degrades to [AnalysisResult.fallback].
  static AnalysisResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      _logger.w('Empty AI response received, returning fallback');
      return AnalysisResult.fallback(rawResponse: rawText);
    }

    try {
      final jsonString = _extractJson(rawText);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        _logger.w('Decoded JSON is not a map: $decoded');
        return AnalysisResult.fallback(rawResponse: rawText);
      }

      return _buildResultFromMap(decoded, rawText);
    } catch (e, st) {
      _logger.w(
          'Failed to parse AI JSON response directly: $e. Attempting repair...',
          e,
          st);
      final repaired = _attemptJsonRepair(rawText);
      if (repaired != null) {
        return _buildResultFromMap(repaired, rawText);
      }

      _logger.e(
          'JSON repair failed completely. Returning fallback result.', e, st);
      return AnalysisResult.fallback(
        title: _extractFallbackTitle(rawText),
        rawResponse: rawText,
      );
    }
  }

  /// Extracts the JSON object substring from raw text, removing markdown code blocks.
  static String _extractJson(String text) {
    var cleaned = text.trim();

    // Strip markdown code fences (```json ... ``` or ``` ... ```)
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.isNotEmpty && lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.trim().startsWith('```')) {
        lines.removeLast();
      }
      cleaned = lines.join('\n').trim();
    }

    // Isolate substring from first '{' to last '}'
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');

    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }

    return cleaned;
  }

  /// Constructs an [AnalysisResult] from a validated JSON map.
  static AnalysisResult _buildResultFromMap(
      Map<String, dynamic> map, String rawResponse) {
    // 1. Title
    final rawTitle = map['title'] as String?;
    final title = (rawTitle != null && rawTitle.trim().isNotEmpty)
        ? rawTitle.trim()
        : 'Untitled Screenshot';

    // 2. Primary Category & Human Context Flag
    final rawCategory = map['primary_category'] as String?;
    final normalizedCategory = CategoryClassifier.normalize(rawCategory);

    final rawNeedsHuman = map['needs_human_context'];
    bool needsHumanContext = false;
    if (rawNeedsHuman is bool) {
      needsHumanContext = rawNeedsHuman;
    } else if (rawNeedsHuman is String) {
      needsHumanContext = rawNeedsHuman.toLowerCase() == 'true';
    }

    // If category is Other or ambiguous, automatically require human review
    if (normalizedCategory == CategoryClassifier.fallbackCategory) {
      needsHumanContext = true;
    }

    // 3. Tags
    final rawTags = map['tags'];
    final List<String> tags = [];

    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is String && item.trim().isNotEmpty) {
          final cleanTag = item
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'^#+'), '')
              .replaceAll(RegExp(r'[^\w\s-]'), '');
          if (cleanTag.isNotEmpty && !tags.contains(cleanTag)) {
            tags.add(cleanTag);
          }
        }
      }
    } else if (rawTags is String && rawTags.trim().isNotEmpty) {
      // Comma-separated fallback
      final split = rawTags.split(RegExp(r'[,;]'));
      for (final item in split) {
        final clean = item.trim().toLowerCase();
        if (clean.isNotEmpty && !tags.contains(clean)) {
          tags.add(clean);
        }
      }
    }

    // Ensure at least one fallback tag and capped at 8
    if (tags.isEmpty) {
      tags.add(normalizedCategory.toLowerCase());
      tags.add('screenshot');
    }
    final finalTags = tags.take(8).toList();

    // 4. Extracted Text
    final rawText = map['extracted_text'] as String?;
    final extractedText = rawText?.trim() ?? '';

    return AnalysisResult(
      title: title,
      primaryCategory: normalizedCategory,
      tags: finalTags,
      extractedText: extractedText,
      needsHumanContext: needsHumanContext,
      rawResponse: rawResponse,
    );
  }

  /// Attempts simple heuristics to repair broken JSON (trailing commas, quotes).
  static Map<String, dynamic>? _attemptJsonRepair(String text) {
    try {
      var candidate = _extractJson(text);
      // Remove trailing commas before closing braces/brackets
      candidate = candidate.replaceAll(RegExp(r',\s*}'), '}');
      candidate = candidate.replaceAll(RegExp(r',\s*]'), ']');
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// Extracts the first reasonable non-empty line as a fallback title.
  static String _extractFallbackTitle(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where(
            (l) => l.isNotEmpty && !l.startsWith('{') && !l.startsWith('```'))
        .toList();

    if (lines.isNotEmpty) {
      final first = lines.first;
      return first.length > 50 ? '${first.substring(0, 47)}...' : first;
    }
    return 'Unclassified Screenshot';
  }
}
