import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  late final FirebaseAnalytics _ga;
  String _langCode = 'en';

  void init() {
    _ga = FirebaseAnalytics.instance;
    _ga.setAnalyticsCollectionEnabled(true);
  }

  void setLangCode(String code) {
    _langCode = code;
    _ga.setUserProperty(name: 'app_language', value: code);
  }

  Future<void> log(String eventName, [Map<String, dynamic>? data]) async {
    try {
      final params = <String, Object>{
        'lang_code': _langCode,
      };
      if (data != null) {
        for (final entry in data.entries) {
          if (entry.value != null) {
            params[entry.key] = entry.value is List
                ? entry.value.toString()
                : entry.value;
          }
        }
      }
      await _ga.logEvent(name: eventName, parameters: params);
    } catch (_) {}
  }

  // ── 편의 메서드 ──

  void screenView(String screenName) =>
      _ga.logEvent(name: 'screen_view', parameters: {'screen_name': screenName});

  void languageSelected(String langCode) =>
      log('language_selected', {'lang_code': langCode});

  void visaSelected(List<String> visaCodes) =>
      log('visa_selected', {'visa_codes': visaCodes, 'count': visaCodes.length});

  void locationPermission(bool granted) =>
      log(granted ? 'location_permission_granted' : 'location_permission_denied');

  void jobCardTap(String jobId, int position) =>
      log('job_card_tap', {'job_id': jobId, 'position': position});

  void filterChipRemoved(String type, String value) =>
      log('filter_chip_removed', {'filter_type': type, 'value': value});

  void siteFilterTap(String? siteName) =>
      log('site_filter_tap', {'site_name': siteName ?? 'all'});

  void scrollDepth(int maxPosition) =>
      log('scroll_depth', {'max_position': maxPosition});

  void languageChanged(String from, String to) =>
      log('language_changed', {'from': from, 'to': to});

  void filterOpened(int activeCount) =>
      log('filter_opened', {'active_count': activeCount});

  void filterApplied(Map<String, dynamic> filterState) =>
      log('filter_applied', filterState);

  /// 필터 상세 이벤트: 어떤 카테고리 + 어떤 옵션을 사용했는지
  void filterAppliedDetail({
    required Set<String> visaIds,
    required Set<String> categoryIds,
    required Set<String> employmentTypeIds,
    required Set<String> regionNames,
    required Set<String> salaryTypes,
    required Set<int> workScheduleIds,
    required String? gender,
    required Set<String> educations,
    required Set<String> experiences,
    required Set<int> koreanLevelIds,
    required Set<String> benefitIds,
    required Set<String> countryIds,
    required Set<String> siteIds,
    required bool? visaSponsorship,
  }) {
    // 1단계: 카테고리 사용 여부
    log('filter_categories', {
      'visa': (visaIds.isNotEmpty || visaSponsorship != null) ? 1 : 0,
      'job_type': categoryIds.isNotEmpty ? 1 : 0,
      'employ_type': employmentTypeIds.isNotEmpty ? 1 : 0,
      'region': regionNames.isNotEmpty ? 1 : 0,
      'salary': salaryTypes.isNotEmpty ? 1 : 0,
      'schedule': workScheduleIds.isNotEmpty ? 1 : 0,
      'qualification': (gender != null || educations.isNotEmpty || experiences.isNotEmpty || koreanLevelIds.isNotEmpty) ? 1 : 0,
      'benefits': benefitIds.isNotEmpty ? 1 : 0,
      'country': countryIds.isNotEmpty ? 1 : 0,
      'site': siteIds.isNotEmpty ? 1 : 0,
    });

    // 2단계: 상세 옵션
    if (visaIds.isNotEmpty) {
      log('filter_visa', {'codes': visaIds.join(', ')});
    }
    if (categoryIds.isNotEmpty) {
      log('filter_job_type', {'ids': categoryIds.join(', ')});
    }
    if (employmentTypeIds.isNotEmpty) {
      log('filter_employ_type', {'ids': employmentTypeIds.join(', ')});
    }
    if (regionNames.isNotEmpty) {
      log('filter_region', {'names': regionNames.join(', ')});
    }
    if (salaryTypes.isNotEmpty) {
      log('filter_salary', {'types': salaryTypes.join(', ')});
    }
    if (workScheduleIds.isNotEmpty) {
      log('filter_schedule', {'ids': workScheduleIds.join(', ')});
    }
    if (gender != null || educations.isNotEmpty || experiences.isNotEmpty || koreanLevelIds.isNotEmpty) {
      log('filter_qualification', {
        'gender': gender ?? 'any',
        'education': educations.join(', '),
        'experience': experiences.join(', '),
        'korean_level': koreanLevelIds.join(', '),
      });
    }
    if (benefitIds.isNotEmpty) {
      log('filter_benefits', {'ids': benefitIds.join(', ')});
    }
    if (countryIds.isNotEmpty) {
      log('filter_country', {'ids': countryIds.join(', ')});
    }
    if (siteIds.isNotEmpty) {
      log('filter_site', {'ids': siteIds.join(', ')});
    }
  }

  void filterReset() => log('filter_reset');

  void searchExecuted(String query, int resultCount) =>
      log('search_executed', {'query': query, 'result_count': resultCount});

  void searchResultTap(String jobId, String query, int position) =>
      log('search_result_tap', {'job_id': jobId, 'query': query, 'position': position});

  void jobDetailView(String jobId, String source) =>
      log('job_detail_view', {'job_id': jobId, 'source': source});

  void applyTap(String jobId, String? siteName) =>
      log('apply_tap', {'job_id': jobId, 'site_name': siteName});

  void applyAdShown(String jobId) =>
      log('apply_ad_shown', {'job_id': jobId});

  void favoriteAdded(String jobId, String source) =>
      log('favorite_added', {'job_id': jobId, 'source': source});

  void favoriteRemoved(String jobId) =>
      log('favorite_removed', {'job_id': jobId});

  void favoritesOpened(int count) =>
      log('favorites_opened', {'count': count});

  void searchSortChanged(String sortBy) =>
      log('search_sort_changed', {'sort_by': sortBy});

  void favoritesSortChanged(String sortBy) =>
      log('favorites_sort_changed', {'sort_by': sortBy});

  void favoritesBulkDelete(int count) =>
      log('favorites_bulk_delete', {'count': count});

  void addressTranslateToggled(bool showKorean) =>
      log(showKorean ? 'address_show_korean' : 'address_show_english');

  void pageLoaded(int page) =>
      log('page_loaded', {'page': page});

  void searchBarTap() => log('search_bar_tap');

  void partTimeToggle(bool checked) =>
      log('part_time_toggle', {'checked': checked});
}

final analytics = AnalyticsService();
