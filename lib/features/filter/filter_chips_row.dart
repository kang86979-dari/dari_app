import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../core/utils/district_names.dart';
import '../../core/utils/region_mapper.dart';
import '../../data/models/filter_state.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/services/analytics_service.dart';
import '../../providers/job_provider.dart';
import '../../providers/language_provider.dart';

/// 선택된 필터 칩 가로 행 (탭=삭제) — 홈에서 쓰던 것을 검색 결과와 공유하기
/// 위해 추출(2026-10-09). 동작·디자인 변화 없음.
class FilterChipData {
  final String label;
  final VoidCallback onRemove;
  const FilterChipData(this.label, this.onRemove);
}

class ReadOnlyFilterChips extends StatelessWidget {
  final FilterState filter;
  final WidgetRef ref;

  const ReadOnlyFilterChips({required this.filter, required this.ref});

  @override
  Widget build(BuildContext context) {
    final chips = buildFilterChipData(filter, ref);
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => GestureDetector(
            onTap: chips[i].onRemove, // 칩 전체 탭으로 삭제 (X만 누르기 어려운 문제 해결)
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.only(left: 12, right: 8, top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.carrotLight,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chips[i].label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.carrotDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 14, color: AppColors.carrot),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// 선택된 필터 → 칩 데이터(라벨+삭제 핸들러) — 칩 행과 키워드 알림 조건
/// 라벨 생성이 공유(2026-10-09).
List<FilterChipData> buildFilterChipData(FilterState filter, WidgetRef ref) {
  final notifier = ref.read(filterStateProvider.notifier);
  final chips = <FilterChipData>[];

  // 비자 (선택된 경우만 옵션 로드)
  if (filter.visaIds.isNotEmpty) {
    final visaOpts = ref.watch(visaOptionsProvider).valueOrNull ?? [];
    for (final id in filter.visaIds) {
      final opt = visaOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('visa', opt.label);
        notifier.toggleVisa(id);
      }));
    }
  }
  // 직종
  if (filter.categoryIds.isNotEmpty) {
    final catOpts = ref.watch(categoryOptionsProvider).valueOrNull ?? [];
    for (final id in filter.categoryIds) {
      final opt = catOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('category', opt.label);
        notifier.toggleCategory(id);
      }));
    }
  }
  // 지역: 시/도 전체면 시/도명, 구/군 개별이면 구/군별 칩
  if (filter.regionIds.isNotEmpty) {
    // 캐시가 아직 없으면 로드 트리거 (앱 재시작 시)
    ref.watch(siDoOptionsProvider);
    final allRegions = JobRepository.allRegionsCacheSync;
    final lang = ref.watch(languageProvider);
    if (allRegions != null) {
      final siDoGroups = <String, List<int>>{};
      final siDoTotals = <String, int>{};
      final siDoHasGuGun = <String, bool>{};
      for (final r in allRegions) {
        final si = r['si_name'] as String;
        if (r['gu_name'] != null) {
          siDoTotals[si] = (siDoTotals[si] ?? 0) + 1;
          siDoHasGuGun[si] = true;
        } else {
          siDoHasGuGun.putIfAbsent(si, () => false);
        }
      }
      for (final id in filter.regionIds) {
        final r = allRegions.where((e) => e['id'] == id).firstOrNull;
        if (r != null) {
          final si = r['si_name'] as String;
          if (r['gu_name'] != null || !(siDoHasGuGun[si] ?? false)) {
            siDoGroups.putIfAbsent(si, () => []).add(id);
          }
        }
      }
      for (final entry in siDoGroups.entries) {
        final si = entry.key;
        final ids = entry.value;
        final hasGuGun = siDoHasGuGun[si] ?? false;
        final total = hasGuGun ? (siDoTotals[si] ?? 0) : ids.length;
        if (ids.length >= total) {
          // 시/도 전체 삭제: gu_name=null 행 포함 모든 ID 제거
          final allSiDoIds = allRegions
              .where((r) => r['si_name'] == si)
              .map((r) => r['id'] as int)
              .toSet();
          chips.add(FilterChipData(
            RegionMapper.getLocalizedName(si, lang),
            () { analytics.filterChipRemoved('region', si);
              final u = Set<int>.from(filter.regionIds); u.removeAll(allSiDoIds); notifier.setRegionIds(u); },
          ));
        } else {
          for (final id in ids) {
            final r = allRegions.where((e) => e['id'] == id).firstOrNull;
            if (r != null && r['gu_name'] != null) {
              final gu = r['gu_name'] as String;
              final label = lang == 'ko' ? gu : DistrictNames.getLocalizedGuName(gu, si, lang);
              chips.add(FilterChipData(label, () {
                analytics.filterChipRemoved('region', gu);
                notifier.toggleRegionId(id);
              }));
            }
          }
        }
      }
    }
  }
  // 급여
  if (filter.salaryRange != null && filter.salaryRange!.isNotEmpty) {
    chips.add(FilterChipData(filter.salaryRange!, () {
      analytics.filterChipRemoved('salary', filter.salaryRange!);
      notifier.setSalary(null);
    }));
  }
  // 고용형태
  if (filter.employmentTypeIds.isNotEmpty) {
    final etOpts = ref.watch(employmentTypeOptionsProvider).valueOrNull ?? [];
    for (final id in filter.employmentTypeIds) {
      final opt = etOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('employment_type', opt.label);
        notifier.toggleEmploymentType(id);
      }));
    }
  }
  // 급여유형
  if (filter.salaryTypes.isNotEmpty) {
    final s = ref.watch(stringsProvider);
    final typeLabels = {
      'hourly': s.salaryHourly, 'daily': s.salaryDaily,
      'weekly': s.salaryWeekly, 'monthly': s.salaryMonthly,
      'annual': s.salaryAnnual,
    };
    for (final code in filter.salaryTypes) {
      final label = typeLabels[code] ?? code;
      chips.add(FilterChipData(label, () {
        analytics.filterChipRemoved('salary_type', code);
        notifier.toggleSalaryType(code);
      }));
    }
  }
  // 근무요일
  if (filter.workScheduleIds.isNotEmpty) {
    final wsOpts = ref.watch(workScheduleOptionsProvider).valueOrNull ?? [];
    for (final id in filter.workScheduleIds) {
      final opt = wsOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('work_schedule', opt.label);
        notifier.toggleWorkSchedule(id);
      }));
    }
  }
  // 성별
  if (filter.gender != null) {
    final s = ref.watch(stringsProvider);
    final label = filter.gender == 'male' ? s.genderMale
        : filter.gender == 'female' ? s.genderFemale : s.genderAny;
    chips.add(FilterChipData(label, () {
      analytics.filterChipRemoved('gender', filter.gender!);
      notifier.setGender(null);
    }));
  }
  // 학력
  if (filter.educations.isNotEmpty) {
    final s = ref.watch(stringsProvider);
    for (final code in filter.educations) {
      chips.add(FilterChipData(s.educationLabel(code), () {
        analytics.filterChipRemoved('education', code);
        notifier.toggleEducation(code);
      }));
    }
  }
  // 경력
  if (filter.experiences.isNotEmpty) {
    final s = ref.watch(stringsProvider);
    for (final code in filter.experiences) {
      chips.add(FilterChipData(s.experienceLabel(code), () {
        analytics.filterChipRemoved('experience', code);
        notifier.toggleExperience(code);
      }));
    }
  }
  // 한국어능력
  if (filter.koreanLevelIds.isNotEmpty) {
    final klOpts = ref.watch(koreanLevelOptionsProvider).valueOrNull ?? [];
    for (final id in filter.koreanLevelIds) {
      final opt = klOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('korean_level', opt.label);
        notifier.toggleKoreanLevel(id);
      }));
    }
  }
  // 복리후생
  if (filter.benefitIds.isNotEmpty) {
    final benOpts = ref.watch(benefitOptionsProvider).valueOrNull ?? [];
    for (final id in filter.benefitIds) {
      final opt = benOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('benefit', opt.label);
        notifier.toggleBenefit(id);
      }));
    }
  }
  // 비자지원
  if (filter.visaSponsorship != null) {
    final s = ref.watch(stringsProvider);
    chips.add(FilterChipData(s.tabVisaSponsorship, () {
      analytics.filterChipRemoved('visa_sponsorship', '');
      notifier.setVisaSponsorship(null);
    }));
  }
  // 언어능력
  if (filter.languageIds.isNotEmpty) {
    final langOpts = ref.watch(languageOptionsProvider).valueOrNull ?? [];
    for (final id in filter.languageIds) {
      final opt = langOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('language', opt.label);
        notifier.toggleLanguage(id);
      }));
    }
  }
  // 국가
  if (filter.countryIds.isNotEmpty) {
    final countryOpts = ref.watch(countryOptionsProvider).valueOrNull ?? [];
    for (final id in filter.countryIds) {
      final opt = countryOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('country', opt.label);
        notifier.toggleCountry(id);
      }));
    }
  }
  // 출처(사이트)
  if (filter.siteIds.isNotEmpty) {
    final siteOpts = ref.watch(siteOptionsProvider).valueOrNull ?? [];
    for (final id in filter.siteIds) {
      final opt = siteOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(FilterChipData(opt.label, () {
        analytics.filterChipRemoved('site', opt.label);
        notifier.toggleSite(id);
      }));
    }
  }

  return chips;
}