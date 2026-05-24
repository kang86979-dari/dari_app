import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/data/models/filter_state.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════
  // isEmpty
  // ════════════════════════════════════════════════════════════════════
  group('isEmpty', () {
    test('FilterState.empty.isEmpty is true', () {
      expect(FilterState.empty.isEmpty, isTrue);
    });

    test('FilterState with visaIds is not empty', () {
      const state = FilterState(visaIds: {'v1'});
      expect(state.isEmpty, isFalse);
    });

    test('FilterState with gender is not empty', () {
      const state = FilterState(gender: 'male');
      expect(state.isEmpty, isFalse);
    });

    test('FilterState with visaSponsorship is not empty', () {
      const state = FilterState(visaSponsorship: true);
      expect(state.isEmpty, isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // activeCount
  // ════════════════════════════════════════════════════════════════════
  group('activeCount', () {
    test('empty state has 0 active count', () {
      expect(FilterState.empty.activeCount, 0);
    });

    test('visaIds + gender counts correctly', () {
      const state = FilterState(
        visaIds: {'v1', 'v2'},
        gender: 'male',
      );
      // 2 visaIds + 1 gender = 3
      expect(state.activeCount, 3);
    });

    test('multiple filter types count correctly', () {
      const state = FilterState(
        visaIds: {'v1'},
        categoryIds: {'c1', 'c2'},
        regionIds: {1},
        visaSponsorship: true,
        salaryTypes: {'hourly', 'monthly'},
      );
      // 1 + 2 + 1 + 1 + 2 = 7
      expect(state.activeCount, 7);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // copyWith
  // ════════════════════════════════════════════════════════════════════
  group('copyWith', () {
    test('changes gender, preserves rest', () {
      const original = FilterState(
        visaIds: {'v1'},
        gender: 'male',
      );
      final updated = original.copyWith(gender: 'female');
      expect(updated.gender, 'female');
      expect(updated.visaIds, {'v1'});
    });

    test('clearGender sets gender to null', () {
      const original = FilterState(gender: 'male');
      final updated = original.copyWith(clearGender: true);
      expect(updated.gender, isNull);
    });

    test('clearVisaSponsorship sets visaSponsorship to null', () {
      const original = FilterState(visaSponsorship: true);
      final updated = original.copyWith(clearVisaSponsorship: true);
      expect(updated.visaSponsorship, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // toJson / fromJson roundtrip
  // ════════════════════════════════════════════════════════════════════
  group('toJson / fromJson', () {
    test('roundtrip preserves all fields', () {
      const original = FilterState(
        visaIds: {'v1', 'v2'},
        categoryIds: {'c1'},
        regionIds: {1, 2},
        employmentTypeIds: {'et1'},
        benefitIds: {'b1'},
        koreanLevelIds: {1, 2},
        workScheduleIds: {3},
        languageIds: {5},
        visaSponsorship: true,
        gender: 'female',
        salaryTypes: {'hourly', 'monthly'},
        educations: {'high_school'},
        experiences: {'3y'},
        siteIds: {'s1'},
        countryIds: {'kr'},
      );

      final json = original.toJson();
      final restored = FilterState.fromJson(json);

      expect(restored, equals(original));
    });

    test('roundtrip with empty state', () {
      final json = FilterState.empty.toJson();
      final restored = FilterState.fromJson(json);
      expect(restored, equals(FilterState.empty));
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // equality
  // ════════════════════════════════════════════════════════════════════
  group('equality', () {
    test('same filters are equal', () {
      const a = FilterState(visaIds: {'v1', 'v2'}, gender: 'male');
      const b = FilterState(visaIds: {'v2', 'v1'}, gender: 'male');
      expect(a, equals(b));
    });

    test('different filters are not equal', () {
      const a = FilterState(visaIds: {'v1'});
      const b = FilterState(visaIds: {'v2'});
      expect(a, isNot(equals(b)));
    });

    test('gender difference makes not equal', () {
      const a = FilterState(gender: 'male');
      const b = FilterState(gender: 'female');
      expect(a, isNot(equals(b)));
    });
  });
}
