import 'package:korea_job/core/l10n/app_strings.dart';
import 'package:korea_job/core/utils/region_mapper.dart';
import 'package:korea_job/core/utils/district_names.dart';

class DuplicateSource {
  final String jobId;
  final String jobUrl;
  final String siteName;
  final String siteUrl;

  const DuplicateSource({
    required this.jobId,
    required this.jobUrl,
    required this.siteName,
    required this.siteUrl,
  });
}

class VisaInfo {
  final String id;
  final String code;
  final String? nameKo;
  final String? nameEn;

  const VisaInfo({
    required this.id,
    required this.code,
    this.nameKo,
    this.nameEn,
  });

  String get displayName => code;
}

class CategoryInfo {
  final String id;
  final Map<String, String?> names;

  const CategoryInfo({required this.id, required this.names});

  String getName(String langCode) =>
      names['name_$langCode'] ?? names['name_en'] ?? '';
}

class EmploymentTypeInfo {
  final String id;
  final Map<String, String?> names;

  const EmploymentTypeInfo({required this.id, required this.names});

  String getName(String langCode) =>
      names['name_$langCode'] ?? names['name_en'] ?? '';
}

class BenefitInfo {
  final String id;
  final Map<String, String?> names;

  const BenefitInfo({required this.id, required this.names});

  String getName(String langCode) =>
      names['name_$langCode'] ?? names['name_en'] ?? '';
}

class RegionInfo {
  final int id;
  final String? siName;
  final String? guName;

  const RegionInfo({required this.id, this.siName, this.guName});

  String get displayName {
    if (guName != null && guName!.isNotEmpty) return '$guName, $siName';
    return siName ?? '';
  }
}

class KoreanLevelInfo {
  final int id;
  final String code;
  final String? nameKo;
  final String? nameEn;

  const KoreanLevelInfo({
    required this.id,
    required this.code,
    this.nameKo,
    this.nameEn,
  });

  String getName(String langCode) {
    if (langCode == 'ko') return nameKo ?? code;
    return nameEn ?? code;
  }
}

class WorkScheduleInfo {
  final int id;
  final String code;
  final String? nameKo;
  final String? nameEn;

  const WorkScheduleInfo({
    required this.id,
    required this.code,
    this.nameKo,
    this.nameEn,
  });

  String getName(String langCode) {
    if (langCode == 'ko') return nameKo ?? code;
    return nameEn ?? code;
  }
}

class JobLanguageInfo {
  final int languageId;
  final String? proficiency;
  final String? langCode;
  final String? langNameKo;
  final String? langNameEn;

  const JobLanguageInfo({
    required this.languageId,
    this.proficiency,
    this.langCode,
    this.langNameKo,
    this.langNameEn,
  });

  String getName(String uiLang) {
    if (uiLang == 'ko') return langNameKo ?? langCode ?? '';
    return langNameEn ?? langCode ?? '';
  }
}

class Job {
  final String id;
  final String siteId;
  final String? siteName;
  final String? siteUrl;
  final String? title;
  final String? company;
  final String? location;
  final String? addressDetail;
  final String? salary;
  final String? salaryTypeRaw;  // 'hourly', 'monthly', 'annual', 'company_rule', 'negotiable'
  final int? salaryAmount;
  final String? workDays;
  final String? workTime;
  final String? workModel;
  final String? jobType;
  final String? description;
  final String? url;
  final bool isActive;
  final String? expiresAt;
  final String? crawledAt;
  final String? postedAt;
  final bool? housingProvided;
  final bool? drivingLicense;
  final List<String> nationalityRestrictions;
  final String? duplicateGroupId;

  // jsonb 번역 필드
  final Map<String, dynamic> titleTranslations;
  final Map<String, dynamic> jobTypeTranslations;
  final Map<String, dynamic> descriptionTranslations;
  final Map<String, dynamic> addressTranslations;
  final Map<String, dynamic> workModelTranslations;
  final Map<String, dynamic> workTimeTranslations;

  // FK 필드 (uuid)
  final String? jobCategoryId;
  final String? employmentTypeId;

  // FK 필드 (bigint)
  final int? regionId;
  final int? workScheduleId;
  final String? workStartTime;
  final String? workEndTime;
  final int? koreanLevelId;
  final bool? visaSponsorship;

  // 조인된 관계 데이터
  final List<VisaInfo> visas;
  final CategoryInfo? jobCategory;
  final EmploymentTypeInfo? employmentType;
  final List<BenefitInfo> benefits;
  final RegionInfo? region;
  final KoreanLevelInfo? koreanLevel;
  final WorkScheduleInfo? workSchedule;
  final List<JobLanguageInfo> jobLanguages;

  const Job({
    required this.id,
    required this.siteId,
    this.siteName,
    this.siteUrl,
    this.title,
    this.company,
    this.location,
    this.addressDetail,
    this.salary,
    this.salaryTypeRaw,
    this.salaryAmount,
    this.workDays,
    this.workTime,
    this.workModel,
    this.jobType,
    this.description,
    this.url,
    this.isActive = true,
    this.expiresAt,
    this.crawledAt,
    this.postedAt,
    this.housingProvided,
    this.drivingLicense,
    this.nationalityRestrictions = const [],
    this.duplicateGroupId,
    this.titleTranslations = const {},
    this.jobTypeTranslations = const {},
    this.descriptionTranslations = const {},
    this.addressTranslations = const {},
    this.workModelTranslations = const {},
    this.workTimeTranslations = const {},
    this.jobCategoryId,
    this.employmentTypeId,
    this.regionId,
    this.workScheduleId,
    this.workStartTime,
    this.workEndTime,
    this.koreanLevelId,
    this.visaSponsorship,
    this.visas = const [],
    this.jobCategory,
    this.employmentType,
    this.benefits = const [],
    this.region,
    this.koreanLevel,
    this.workSchedule,
    this.jobLanguages = const [],
  });

  /// 현재 언어에 맞는 제목 (ko → 원문 우선, 그 외 → translations → en → 원문)
  String getTitle(String langCode) {
    if (langCode == 'ko') return title ?? _translated(titleTranslations, 'ko') ?? '';
    return _translated(titleTranslations, langCode) ?? title ?? '';
  }

  /// 현재 언어에 맞는 직종명 (app_strings 번역 우선, 폴백: translations jsonb → 원문)
  String getJobType(String langCode) {
    if (jobCategory != null) {
      final nameEn = jobCategory!.getName('en');
      final translated = AppStrings.of(langCode).translateJobCategory(nameEn);
      if (translated != nameEn || langCode == 'en') return translated;
      return jobCategory!.getName(langCode);
    }
    // jobCategory 없는 공고: 앱 번역 → jsonb → 원문 폴백
    final raw = jobType ?? '';
    if (raw.isNotEmpty) {
      // "마감 D-XX" 같은 잘못된 데이터 필터링
      if (raw.startsWith('마감')) return '';
      final appTranslated = AppStrings.of(langCode).translateJobTypeRaw(raw);
      if (appTranslated != null) return appTranslated;
    }
    if (jobTypeTranslations.isNotEmpty) {
      if (langCode == 'ko') return raw.isNotEmpty ? raw : (_translated(jobTypeTranslations, 'ko') ?? '');
      return _translated(jobTypeTranslations, langCode) ?? raw;
    }
    return langCode == 'ko' ? raw : '';
  }

  /// 상세설명 순수 텍스트 (한국어 원본, 검색 결과 등 비HTML용)
  String getDescription() {
    var text = description ?? '';
    // 다양한 개행 패턴을 실제 줄바꿈으로 변환
    text = text.replaceAll('<br>', '\n');
    text = text.replaceAll('<br/>', '\n');
    text = text.replaceAll('<br />', '\n');
    text = text.replaceAll('\\r\\n', '\n');
    text = text.replaceAll('\\n', '\n');
    text = text.replaceAll('\\r', '\n');
    return text.trim();
  }

  /// 상세설명 텍스트 (번역 우선 → 원문, HTML 태그 제거)
  String getDescriptionText([String? langCode]) {
    String text;
    if (langCode != null && langCode != 'ko') {
      final translated = descriptionTranslations[langCode]?.toString();
      if (translated != null && translated.isNotEmpty) {
        text = translated;
      } else {
        text = description ?? '';
      }
    } else {
      text = description ?? '';
    }
    // HTML → 텍스트 변환
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // 번역 줄바꿈 마커 → 실제 줄바꿈 (‖NL‖, ‖एनएल‖ 등)
    text = text.replaceAll(RegExp(r'‖[^‖]*‖'), '\n');
    // 이스케이프된 줄바꿈 → 실제 줄바꿈
    text = text.replaceAll('\\r\\n', '\n');
    text = text.replaceAll('\\n', '\n');
    text = text.replaceAll('\\r', '\n');
    // 연속 줄바꿈 정리
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// 상세설명 HTML (한국어 원본, 상세 화면용)
  String getDescriptionHtml([String? langCode]) {
    // 번역이 있으면 해당 언어로 표시
    if (langCode != null && langCode != 'ko') {
      final translated = descriptionTranslations[langCode]?.toString();
      if (translated != null && translated.isNotEmpty) {
        return translated.replaceAll('\n', '<br>').trim();
      }
    }
    // 원문 (한국어)
    var text = description ?? '';
    text = text.replaceAll('\\r\\n', '<br>');
    text = text.replaceAll('\\n', '<br>');
    text = text.replaceAll('\\r', '<br>');
    text = text.replaceAll('\n', '<br>');
    return text.trim();
  }

  /// 고용형태 표시명 (app_strings 번역 우선, 폴백: DB name)
  String getEmploymentType(String langCode) {
    if (employmentType != null) {
      final nameEn = employmentType!.getName('en');
      final translated = AppStrings.of(langCode).translateEmploymentType(nameEn);
      if (translated != nameEn || langCode == 'en') return translated;
      return employmentType!.getName(langCode);
    }
    return '';
  }

  /// 한국어 능력 표시명 (app_strings 번역 우선, 폴백: DB name)
  String getKoreanLevel(String langCode) {
    if (koreanLevel != null) {
      final nameEn = koreanLevel!.getName('en');
      final translated = AppStrings.of(langCode).translateKoreanLevel(nameEn);
      if (translated != nameEn || langCode == 'en') return translated;
      return koreanLevel!.getName(langCode);
    }
    return '';
  }

  /// 근무형태 표시명 (translations → en → 원문 폴백)
  String getWorkModel(String langCode) {
    if (langCode == 'ko') return workModel ?? '';
    return _translated(workModelTranslations, langCode) ?? workModel ?? '';
  }

  /// 근무요일 표시명 (app_strings 번역 우선, 폴백: DB name)
  String getWorkSchedule(String langCode) {
    if (workSchedule != null) {
      final nameEn = workSchedule!.getName('en');
      final translated = AppStrings.of(langCode).translateWorkSchedule(nameEn);
      if (translated != nameEn || langCode == 'en') return translated;
      return workSchedule!.getName(langCode);
    }
    return '';
  }

  /// 주소 표시 (ko → 원문, 그 외 → en 번역 폴백)
  String getAddress(String langCode) {
    if (langCode == 'ko') {
      return addressDetail ?? location ?? region?.displayName ?? '';
    }
    final translated = _translated(addressTranslations, 'en');
    if (translated != null) return translated;
    if (region != null) return region!.displayName;
    return addressDetail ?? location ?? '';
  }

  /// 카드용 짧은 지역명 (번역 → region 조인 → location 추출)
  String getShortLocation(String langCode) {
    if (langCode == 'ko') {
      // 한국어: 원문에서 앞 2단어 (예: "경기 성남시 수정구..." → "경기 성남시")
      final raw = addressDetail ?? location;
      if (raw != null && raw.isNotEmpty) {
        final words = raw.split(' ');
        if (words.length >= 2) {
          final first = words[0];
          if (!_isSiDoName(first) && region != null) {
            return _regionShortName('ko');
          }
          return '${words[0]} ${words[1]}';
        }
        return words.first;
      }
      if (region != null) return _regionShortName('ko');
      return '';
    }
    // 그 외: en 번역 → 괄호 제거 후 콤마 구분 뒤 2개 (마지막은 첫 단어만)
    final translated = _translated(addressTranslations, 'en');
    if (translated != null) {
      final cleaned = translated.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
      final parts = cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.length >= 2) {
        final lastWords = parts.last.split(' ');
        final siDo = lastWords.first;
        if (!siDo.contains('-do') && !siDo.contains('-si') && !_isEnSiDoName(siDo) && region != null) {
          return _regionShortName(langCode);
        }
        return '${parts[parts.length - 2]}, $siDo';
      }
      return parts.isNotEmpty ? parts.last.split(' ').first : translated;
    }
    if (region != null) return _regionShortName(langCode);
    if (location == null || location!.isEmpty) return '';
    final parts = location!.split(' ');
    if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
    return parts.first;
  }

  String _regionShortName(String langCode) {
    if (region == null) return '';
    final si = region!.siName ?? '';
    final gu = region!.guName;
    if (langCode == 'ko') {
      return gu != null ? '$si $gu' : si;
    }
    final siEn = RegionMapper.getLocalizedName(si, 'en');
    if (gu != null) {
      final guEn = DistrictNames.getLocalizedGuName(gu, si, 'en');
      return '$guEn, $siEn';
    }
    return siEn;
  }

  static bool _isSiDoName(String s) {
    const names = {'서울','부산','대구','인천','광주','대전','울산','세종','경기','강원','충북','충남','전북','전남','경북','경남','제주'};
    return names.contains(s);
  }

  static bool _isEnSiDoName(String s) {
    const names = {'Seoul','Busan','Daegu','Incheon','Gwangju','Daejeon','Ulsan','Sejong',
                   'Gyeonggi-do','Gangwon-do','Chungcheongbuk-do','Chungcheongnam-do',
                   'Jeollabuk-do','Jeollanam-do','Gyeongsangbuk-do','Gyeongsangnam-do','Jeju-do'};
    return names.contains(s);
  }

  /// 근무시간 표시
  String get displayWorkTime {
    if (workStartTime != null && workEndTime != null) {
      return '${_formatTime(workStartTime!)} - ${_formatTime(workEndTime!)}';
    }
    return workTime ?? '';
  }

  /// 근무시간 표시 (ko → 원문, 그 외 → 번역 → 구조화 시간 → 원문)
  String getWorkTime(String langCode) {
    if (langCode == 'ko') {
      if (workStartTime != null && workEndTime != null) {
        return '${_formatTime(workStartTime!)} - ${_formatTime(workEndTime!)}';
      }
      return workTime ?? '';
    }
    // 번역 찾기 (en 폴백 없이 해당 언어만)
    final translated = workTimeTranslations[langCode]?.toString();
    if (translated != null && translated.isNotEmpty) return translated;
    // 구조화된 시간 필드 (숫자라 언어 무관)
    if (workStartTime != null && workEndTime != null) {
      return '${_formatTime(workStartTime!)} - ${_formatTime(workEndTime!)}';
    }
    // 원문
    return workTime ?? '';
  }

  String? _translated(Map<String, dynamic> translations, String langCode) {
    final val = translations[langCode];
    if (val != null && val.toString().isNotEmpty) return val.toString();
    final en = translations['en'];
    if (en != null && en.toString().isNotEmpty) return en.toString();
    return null;
  }

  String _formatTime(String time) {
    // "09:00:00" → "09:00"
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  // ── 안전한 타입 파싱 헬퍼 ──
  static String _str(dynamic v, [String fallback = '']) =>
      v?.toString() ?? fallback;

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static bool _bool(dynamic v, [bool fallback = false]) {
    if (v is bool) return v;
    return fallback;
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map<String, dynamic> ? v : {};

  factory Job.fromJson(Map<String, dynamic> json) {
    // 비자 조인: job_visas → visa_master
    final visas = <VisaInfo>[];
    final jobVisas = json['job_visas'] as List<dynamic>?;
    if (jobVisas != null) {
      for (final jv in jobVisas) {
        final vm = jv['visa_master'] as Map<String, dynamic>?;
        if (vm != null) {
          visas.add(VisaInfo(
            id: vm['id'].toString(),
            code: vm['code'] as String? ?? '',
            nameKo: vm['name_ko'] as String?,
            nameEn: vm['name_en'] as String?,
          ));
        }
      }
    }

    // 직종 카테고리 조인
    CategoryInfo? jobCategory;
    final catJson = json['job_categories'] as Map<String, dynamic>?;
    if (catJson != null) {
      jobCategory = CategoryInfo(
        id: catJson['id'].toString(),
        names: catJson.map((k, v) => MapEntry(k, v?.toString())),
      );
    }

    // 고용형태 조인
    EmploymentTypeInfo? employmentType;
    final etJson = json['employment_types'] as Map<String, dynamic>?;
    if (etJson != null) {
      employmentType = EmploymentTypeInfo(
        id: etJson['id'].toString(),
        names: etJson.map((k, v) => MapEntry(k, v?.toString())),
      );
    }

    // 복리후생 조인: job_benefits → benefits
    final benefits = <BenefitInfo>[];
    final jobBenefits = json['job_benefits'] as List<dynamic>?;
    if (jobBenefits != null) {
      for (final jb in jobBenefits) {
        final b = jb['benefits'] as Map<String, dynamic>?;
        if (b != null) {
          benefits.add(BenefitInfo(
            id: b['id'].toString(),
            names: b.map((k, v) => MapEntry(k, v?.toString())),
          ));
        }
      }
    }

    // 지역 조인
    RegionInfo? region;
    final regJson = json['regions'] as Map<String, dynamic>?;
    if (regJson != null) {
      region = RegionInfo(
        id: _int(regJson['id']) ?? 0,
        siName: regJson['si_name']?.toString(),
        guName: regJson['gu_name']?.toString(),
      );
    }

    // 한국어 능력 조인
    KoreanLevelInfo? koreanLevel;
    final klJson = json['korean_levels'] as Map<String, dynamic>?;
    if (klJson != null) {
      koreanLevel = KoreanLevelInfo(
        id: _int(klJson['id']) ?? 0,
        code: _str(klJson['code']),
        nameKo: klJson['name_ko']?.toString(),
        nameEn: klJson['name_en']?.toString(),
      );
    }

    // 근무요일 조인
    WorkScheduleInfo? workSchedule;
    final wsJson = json['work_schedules'] as Map<String, dynamic>?;
    if (wsJson != null) {
      workSchedule = WorkScheduleInfo(
        id: _int(wsJson['id']) ?? 0,
        code: _str(wsJson['code']),
        nameKo: wsJson['name_ko']?.toString(),
        nameEn: wsJson['name_en']?.toString(),
      );
    }

    // 언어 능력 조인: job_languages → languages
    final jobLanguages = <JobLanguageInfo>[];
    final jlList = json['job_languages'] as List<dynamic>?;
    if (jlList != null) {
      for (final jl in jlList) {
        final langData = jl['languages'] as Map<String, dynamic>?;
        jobLanguages.add(JobLanguageInfo(
          languageId: _int(jl['language_id']) ?? 0,
          proficiency: jl['proficiency']?.toString(),
          langCode: langData?['code']?.toString(),
          langNameKo: langData?['name_ko']?.toString(),
          langNameEn: langData?['name_en']?.toString(),
        ));
      }
    }

    final sitesJson = _map(json['sites']);

    return Job(
      id: _str(json['id']),
      siteId: _str(json['site_id']),
      siteName: sitesJson['name']?.toString(),
      siteUrl: sitesJson['url']?.toString(),
      title: json['title']?.toString(),
      company: json['company']?.toString(),
      location: json['location']?.toString(),
      addressDetail: json['address_detail']?.toString(),
      salary: json['salary']?.toString(),
      salaryTypeRaw: json['salary_type']?.toString(),
      salaryAmount: _int(json['salary_amount']),
      workDays: json['work_days']?.toString(),
      workTime: json['work_time']?.toString(),
      workModel: json['work_model']?.toString(),
      jobType: json['job_type']?.toString(),
      description: json['description']?.toString(),
      url: json['url']?.toString(),
      isActive: _bool(json['is_active'], true),
      expiresAt: json['expires_at']?.toString(),
      crawledAt: json['crawled_at']?.toString(),
      postedAt: json['posted_at']?.toString(),
      housingProvided: json['housing_provided'] is bool ? json['housing_provided'] : null,
      drivingLicense: json['driving_license'] is bool ? json['driving_license'] : null,
      duplicateGroupId: json['duplicate_group_id']?.toString(),
      nationalityRestrictions:
          (json['nationality_restrictions'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      titleTranslations: _map(json['title_translations']),
      jobTypeTranslations: _map(json['job_type_translations']),
      descriptionTranslations: _map(json['description_translations']),
      addressTranslations: _map(json['address_translations']),
      workModelTranslations: _map(json['work_model_translations']),
      workTimeTranslations: _map(json['work_time_translations']),
      jobCategoryId: json['job_category_id']?.toString(),
      employmentTypeId: json['employment_type_id']?.toString(),
      regionId: _int(json['region_id']),
      workScheduleId: _int(json['work_schedule_id']),
      workStartTime: json['work_start_time']?.toString(),
      workEndTime: json['work_end_time']?.toString(),
      koreanLevelId: _int(json['korean_level_id']),
      visaSponsorship: json['visa_sponsorship'] is bool ? json['visa_sponsorship'] : null,
      visas: visas,
      jobCategory: jobCategory,
      employmentType: employmentType,
      benefits: benefits,
      region: region,
      koreanLevel: koreanLevel,
      workSchedule: workSchedule,
      jobLanguages: jobLanguages,
    );
  }

  /// RPC get_jobs_page 응답 + 조인 데이터로 Job 생성
  /// rpcJobData: RPC job_data (기본 컬럼 + 번역 필드)
  /// joinData: 후속 조인 쿼리 결과 (sites, visas, categories 등)
  /// langCode: 현재 언어 코드
  factory Job.fromRpcAndJoins(
    Map<String, dynamic> rpcJobData,
    Map<String, dynamic>? joinData,
    String langCode,
  ) {
    final j = joinData ?? {};

    // 조인 데이터 파싱 (fromJson과 동일한 로직)
    final visas = <VisaInfo>[];
    final jobVisas = j['job_visas'] as List<dynamic>?;
    if (jobVisas != null) {
      for (final jv in jobVisas) {
        final vm = jv['visa_master'] as Map<String, dynamic>?;
        if (vm != null) {
          visas.add(VisaInfo(
            id: vm['id'].toString(),
            code: vm['code'] as String? ?? '',
            nameKo: vm['name_ko'] as String?,
            nameEn: vm['name_en'] as String?,
          ));
        }
      }
    }

    CategoryInfo? jobCategory;
    final catJson = j['job_categories'] as Map<String, dynamic>?;
    if (catJson != null) {
      jobCategory = CategoryInfo(
        id: catJson['id'].toString(),
        names: catJson.map((k, v) => MapEntry(k, v?.toString())),
      );
    }

    EmploymentTypeInfo? employmentType;
    final etJson = j['employment_types'] as Map<String, dynamic>?;
    if (etJson != null) {
      employmentType = EmploymentTypeInfo(
        id: etJson['id'].toString(),
        names: etJson.map((k, v) => MapEntry(k, v?.toString())),
      );
    }

    final benefits = <BenefitInfo>[];
    final jobBenefits = j['job_benefits'] as List<dynamic>?;
    if (jobBenefits != null) {
      for (final jb in jobBenefits) {
        final b = jb['benefits'] as Map<String, dynamic>?;
        if (b != null) {
          benefits.add(BenefitInfo(
            id: b['id'].toString(),
            names: b.map((k, v) => MapEntry(k, v?.toString())),
          ));
        }
      }
    }

    RegionInfo? region;
    final regJson = j['regions'] as Map<String, dynamic>?;
    if (regJson != null) {
      region = RegionInfo(
        id: _int(regJson['id']) ?? 0,
        siName: regJson['si_name']?.toString(),
        guName: regJson['gu_name']?.toString(),
      );
    }

    KoreanLevelInfo? koreanLevel;
    final klJson = j['korean_levels'] as Map<String, dynamic>?;
    if (klJson != null) {
      koreanLevel = KoreanLevelInfo(
        id: _int(klJson['id']) ?? 0,
        code: _str(klJson['code']),
        nameKo: klJson['name_ko']?.toString(),
        nameEn: klJson['name_en']?.toString(),
      );
    }

    WorkScheduleInfo? workSchedule;
    final wsJson = j['work_schedules'] as Map<String, dynamic>?;
    if (wsJson != null) {
      workSchedule = WorkScheduleInfo(
        id: _int(wsJson['id']) ?? 0,
        code: _str(wsJson['code']),
        nameKo: wsJson['name_ko']?.toString(),
        nameEn: wsJson['name_en']?.toString(),
      );
    }

    final jobLanguages = <JobLanguageInfo>[];
    final jlList = j['job_languages'] as List<dynamic>?;
    if (jlList != null) {
      for (final jl in jlList) {
        final langData = jl['languages'] as Map<String, dynamic>?;
        jobLanguages.add(JobLanguageInfo(
          languageId: _int(jl['language_id']) ?? 0,
          proficiency: jl['proficiency']?.toString(),
          langCode: langData?['code']?.toString(),
          langNameKo: langData?['name_ko']?.toString(),
          langNameEn: langData?['name_en']?.toString(),
        ));
      }
    }

    final sitesJson = _map(j['sites']);

    // RPC 번역 필드 → Map 형태로 변환
    final titleTranslated = rpcJobData['title_translated']?.toString();
    final titleEn = rpcJobData['title_en']?.toString();
    final addressTranslated = rpcJobData['address_translated']?.toString();
    final addressEn = rpcJobData['address_en']?.toString();
    final descTranslated = rpcJobData['description_translated']?.toString();
    final workTimeTranslated = rpcJobData['work_time_translated']?.toString();

    // search_jobs_fuzzy는 title_translations jsonb를 직접 반환
    final titleTranslations = <String, dynamic>{..._map(rpcJobData['title_translations'])};
    if (titleTranslated != null && titleTranslated.isNotEmpty) {
      titleTranslations[langCode] = titleTranslated;
    }
    if (titleEn != null && titleEn.isNotEmpty) {
      titleTranslations['en'] = titleEn;
    }

    final addressTranslations = <String, dynamic>{..._map(rpcJobData['address_translations'])};
    if (addressTranslated != null && addressTranslated.isNotEmpty) {
      addressTranslations[langCode] = addressTranslated;
    }
    if (addressEn != null && addressEn.isNotEmpty) {
      addressTranslations['en'] = addressEn;
    }

    final descTranslations = <String, dynamic>{..._map(rpcJobData['description_translations'])};
    if (descTranslated != null && descTranslated.isNotEmpty) {
      descTranslations[langCode] = descTranslated;
    }

    final workTimeTranslations = <String, dynamic>{..._map(rpcJobData['work_time_translations'])};
    if (workTimeTranslated != null && workTimeTranslated.isNotEmpty) {
      workTimeTranslations[langCode] = workTimeTranslated;
    }

    return Job(
      id: _str(rpcJobData['id']),
      siteId: _str(rpcJobData['site_id']),
      siteName: sitesJson['name']?.toString(),
      siteUrl: sitesJson['url']?.toString(),
      title: rpcJobData['title']?.toString(),
      company: rpcJobData['company']?.toString(),
      location: rpcJobData['location']?.toString(),
      addressDetail: rpcJobData['address_detail']?.toString(),
      salary: rpcJobData['salary']?.toString(),
      salaryTypeRaw: rpcJobData['salary_type']?.toString(),
      salaryAmount: _int(rpcJobData['salary_amount']),
      workDays: rpcJobData['work_days']?.toString(),
      workTime: rpcJobData['work_time']?.toString(),
      workModel: rpcJobData['work_model']?.toString(),
      jobType: rpcJobData['job_type']?.toString(),
      description: rpcJobData['description']?.toString(),
      url: rpcJobData['url']?.toString(),
      isActive: _bool(rpcJobData['is_active'], true),
      expiresAt: rpcJobData['expires_at']?.toString(),
      crawledAt: rpcJobData['crawled_at']?.toString(),
      postedAt: rpcJobData['posted_at']?.toString(),
      housingProvided: rpcJobData['housing_provided'] is bool ? rpcJobData['housing_provided'] : null,
      drivingLicense: rpcJobData['driving_license'] is bool ? rpcJobData['driving_license'] : null,
      duplicateGroupId: rpcJobData['duplicate_group_id']?.toString(),
      nationalityRestrictions:
          (rpcJobData['nationality_restrictions'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      titleTranslations: titleTranslations,
      jobTypeTranslations: const {},
      descriptionTranslations: descTranslations,
      addressTranslations: addressTranslations,
      workModelTranslations: const {},
      workTimeTranslations: workTimeTranslations,
      jobCategoryId: rpcJobData['job_category_id']?.toString(),
      employmentTypeId: rpcJobData['employment_type_id']?.toString(),
      regionId: _int(rpcJobData['region_id']),
      workScheduleId: _int(rpcJobData['work_schedule_id']),
      workStartTime: rpcJobData['work_start_time']?.toString(),
      workEndTime: rpcJobData['work_end_time']?.toString(),
      koreanLevelId: _int(rpcJobData['korean_level_id']),
      visaSponsorship: rpcJobData['visa_sponsorship'] is bool ? rpcJobData['visa_sponsorship'] : null,
      visas: visas,
      jobCategory: jobCategory,
      employmentType: employmentType,
      benefits: benefits,
      region: region,
      koreanLevel: koreanLevel,
      workSchedule: workSchedule,
      jobLanguages: jobLanguages,
    );
  }

  int? get dDay {
    if (expiresAt == null) return null;
    final expires = DateTime.tryParse(expiresAt!);
    if (expires == null) return null;
    return expires.difference(DateTime.now()).inDays;
  }

  String get companyInitial {
    if (company == null || company!.isEmpty) return '?';
    return company![0].toUpperCase();
  }

  /// 급여 타입 감지 (DB salary_type 우선, 없으면 텍스트 파싱)
  SalaryType get salaryType {
    if (salaryTypeRaw != null) {
      switch (salaryTypeRaw) {
        case 'hourly': return SalaryType.hourly;
        case 'daily': return SalaryType.daily;
        case 'weekly': return SalaryType.weekly;
        case 'monthly': return SalaryType.monthly;
        case 'annual': return SalaryType.annual;
        case 'company_rule': return SalaryType.companyRule;
        case 'negotiable': return SalaryType.negotiable;
      }
    }
    if (salary == null) return SalaryType.unknown;
    final s = salary!.toLowerCase();
    if (s.contains('시급') || s.contains('시간') || s.contains('/h') || s.contains('per hour') || s.contains('hourly')) {
      return SalaryType.hourly;
    }
    if (s.contains('연봉') || s.contains('연간') || s.contains('annual') || s.contains('/year') || s.contains('yearly')) {
      return SalaryType.annual;
    }
    return SalaryType.monthly;
  }
}

enum SalaryType { hourly, daily, weekly, monthly, annual, companyRule, negotiable, unknown }
