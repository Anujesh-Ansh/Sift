import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/infrastructure/ai/category_classifier.dart';

void main() {
  group('CategoryClassifier Unit Tests', () {
    test('should recognize all canonical categories exactly', () {
      for (final cat in CategoryClassifier.canonicalCategories) {
        expect(CategoryClassifier.normalize(cat), equals(cat));
        if (cat != 'Other') {
          expect(CategoryClassifier.isRecognized(cat), isTrue);
        }
      }
    });

    test('should match categories case-insensitively and trim whitespace', () {
      expect(CategoryClassifier.normalize('  finance  '), equals('Finance'));
      expect(CategoryClassifier.normalize('sHoPpInG'), equals('Shopping'));
      expect(CategoryClassifier.normalize('TECHNOLOGY'), equals('Technology'));
      expect(CategoryClassifier.normalize('entertainment'),
          equals('Entertainment'));
    });

    test('should apply semantic keyword fallbacks for common synonyms', () {
      expect(CategoryClassifier.normalize('Crypto transaction receipt'),
          equals('Finance'));
      expect(CategoryClassifier.normalize('Amazon product page'),
          equals('Shopping'));
      expect(CategoryClassifier.normalize('WhatsApp chat screenshot'),
          equals('Communication'));
      expect(CategoryClassifier.normalize('Python dev error log on github'),
          equals('Technology'));
      expect(CategoryClassifier.normalize('Flight ticket to Tokyo'),
          equals('Travel'));
      expect(CategoryClassifier.normalize('Pasta recipe'), equals('Food'));
      expect(CategoryClassifier.normalize('Instagram meme post'),
          equals('Social'));
      expect(CategoryClassifier.normalize('Signed PDF contract scan'),
          equals('Documents'));
      expect(CategoryClassifier.normalize('Online course study notes'),
          equals('Education'));
      expect(CategoryClassifier.normalize('Aesthetic wallpaper art'),
          equals('Aesthetic'));
    });

    test('should map unknown categories or empty strings to Other', () {
      expect(CategoryClassifier.normalize('random gibberish string 12345'),
          equals('Other'));
      expect(CategoryClassifier.normalize(null), equals('Other'));
      expect(CategoryClassifier.normalize('   '), equals('Other'));
      expect(CategoryClassifier.isRecognized('random gibberish'), isFalse);
    });
  });
}
