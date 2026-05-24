import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/data/models/filter_state.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════
  // fromJson
  // ════════════════════════════════════════════════════════════════════
  group('FilterCounts.fromJson', () {
    test('parses full data correctly', () {
      final json = {
        'visa': {'v1': 50, 'v2': 30},
        'category': {'c1': 120, 'c2': 80},
        'region': {'Seoul': 200, 'Busan': 100},
        'employment_type': {'et1': 150},
        'benefit': {'b1': 90, 'b2': 45},
        'korean_level': {'kl1': 60},
        'work_schedule': {'ws1': 70, 'ws2': 40},
        'language': {'lang1': 55},
        'visa_sponsorship': 25,
        'gender': {'male': 300, 'female': 200, 'any': 500},
        'salary_type': {'hourly': 100, 'monthly': 400},
        'education': {'high_school': 250, 'bachelor': 150},
        'experience': {'none': 300, '3y': 120},
      };

      final counts = FilterCounts.fromJson(json);

      expect(counts.visa, {'v1': 50, 'v2': 30});
      expect(counts.category, {'c1': 120, 'c2': 80});
      expect(counts.region, {'Seoul': 200, 'Busan': 100});
      expect(counts.employmentType, {'et1': 150});
      expect(counts.benefit, {'b1': 90, 'b2': 45});
      expect(counts.koreanLevel, {'kl1': 60});
      expect(counts.workSchedule, {'ws1': 70, 'ws2': 40});
      expect(counts.language, {'lang1': 55});
      expect(counts.visaSponsorship, 25);
      expect(counts.gender, {'male': 300, 'female': 200, 'any': 500});
      expect(counts.salaryType, {'hourly': 100, 'monthly': 400});
      expect(counts.education, {'high_school': 250, 'bachelor': 150});
      expect(counts.experience, {'none': 300, '3y': 120});
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // getCount
  // ════════════════════════════════════════════════════════════════════
  group('getCount', () {
    final counts = FilterCounts.fromJson({
      'visa': {'v1': 50, 'v2': 30},
      'category': {'c1': 120},
      'region': {'Seoul': 200},
      'employment_type': {'et1': 150},
      'benefit': {'b1': 90},
      'korean_level': {'kl1': 60},
      'work_schedule': {'ws1': 70},
      'language': {'lang1': 55},
    });

    test('returns correct count for known visa', () {
      expect(counts.getCount('visa', 'v1'), 50);
    });

    test('returns 0 for unknown visa id', () {
      expect(counts.getCount('visa', 'unknown'), 0);
    });

    test('returns correct count for category', () {
      expect(counts.getCount('category', 'c1'), 120);
    });

    test('returns correct count for region', () {
      expect(counts.getCount('region', 'Seoul'), 200);
    });

    test('returns 0 for unknown category name', () {
      expect(counts.getCount('unknown_category', 'x'), 0);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // fromJson with empty map
  // ════════════════════════════════════════════════════════════════════
  group('fromJson empty', () {
    test('empty JSON produces all empty maps and visaSponsorship=0', () {
      final counts = FilterCounts.fromJson({});

      expect(counts.visa, isEmpty);
      expect(counts.category, isEmpty);
      expect(counts.region, isEmpty);
      expect(counts.employmentType, isEmpty);
      expect(counts.benefit, isEmpty);
      expect(counts.koreanLevel, isEmpty);
      expect(counts.workSchedule, isEmpty);
      expect(counts.language, isEmpty);
      expect(counts.visaSponsorship, 0);
      expect(counts.gender, isEmpty);
      expect(counts.salaryType, isEmpty);
      expect(counts.education, isEmpty);
      expect(counts.experience, isEmpty);
    });
  });
}
