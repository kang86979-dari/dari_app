import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/job.dart';
import '../data/models/filter_state.dart';
import '../data/repositories/job_repository.dart';
import 'language_provider.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository();
});

final filterStateProvider =
    StateNotifierProvider<FilterStateNotifier, FilterState>((ref) {
  return FilterStateNotifier();
});

class FilterStateNotifier extends StateNotifier<FilterState> {
  static const _prefsKey = 'filter_state';

  FilterStateNotifier() : super(FilterState.empty) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      try {
        state = FilterState.fromJson(jsonDecode(json));
      } catch (_) {}
    }
  }

  /// 캐시 로드 후 유효하지 않은 regionId 정리 (전국 등 삭제된 항목 제거)
  Future<void> cleanupInvalidRegionIds() async {
    if (state.regionIds.isEmpty) return;
    try {
      final repo = JobRepository();
      final allRegions = await repo.getAllRegionsPublic();
      final validIds = allRegions.map((r) => r['id'] as int).toSet();
      final cleaned = state.regionIds.where(validIds.contains).toSet();
      if (cleaned.length != state.regionIds.length) {
        state = state.copyWith(regionIds: cleaned);
        _save();
      }
    } catch (_) {}
  }

  Timer? _saveTimer;

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
    });
  }

  void toggleVisa(String id) {
    final updated = Set<String>.from(state.visaIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(visaIds: updated);
    _save();
  }

  void toggleCategory(String id) {
    final updated = Set<String>.from(state.categoryIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(categoryIds: updated);
    _save();
  }

  void toggleRegionId(int id) {
    final updated = Set<int>.from(state.regionIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(regionIds: updated);
    _save();
  }

  void setRegionIds(Set<int> ids) {
    state = state.copyWith(regionIds: ids);
    _save();
  }

  void setSalary(String? salary) {
    if (salary == null) {
      state = state.copyWith(salaryRange: '');
    } else {
      state = state.copyWith(salaryRange: salary);
    }
    _save();
  }

  void toggleEmploymentType(String id) {
    final updated = Set<String>.from(state.employmentTypeIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(employmentTypeIds: updated);
    _save();
  }

  void toggleBenefit(String id) {
    final updated = Set<String>.from(state.benefitIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(benefitIds: updated);
    _save();
  }

  void toggleKoreanLevel(int id) {
    final updated = Set<int>.from(state.koreanLevelIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(koreanLevelIds: updated);
    _save();
  }

  void toggleWorkSchedule(int id) {
    final updated = Set<int>.from(state.workScheduleIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(workScheduleIds: updated);
    _save();
  }

  void toggleLanguage(int id) {
    final updated = Set<int>.from(state.languageIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(languageIds: updated);
    _save();
  }

  void setVisaSponsorship(bool? value) {
    if (value == null) {
      state = state.copyWith(clearVisaSponsorship: true);
    } else {
      state = state.copyWith(visaSponsorship: value);
    }
    _save();
  }

  void setGender(String? value) {
    if (value == null) {
      state = state.copyWith(clearGender: true);
    } else {
      state = state.copyWith(gender: value);
    }
    _save();
  }

  void toggleSalaryType(String value) {
    final updated = Set<String>.from(state.salaryTypes);
    updated.contains(value) ? updated.remove(value) : updated.add(value);
    state = state.copyWith(salaryTypes: updated);
    _save();
  }

  void toggleEducation(String value) {
    final updated = Set<String>.from(state.educations);
    updated.contains(value) ? updated.remove(value) : updated.add(value);
    state = state.copyWith(educations: updated);
    _save();
  }

  void toggleExperience(String value) {
    final updated = Set<String>.from(state.experiences);
    updated.contains(value) ? updated.remove(value) : updated.add(value);
    state = state.copyWith(experiences: updated);
    _save();
  }

  void toggleSite(String id) {
    final updated = Set<String>.from(state.siteIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(siteIds: updated);
    _save();
  }

  void toggleCountry(String id) {
    final updated = Set<String>.from(state.countryIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    state = state.copyWith(countryIds: updated);
    _save();
  }

  /// 직접 상태 설정 (온보딩에서 사용)
  void setState(FilterState newState) {
    if (state == newState) return;
    state = newState;
    _save();
  }

  void reset() {
    state = FilterState.empty;
    _save();
  }
}

// ── Job 리스트/상세 ──

// [DEV] 사이트 필터
final selectedSiteIdProvider = StateProvider<String?>((ref) => null);

final jobListProvider =
    FutureProvider.family<List<Job>, int>((ref, page) async {
  final repo = ref.watch(jobRepositoryProvider);
  final filter = ref.watch(filterStateProvider);
  final langCode = ref.watch(languageProvider);
  return repo.getJobs(filter: filter, page: page, langCode: langCode);
});

// [DEV] 사이트 목록
final siteOptionsProvider = FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getSiteOptions();
});

final jobTotalCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final filter = ref.watch(filterStateProvider);
  final langCode = ref.watch(languageProvider);
  return repo.getJobCount(filter: filter, langCode: langCode);
});

final jobDetailProvider =
    FutureProvider.family<Job?, String>((ref, id) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getJobById(id);
});

// ── 필터 카운트 (RPC) ──

final filterCountsProvider = FutureProvider<FilterCounts>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getFilterCounts();
});

// ── 필터 옵션 (DB 동적 로드) ──

final visaOptionsProvider = FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getVisaOptions();
});

final categoryOptionsProvider = FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getCategoryOptions(lang);
});

final employmentTypeOptionsProvider =
    FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getEmploymentTypeOptions(lang);
});

final benefitOptionsProvider =
    FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getBenefitOptions(lang);
});

final siDoOptionsProvider =
    FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getSiDoOptions(lang);
});

final guGunOptionsProvider =
    FutureProvider.family<List<FilterOption>, String>((ref, siName) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getGuGunOptions(siName, lang);
});

final koreanLevelOptionsProvider =
    FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getKoreanLevelOptions(lang);
});

final workScheduleOptionsProvider =
    FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getWorkScheduleOptions(lang);
});

final languageOptionsProvider =
    FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getLanguageOptions(lang);
});

final countryOptionsProvider =
    FutureProvider<List<FilterOption>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  final lang = ref.watch(languageProvider);
  return repo.getCountryOptions(lang);
});
