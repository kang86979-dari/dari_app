import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/core/l10n/app_strings.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════
  // Korean (ko)
  // ════════════════════════════════════════════════════════════════════
  group('formatSalary - ko', () {
    final ko = AppStrings.of('ko');

    test('monthly 2,000,000 => 월급 200만원', () {
      expect(ko.formatSalary('monthly', 2000000), '월급 200만원');
    });

    test('hourly 10,030 => 시급 10,030원', () {
      expect(ko.formatSalary('hourly', 10030), '시급 10,030원');
    });

    test('annual 30,000,000 => 연봉 3,000만원', () {
      expect(ko.formatSalary('annual', 30000000), '연봉 3,000만원');
    });

    test('daily 80,000 => 일급 8만원', () {
      expect(ko.formatSalary('daily', 80000), '일급 8만원');
    });

    test('monthly 2,500,000 (divisible by 10000) => 월급 250만원', () {
      expect(ko.formatSalary('monthly', 2500000), '월급 250만원');
    });

    test('monthly 2,500,001 (not divisible by 10000) => 월급 2,500,001원', () {
      expect(ko.formatSalary('monthly', 2500001), '월급 2,500,001원');
    });

    test('monthly 0 => 월급 0원', () {
      expect(ko.formatSalary('monthly', 0), '월급 0원');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Japanese (ja)
  // ════════════════════════════════════════════════════════════════════
  group('formatSalary - ja', () {
    final ja = AppStrings.of('ja');

    test('monthly 2,000,000 => 月給 200万ウォン', () {
      expect(ja.formatSalary('monthly', 2000000), '月給 200万ウォン');
    });

    test('hourly 10,030 => 時給 10,030ウォン', () {
      expect(ja.formatSalary('hourly', 10030), '時給 10,030ウォン');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Chinese (zh)
  // ════════════════════════════════════════════════════════════════════
  group('formatSalary - zh', () {
    final zh = AppStrings.of('zh');

    test('monthly 2,000,000 => 月薪 200万韩元', () {
      expect(zh.formatSalary('monthly', 2000000), '月薪 200万韩元');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // German (de) - no 'de' key in salaryMonthly _t map, falls back to en
  // ════════════════════════════════════════════════════════════════════
  group('formatSalary - de', () {
    final de = AppStrings.of('de');

    test('monthly 2,000,000 => dot separator + Monthly (en fallback)', () {
      // de is in the dot-format set, but salaryMonthly has no 'de' key,
      // so _t falls back to 'en' => 'Monthly'
      expect(de.formatSalary('monthly', 2000000), '₩2.000.000 / Monthly');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Hindi (hi) - Indian number format
  // ════════════════════════════════════════════════════════════════════
  group('formatSalary - hi', () {
    final hi = AppStrings.of('hi');

    test('monthly 2,000,000 => Indian format with Hindi label', () {
      expect(hi.formatSalary('monthly', 2000000), '₩20,00,000 / मासिक');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // English (en)
  // ════════════════════════════════════════════════════════════════════
  group('formatSalary - en', () {
    final en = AppStrings.of('en');

    test('monthly 2,000,000 => comma format', () {
      expect(en.formatSalary('monthly', 2000000), '₩2,000,000 / Monthly');
    });

    test('hourly 10,030 => comma format', () {
      expect(en.formatSalary('hourly', 10030), '₩10,030 / Hourly');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Arabic (ar) - RTL format: typeLabel + ₩amount
  // ════════════════════════════════════════════════════════════════════
  group('formatSalary - ar', () {
    final ar = AppStrings.of('ar');

    test('monthly 2,000,000 => RTL format with en fallback label', () {
      // ar has no salaryMonthly key in _t map, falls back to en => 'Monthly'
      // Format: typeLabel ₩amount
      expect(ar.formatSalary('monthly', 2000000), 'Monthly ₩2,000,000');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Russian (ru) - dot format group
  // ════════════════════════════════════════════════════════════════════
  group('formatSalary - ru', () {
    final ru = AppStrings.of('ru');

    test('monthly 2,000,000 => dot format with Russian label', () {
      expect(ru.formatSalary('monthly', 2000000), '₩2.000.000 / Ежемесячная');
    });
  });
}
