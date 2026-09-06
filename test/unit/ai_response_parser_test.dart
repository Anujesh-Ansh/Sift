import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/infrastructure/ai/ai_response_parser.dart';

void main() {
  group('AiResponseParser Unit Tests', () {
    test('should parse well-formed direct JSON cleanly', () {
      const jsonText = '''
{
  "title": "Stripe Payment Invoice",
  "primary_category": "Finance",
  "tags": ["stripe", "invoice", "receipt", "tax"],
  "extracted_text": "Payment successful. Total: \$49.00. Invoice #10294.",
  "needs_human_context": false
}
''';

      final result = AiResponseParser.parse(jsonText);

      expect(result.title, equals('Stripe Payment Invoice'));
      expect(result.primaryCategory, equals('Finance'));
      expect(result.tags, equals(['stripe', 'invoice', 'receipt', 'tax']));
      expect(result.extractedText, contains('\$49.00'));
      expect(result.needsHumanContext, isFalse);
    });

    test('should extract JSON wrapped in markdown code fences', () {
      const markdownJson = '''
Here is the extracted screenshot data:
```json
{
  "title": "Flight Boarding Pass",
  "primary_category": "Travel",
  "tags": ["delta", "flight", "jfk", "boarding-pass"],
  "extracted_text": "Flight DL102 JFK to LHR Gate B22",
  "needs_human_context": false
}
```
Hope this helps!
''';

      final result = AiResponseParser.parse(markdownJson);

      expect(result.title, equals('Flight Boarding Pass'));
      expect(result.primaryCategory, equals('Travel'));
      expect(result.tags, contains('boarding-pass'));
      expect(result.needsHumanContext, isFalse);
    });

    test(
        'should automatically mark needsHumanContext true when category is Other',
        () {
      const ambiguousJson = '''
{
  "title": "Abstract Moodboard Photo",
  "primary_category": "UnknownCategory",
  "tags": ["colors", "inspiration"],
  "extracted_text": "Sample text",
  "needs_human_context": false
}
''';

      final result = AiResponseParser.parse(ambiguousJson);

      expect(result.primaryCategory, equals('Other'));
      expect(result.needsHumanContext, isTrue);
    });

    test('should normalize, sanitize and cap tags properly', () {
      const tagsJson = '''
{
  "title": "Sneakers Checkout",
  "primary_category": "Shopping",
  "tags": ["#Nike", "#shoes!", "SNEAKERS", "nike", "shopping", "cart", "discount", "sale", "footwear", "extra_tag_to_exceed_limit"],
  "extracted_text": "Order total \$120",
  "needs_human_context": false
}
''';

      final result = AiResponseParser.parse(tagsJson);

      expect(result.tags.length, lessThanOrEqualTo(8));
      expect(result.tags, contains('nike'));
      expect(result.tags, contains('shoes'));
      expect(result.tags, isNot(contains('#Nike')));
      // No duplicate tags
      expect(result.tags.where((t) => t == 'nike').length, equals(1));
    });

    test('should repair trailing commas in JSON gracefully', () {
      const brokenJson = '''
{
  "title": "Broken Trailing Comma",
  "primary_category": "Technology",
  "tags": ["bug", "error",],
  "extracted_text": "NullPointerException",
  "needs_human_context": false,
}
''';

      final result = AiResponseParser.parse(brokenJson);

      expect(result.title, equals('Broken Trailing Comma'));
      expect(result.primaryCategory, equals('Technology'));
      expect(result.tags, equals(['bug', 'error']));
    });

    test(
        'should return safe fallback when response is total gibberish or empty',
        () {
      final emptyResult = AiResponseParser.parse('');
      expect(emptyResult.primaryCategory, equals('Other'));
      expect(emptyResult.needsHumanContext, isTrue);

      final gibberishResult = AiResponseParser.parse(
          'Random unparseable string with no braces at all');
      expect(gibberishResult.primaryCategory, equals('Other'));
      expect(gibberishResult.needsHumanContext, isTrue);
      expect(gibberishResult.tags, contains('unclassified'));
    });
  });
}
