import 'dart:async';
import 'dart:convert';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/l10n/app_strings.dart';
import '../models/job.dart';
import '../models/filter_state.dart';
import '../../core/utils/region_mapper.dart';

class JobRepository {
  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 15);

  JobRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// 타임아웃 래퍼
  Future<T> _t<T>(Future<T> future) => future.timeout(_timeout);

  /// Performance 트레이스 래퍼
  Future<T> _traced<T>(String name, Future<T> Function() fn) async {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();
    try {
      final result = await fn();
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      trace.putAttribute('status', 'error');
      trace.putAttribute('error', e.runtimeType.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  static const _pageSize = 20;

  /// 제외할 사이트 이름 목록
  static const _excludedSiteNames = {'OKJob', 'KLiK', 'Here-Ro', 'Foreigner-Jobs'};

  /// education Set에서 가장 높은 값 반환
  static String? _maxEducation(Set<String> educations) {
    if (educations.isEmpty) return null;
    const order = ['none', 'middle_school', 'high_school', 'college', 'bachelor', 'master', 'doctor'];
    int maxIdx = 0;
    for (final e in educations) {
      final idx = order.indexOf(e);
      if (idx > maxIdx) maxIdx = idx;
    }
    return order[maxIdx];
  }

  /// experience Set에서 가장 높은 값 반환
  static String? _maxExperience(Set<String> experiences) {
    if (experiences.isEmpty) return null;
    const order = ['none', 'newcomer', '1y', '3y', '5y', '10y'];
    int maxIdx = 0;
    for (final e in experiences) {
      final idx = order.indexOf(e);
      if (idx > maxIdx) maxIdx = idx;
    }
    return order[maxIdx];
  }

  /// 조인 전용 select (번역 JSONB 제외 — RPC가 번역을 처리)
  static const _joinSelectQuery = '''
    id,
    sites(name, url),
    regions(id, si_name, gu_name),
    korean_levels(id, code, name_ko, name_en),
    work_schedules(id, code, name_ko, name_en),
    job_categories(id, name_ko, name_en),
    employment_types(id, name_ko, name_en),
    job_visas(visa_master(id, code, name_ko, name_en)),
    job_benefits(benefits(id, name_ko, name_en)),
    job_languages(language_id, proficiency, languages(code, name_ko, name_en))
  ''';

  // 마지막 getJobs RPC에서 가져온 total_count �시
  // ignore: unused_field
  int? _lastTotalCount;

  /// 상세용 select (description + description_translations 포함)
  static const _detailSelectQuery = '''
    *,
    sites(name, url),
    regions(id, si_name, gu_name),
    korean_levels(id, code, name_ko, name_en),
    work_schedules(id, code, name_ko, name_en),
    job_categories(id, name_ko, name_en),
    employment_types(id, name_ko, name_en),
    job_visas(visa_master(id, code, name_ko, name_en)),
    job_benefits(benefits(id, name_ko, name_en)),
    job_languages(language_id, proficiency, languages(code, name_ko, name_en))
  ''';

  /// FilterState → RPC params 변환
  Future<Map<String, dynamic>> _buildRpcParams({
    required FilterState filter,
    required String langCode,
    required int limit,
    required int offset,
    String sortBy = 'latest',
    bool includeTesting = false,
  }) async {
    final params = <String, dynamic>{
      'p_lang': langCode,
      'p_limit': limit,
      'p_offset': offset,
      'p_sort_by': sortBy,
    };
    // 테스트 모드: testing 사이트(JobnShop 등) 포함. 생략(false) 시 기존과 동일.
    if (includeTesting) params['p_include_testing'] = true;

    if (filter.visaIds.isNotEmpty) {
      params['p_visa_ids'] = filter.visaIds.toList();
    }
    if (filter.benefitIds.isNotEmpty) {
      params['p_benefit_ids'] = filter.benefitIds.toList();
    }
    if (filter.languageIds.isNotEmpty) {
      params['p_language_ids'] = filter.languageIds.toList();
    }
    if (filter.regionIds.isNotEmpty) {
      final allRegions = await _getAllRegions();
      final validIds = allRegions.map((r) => r['id'] as int).toSet();
      final validRegionIds = filter.regionIds.where(validIds.contains).toList();
      if (validRegionIds.isNotEmpty) {
        // 전국(nationwide) 공고도 함께 표시
        if (_nationwideRegionId != null) validRegionIds.add(_nationwideRegionId!);
        params['p_region_ids'] = validRegionIds;
      }
    }
    if (filter.categoryIds.isNotEmpty) {
      params['p_category_ids'] = filter.categoryIds.toList();
    }
    if (filter.employmentTypeIds.isNotEmpty) {
      const negotiableEmploymentId = '977e9c8e-7aa3-4528-9cbc-173d466b987f';
      final ids = filter.employmentTypeIds.toList();
      if (!ids.contains(negotiableEmploymentId)) ids.add(negotiableEmploymentId);
      params['p_employment_ids'] = ids;
    }
    if (filter.koreanLevelIds.isNotEmpty) {
      params['p_korean_level_ids'] = filter.koreanLevelIds.toList();
    }
    if (filter.workScheduleIds.isNotEmpty) {
      params['p_schedule_ids'] = filter.workScheduleIds.toList();
    }
    if (filter.salaryTypes.isNotEmpty) {
      final types = filter.salaryTypes.toList();
      if (!types.contains('negotiable')) types.add('negotiable');
      params['p_salary_types'] = types;
    }
    if (filter.gender != null && filter.gender != 'any') {
      params['p_gender'] = filter.gender;
    }
    final edu = _maxEducation(filter.educations);
    if (edu != null) {
      params['p_education'] = edu;
    }
    final exp = _maxExperience(filter.experiences);
    if (exp != null) {
      params['p_experience'] = exp;
    }
    if (filter.visaSponsorship != null) {
      params['p_visa_sponsorship'] = filter.visaSponsorship;
    }
    if (filter.countryIds.isNotEmpty) {
      params['p_country_ids'] = filter.countryIds.toList();
    }
    // 사이트 필터: 사용자 선택이 있으면 그대로, 없으면 제외 사이트 빼고 전체
    if (filter.siteIds.isNotEmpty) {
      params['p_site_ids'] = filter.siteIds.toList();
    } else {
      final excludeIds = await _getExcludedSiteIds();
      if (excludeIds.isNotEmpty) {
        final allSites = await getSiteOptions();
        final allowedIds = allSites.map((s) => s.id).toList();
        if (allowedIds.isNotEmpty) {
          params['p_site_ids'] = allowedIds;
        }
      }
    }

    return params;
  }

  /// 공고 목록 조회 (RPC get_jobs_page + 조인 후속 쿼리)
  Future<List<Job>> getJobs({
    FilterState filter = FilterState.empty,
    int page = 0,
    String langCode = 'ko',
    bool includeTesting = false,
  }) async {
    // 첫 페이지 요청 시 캐시된 total_count 리셋
    if (page == 0) _lastTotalCount = null;

    final params = await _buildRpcParams(
      filter: filter,
      langCode: langCode,
      limit: _pageSize,
      offset: page * _pageSize,
      includeTesting: includeTesting,
    );

    try {
      final data = await _traced('get_jobs_page', () => _t(_client.rpc('get_jobs_page', params: params)));
      final rows = data as List;
      if (rows.isEmpty) {
        _lastTotalCount = 0;
        return [];
      }

      // job_data 추출 + ID 목록 (순서 유지)
      final rpcJobs = <String, Map<String, dynamic>>{};
      final jobIds = <String>[];
      for (final row in rows) {
        final jobData = (row is Map && row.containsKey('job_data'))
            ? row['job_data'] as Map<String, dynamic>
            : row as Map<String, dynamic>;
        final id = jobData['id'].toString();
        rpcJobs[id] = jobData;
        jobIds.add(id);
      }

      // 조인 데이터 후속 쿼리 (sites, visas, categories 등)
      final joinData = await _t(
        _client.from('jobs').select(_joinSelectQuery).inFilter('id', jobIds),
      );
      final joinMap = <String, Map<String, dynamic>>{};
      for (final e in joinData as List) {
        joinMap[e['id'].toString()] = e;
      }

      // RPC 데이터 + 조인 데이터 병합하여 Job 생성 (RPC 순서 유지)
      return jobIds
          .map((id) => Job.fromRpcAndJoins(rpcJobs[id]!, joinMap[id], langCode))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 건수 캐시 (필터 JSON → 건수, 포그라운드 복귀 시 초기화)
  static final Map<String, int> _countCache = {};
  static void clearCountCache() => _countCache.clear();

  /// 전체 공고 건수 (별도 경량 RPC, 캐시 적용)
  Future<int> getJobCount({
    FilterState filter = FilterState.empty,
    String langCode = 'ko',
    bool includeTesting = false,
  }) async {
    // 캐시 키에 includeTesting 포함 — 토글 시 다른 값이 나와야 하므로
    final cacheKey = '${jsonEncode(filter.toJson())}|t:$includeTesting';
    if (_countCache.containsKey(cacheKey)) {
      return _countCache[cacheKey]!;
    }
    try {
      final params = await _buildRpcParams(
        filter: filter,
        langCode: langCode,
        limit: 1,
        offset: 0,
        includeTesting: includeTesting,
      );
      // count 전용 파라미터만 전달 (p_lang, p_limit, p_offset, p_sort_by 제외)
      params.remove('p_lang');
      params.remove('p_limit');
      params.remove('p_offset');
      params.remove('p_sort_by');
      final data = await _t(_client.rpc('get_jobs_count', params: params));
      final count = (data as int?) ?? 0;
      _countCache[cacheKey] = count;
      return count;
    } catch (_) {
      return -1;
    }
  }

  Future<List<Job>> searchJobs(String queryText, {int page = 0, String langCode = 'en', String sortBy = 'relevance', bool includeTesting = false}) async {
    final q = queryText.trim();
    if (q.isEmpty) return [];

    final offset = page * _pageSize;
    final data = await _traced('search_jobs_fuzzy', () => _t(_client.rpc('search_jobs_fuzzy', params: {
      'search_query': q,
      'lang_code': langCode,
      'sort_by': sortBy,
      'result_limit': _pageSize,
      'result_offset': offset,
      if (includeTesting) 'include_testing': true, // 테스트 모드 (search는 p_ 없음)
    })));

    final rows = data as List;
    if (rows.isEmpty) return [];

    // 제외 사이트 필터링
    final excludeIds = await _getExcludedSiteIds();

    // job_data 추출 + ID 목록 (순서 유지)
    final rpcJobs = <String, Map<String, dynamic>>{};
    final jobIds = <String>[];
    for (final row in rows) {
      if (row is! Map || !row.containsKey('job_data')) continue;
      final jobData = row['job_data'] as Map<String, dynamic>;
      final siteId = jobData['site_id']?.toString() ?? '';
      if (excludeIds.contains(siteId)) continue;
      final id = jobData['id'].toString();
      rpcJobs[id] = jobData;
      jobIds.add(id);
    }

    if (jobIds.isEmpty) return [];

    // 조인 데이터 후속 쿼리
    final joinData = await _t(
      _client.from('jobs').select(_joinSelectQuery).inFilter('id', jobIds),
    );
    final joinMap = <String, Map<String, dynamic>>{};
    for (final e in joinData as List) {
      joinMap[e['id'].toString()] = e;
    }

    // RPC 순서 유지
    return jobIds
        .map((id) => Job.fromRpcAndJoins(rpcJobs[id]!, joinMap[id], langCode))
        .toList();
  }

  Future<int> searchJobsCount(String queryText, {String langCode = 'en', bool includeTesting = false}) async {
    final q = queryText.trim();
    if (q.isEmpty) return 0;
    final data = await _t(_client.rpc('search_jobs_count', params: {
      'search_query': q,
      'lang_code': langCode,
      if (includeTesting) 'include_testing': true,
    }));
    return (data as int?) ?? 0;
  }

  Future<Job?> getJobById(String id) async {
    final data = await _t(
      _client.from('jobs').select(_detailSelectQuery).eq('id', id).maybeSingle(),
    );
    if (data == null) return null;
    return Job.fromJson(data);
  }

  /// 중복 그룹 공고 조회 (같은 duplicate_group_id를 가진 다른 사이트 공고)
  Future<List<DuplicateSource>> getDuplicateSources(String groupId) async {
    final data = await _t(
      _client.from('jobs')
          .select('id, url, site_id, sites(name, url)')
          .eq('duplicate_group_id', groupId)
          .eq('is_active', true),
    );
    return (data as List).map((e) {
      final sites = e['sites'] as Map<String, dynamic>?;
      return DuplicateSource(
        jobId: e['id'].toString(),
        jobUrl: e['url']?.toString() ?? '',
        siteName: sites?['name']?.toString() ?? '',
        siteUrl: sites?['url']?.toString() ?? '',
      );
    }).toList();
  }

  /// 중복 그룹 카운트 배치 조회 (groupId → 자신 제외 개수)
  Future<Map<String, int>> getDuplicateCounts(Set<String> groupIds) async {
    if (groupIds.isEmpty) return {};
    try {
      final data = await _t(
        _client.from('jobs')
            .select('duplicate_group_id')
            .inFilter('duplicate_group_id', groupIds.toList())
            .eq('is_active', true),
      );
      final counts = <String, int>{};
      for (final row in data as List) {
        final gid = row['duplicate_group_id']?.toString();
        if (gid != null) counts[gid] = (counts[gid] ?? 0) + 1;
      }
      // 자신 제외 (-1)
      return counts.map((k, v) => MapEntry(k, v > 1 ? v - 1 : 0));
    } catch (_) {
      return {};
    }
  }

  /// 즐겨찾기 공고 조회 (만료 포함)
  Future<List<Job>> getFavoriteJobs(List<String> jobIds) async {
    if (jobIds.isEmpty) return [];
    final data = await _t(
      _client.from('jobs').select(_detailSelectQuery).inFilter('id', jobIds),
    );
    return (data as List).map((e) => Job.fromJson(e)).toList();
  }

  /// [DEV] 사이트 목록 조회
  Future<List<FilterOption>> getSiteOptions() async {
    final data = await _t(
      _client.from('sites').select('id, name').order('name'),
    );
    return (data as List)
        .where((e) => !_excludedSiteNames.contains(e['name'] as String? ?? ''))
        .map((e) => FilterOption(
              id: e['id'].toString(),
              label: e['name'] as String? ?? '',
            ))
        .toList();
  }

  /// 제외할 사이트 ID 캐시
  static Set<String>? _excludedSiteIds;

  Future<Set<String>> _getExcludedSiteIds() async {
    if (_excludedSiteIds != null) return _excludedSiteIds!;
    final data = await _t(
      _client.from('sites').select('id, name'),
    );
    _excludedSiteIds = (data as List)
        .where((e) => _excludedSiteNames.contains(e['name'] as String? ?? ''))
        .map((e) => e['id'].toString())
        .toSet();
    return _excludedSiteIds!;
  }

  // ── 필터 옵션 로드 ──

  Future<List<FilterOption>> getVisaOptions() async {
    final data = await _t(
      _client.from('visa_master').select('id, code, name_ko, name_en, job_visas(count)').order('code'),
    );
    final list = (data as List).map((e) {
      final countData = e['job_visas'] as List?;
      final count = (countData != null && countData.isNotEmpty)
          ? (countData[0]['count'] as int? ?? 0)
          : 0;
      return (
        option: FilterOption(
          id: e['id'].toString(),
          label: e['code'] as String? ?? '',
        ),
        count: count,
      );
    }).toList();

    // ANY 제거 + 알파벳순 정렬
    list.removeWhere((e) => e.option.label.toUpperCase() == 'ANY');
    list.sort((a, b) => a.option.label.compareTo(b.option.label));

    return list.map((e) => e.option).toList();
  }

  /// 인기 비자 (한국 거주 외국인 소유 상위 10개)
  static const popularVisaCodes = {
    'H-2',   // 방문취업 (중국동포)
    'E-9',   // 비전문취업 (제조/농축산/건설)
    'F-4',   // 재외동포
    'F-2',   // 거주
    'F-5',   // 영주
    'F-6',   // 결혼이민
    'D-2',   // 유학
    'E-7',   // 특정활동 (IT/전문직)
    'D-4',   // 일반연수
    'D-10',  // 구직활동
  };

  Future<List<FilterOption>> getCategoryOptions(String langCode) async {
    final data = await _t(
      _client.from('job_categories').select('*').order('name_ko'),
    );
    final s = AppStrings.of(langCode);
    return (data as List)
        .map((e) {
          final nameEn = (e['name_en'] as String?) ?? '';
          final translated = s.translateJobCategory(nameEn);
          return FilterOption(
            id: e['id'].toString(),
            label: (translated != nameEn || langCode == 'en')
                ? translated
                : (e['name_$langCode'] as String?) ?? nameEn,
          );
        })
        .toList();
  }

  Future<List<FilterOption>> getEmploymentTypeOptions(String langCode) async {
    final data = await _t(
      _client.from('employment_types').select('*').order('name_ko'),
    );
    const negotiableEmploymentId = '977e9c8e-7aa3-4528-9cbc-173d466b987f';
    final s = AppStrings.of(langCode);
    return (data as List)
        .where((e) => e['id'].toString() != negotiableEmploymentId)
        .map((e) {
          final nameEn = (e['name_en'] as String?) ?? '';
          final translated = s.translateEmploymentType(nameEn);
          return FilterOption(
            id: e['id'].toString(),
            label: (translated != nameEn || langCode == 'en')
                ? translated
                : (e['name_$langCode'] as String?) ?? nameEn,
          );
        })
        .toList();
  }

  Future<List<FilterOption>> getBenefitOptions(String langCode) async {
    final data = await _t(
      _client.from('benefits').select('*').order('name_ko'),
    );
    final s = AppStrings.of(langCode);
    return (data as List)
        .map((e) {
          final nameEn = (e['name_en'] as String?) ?? '';
          final translated = s.translateBenefit(nameEn);
          return FilterOption(
            id: e['id'].toString(),
            label: (translated != nameEn || langCode == 'en')
                ? translated
                : (e['name_$langCode'] as String?) ?? nameEn,
          );
        })
        .toList();
  }

  /// 전체 지역 데이터 캐시 (id, si_name, gu_name, sort_order)
  static List<Map<String, dynamic>>? _allRegionsCache;
  static List<Map<String, dynamic>>? get allRegionsCacheSync => _allRegionsCache;
  /// "전국" region ID (지역 필터 시 항상 포함)
  static int? _nationwideRegionId;

  Future<List<Map<String, dynamic>>> _getAllRegions() async {
    if (_allRegionsCache == null) {
      final raw = List<Map<String, dynamic>>.from(
        await _t(_client.from('regions').select('id, si_name, gu_name, sort_order').order('sort_order', ascending: true).order('gu_name', ascending: true, nullsFirst: true)),
      );
      final nationwide = raw.where((e) => e['si_name'] == '전국').firstOrNull;
      _nationwideRegionId = nationwide != null ? nationwide['id'] as int : null;
      _allRegionsCache = raw.where((e) => e['si_name'] != '전국').toList();
    }
    return _allRegionsCache!;
  }

  /// 외부에서 캐시된 전체 지역 조회 (유효성 검증용)
  Future<List<Map<String, dynamic>>> getAllRegionsPublic() => _getAllRegions();

  /// 시/도 목록 (중복 제거, sort_order 순)
  Future<List<FilterOption>> getSiDoOptions(String langCode) async {
    final data = await _getAllRegions();
    final seen = <String>{};
    final options = <FilterOption>[];
    for (final e in data) {
      final siName = e['si_name'] as String? ?? '';
      if (siName.isNotEmpty && e['gu_name'] == null && seen.add(siName)) {
        options.add(FilterOption(
          id: siName,
          label: RegionMapper.getLocalizedName(siName, langCode),
        ));
      }
    }
    return options;
  }

  /// 특정 시/도의 구/군 목록
  /// 구/군 옵션 — label은 항상 한글 원본 (화면에서 다국어 조합)
  Future<List<FilterOption>> getGuGunOptions(String siName, String langCode) async {
    final data = await _getAllRegions();
    return data
        .where((e) => e['si_name'] == siName && e['gu_name'] != null)
        .map((e) => FilterOption(
              id: (e['id'] as int).toString(),
              label: e['gu_name'] as String,
            ))
        .toList();
  }

  /// 특정 시/도의 모든 region_id (시/도 행 + 구/군 행)
  /// 시/도의 모든 region_id (시/도 행 + 구/군 행 모두 포함)
  Future<List<int>> getRegionIdsForSiDo(String siName) async {
    final data = await _getAllRegions();
    final siRows = data.where((e) => e['si_name'] == siName).toList();
    // 시/도 레벨 레코드(gu_name=null) + 구/군 레코드 모두 포함
    return siRows.map<int>((e) => e['id'] as int).toList();
  }

  /// region_id로 시/도 + 구/군 이름 조회
  Future<Map<String, String?>> getRegionInfo(int regionId) async {
    final data = await _getAllRegions();
    final match = data.where((e) => e['id'] == regionId).firstOrNull;
    if (match == null) return {};
    return {
      'si_name': match['si_name'] as String?,
      'gu_name': match['gu_name'] as String?,
    };
  }

  Future<List<FilterOption>> getKoreanLevelOptions(String langCode) async {
    final data = await _t(
      _client.from('korean_levels').select('id, code, name_ko, name_en').order('sort_order'),
    );
    final s = AppStrings.of(langCode);
    return (data as List)
        .map((e) {
          final nameEn = (e['name_en'] as String?) ?? e['code'] as String;
          final translated = s.translateKoreanLevel(nameEn);
          return FilterOption(
            id: e['id'].toString(),
            label: (translated != nameEn || langCode == 'en')
                ? translated
                : langCode == 'ko'
                    ? (e['name_ko'] as String?) ?? nameEn
                    : nameEn,
          );
        })
        .toList();
  }

  Future<List<FilterOption>> getWorkScheduleOptions(String langCode) async {
    final data = await _t(
      _client.from('work_schedules').select('id, code, name_ko, name_en').order('sort_order'),
    );
    final s = AppStrings.of(langCode);
    return (data as List)
        .map((e) {
          final nameEn = (e['name_en'] as String?) ?? e['code'] as String;
          final translated = s.translateWorkSchedule(nameEn);
          return FilterOption(
            id: e['id'].toString(),
            label: (translated != nameEn || langCode == 'en')
                ? translated
                : langCode == 'ko'
                    ? (e['name_ko'] as String?) ?? nameEn
                    : nameEn,
          );
        })
        .toList();
  }

  Future<List<FilterOption>> getLanguageOptions(String langCode) async {
    final data = await _t(
      _client.from('languages').select('id, code, name_ko, name_en').order('name_en'),
    );
    return (data as List)
        .map((e) => FilterOption(
              id: e['id'].toString(),
              label: langCode == 'ko'
                  ? (e['name_ko'] as String?) ?? e['code'] as String
                  : (e['name_en'] as String?) ?? e['code'] as String,
            ))
        .toList();
  }

  Future<List<FilterOption>> getCountryOptions(String langCode) async {
    final data = await _t(
      _client.from('countries').select('id, name_ko, name_en, code').order('name_en'),
    );
    final s = AppStrings.of(langCode);
    return (data as List)
        .where((e) => (e['name_en'] as String?) != 'Any nationality')
        .map((e) {
          final code = e['code'] as String? ?? '';
          return FilterOption(
            id: e['id'].toString(),
            label: code.isNotEmpty
                ? s.countryName(code)
                : (e['name_en'] as String?) ?? '',
          );
        })
        .toList();
  }

  /// 필터 옵션별 공고 건수 조회 (RPC)
  Future<FilterCounts> getFilterCounts({bool includeTesting = false}) async {
    final data = await _t(_client.rpc('get_filter_counts',
        params: {if (includeTesting) 'p_include_testing': true}));
    return FilterCounts.fromJson(data as Map<String, dynamic>);
  }

  /// 공고 설명 Lazy 번역 (Edge Function: 캐시 히트 시 즉시, 미스 시 Google Translate 호출)
  Future<String> translateDescription(String jobId, String langCode) async {
    // 번역은 긴 설명 + 콜드스타트 시 15초를 넘길 수 있어 전용 타임아웃 사용
    final response = await _client.functions.invoke(
      'translate-description',
      body: {'job_id': jobId, 'lang': langCode},
    ).timeout(const Duration(seconds: 30));
    if (response.status != 200) throw Exception('Translation failed: ${response.status}');
    final data = response.data as Map<String, dynamic>;
    final description = data['description'] as String?;
    if (description == null || description.isEmpty) throw Exception('Empty translation');
    return description;
  }
}
