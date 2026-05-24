import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/core/l10n/app_strings.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════
  // 17 supported languages: basic string availability
  // ════════════════════════════════════════════════════════════════════
  group('17 supported languages have non-empty strings', () {
    const supportedLanguages = [
      'ko', 'en', 'zh', 'hi', 'ja', 'th', 'vi', 'bn',
      'ru', 'id', 'ne', 'km', 'my', 'si', 'fil', 'uz', 'mn',
    ];

    for (final lang in supportedLanguages) {
      test('$lang: selectLanguage is not empty', () {
        final s = AppStrings.of(lang);
        expect(s.selectLanguage, isNotEmpty);
      });

      test('$lang: salaryHourly is not empty', () {
        final s = AppStrings.of(lang);
        expect(s.salaryHourly, isNotEmpty);
      });

      test('$lang: infoSalary is not empty', () {
        final s = AppStrings.of(lang);
        expect(s.infoSalary, isNotEmpty);
      });
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // Unknown language falls back to English
  // ════════════════════════════════════════════════════════════════════
  group('fallback behavior', () {
    test('unknown language xx falls back to English', () {
      final xx = AppStrings.of('xx');
      final en = AppStrings.of('en');
      expect(xx.selectLanguage, en.selectLanguage);
      expect(xx.salaryHourly, en.salaryHourly);
      expect(xx.infoSalary, en.infoSalary);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // educationLabel
  // ════════════════════════════════════════════════════════════════════
  group('educationLabel', () {
    test('ko high_school returns eduHighSchool', () {
      final ko = AppStrings.of('ko');
      expect(ko.educationLabel('high_school'), ko.eduHighSchool);
      expect(ko.educationLabel('high_school'), '고졸');
    });

    test('en high_school returns English value', () {
      final en = AppStrings.of('en');
      expect(en.educationLabel('high_school'), 'High school');
    });

    test('unknown code returns code itself', () {
      final ko = AppStrings.of('ko');
      expect(ko.educationLabel('phd_plus'), 'phd_plus');
    });

    test('all education codes are handled', () {
      final en = AppStrings.of('en');
      for (final code in [
        'none', 'middle_school', 'high_school',
        'college', 'bachelor', 'master', 'doctor',
      ]) {
        expect(en.educationLabel(code), isNotEmpty);
        expect(en.educationLabel(code), isNot(equals(code)));
      }
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // experienceLabel
  // ════════════════════════════════════════════════════════════════════
  group('experienceLabel', () {
    test('ko 3y returns exp3y', () {
      final ko = AppStrings.of('ko');
      expect(ko.experienceLabel('3y'), ko.exp3y);
      expect(ko.experienceLabel('3y'), '3년 이상');
    });

    test('en 3y returns English value', () {
      final en = AppStrings.of('en');
      expect(en.experienceLabel('3y'), '3+ years');
    });

    test('unknown code returns code itself', () {
      final en = AppStrings.of('en');
      expect(en.experienceLabel('20y'), '20y');
    });

    test('all experience codes are handled', () {
      final en = AppStrings.of('en');
      for (final code in ['none', 'newcomer', '1y', '3y', '5y', '10y']) {
        expect(en.experienceLabel(code), isNotEmpty);
        expect(en.experienceLabel(code), isNot(equals(code)));
      }
    });
  });
}
