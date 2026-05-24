class FilterOption {
  final String id;
  final String label;

  const FilterOption({required this.id, required this.label});
}

class FilterState {
  final Set<String> visaIds;
  final Set<String> categoryIds;
  final Set<int> regionIds;
  final String? salaryRange;
  final Set<String> employmentTypeIds;
  final Set<String> benefitIds;
  final Set<int> koreanLevelIds;
  final Set<int> workScheduleIds;
  final Set<int> languageIds;
  final bool? visaSponsorship;
  final String? gender;          // 'male', 'female', 'any'
  final Set<String> salaryTypes; // 'hourly', 'daily', 'monthly', 'annual'
  final Set<String> educations;  // DB 값 그대로
  final Set<String> experiences; // DB 값 그대로
  final Set<String> siteIds;     // sites 테이블 ID
  final Set<String> countryIds;  // countries 테이블 ID

  const FilterState({
    this.visaIds = const {},
    this.categoryIds = const {},
    this.regionIds = const {},
    this.salaryRange,
    this.employmentTypeIds = const {},
    this.benefitIds = const {},
    this.koreanLevelIds = const {},
    this.workScheduleIds = const {},
    this.languageIds = const {},
    this.visaSponsorship,
    this.gender,
    this.salaryTypes = const {},
    this.educations = const {},
    this.experiences = const {},
    this.siteIds = const {},
    this.countryIds = const {},
  });

  bool get isEmpty =>
      visaIds.isEmpty &&
      categoryIds.isEmpty &&
      regionIds.isEmpty &&
      (salaryRange == null || salaryRange!.isEmpty) &&
      employmentTypeIds.isEmpty &&
      benefitIds.isEmpty &&
      koreanLevelIds.isEmpty &&
      workScheduleIds.isEmpty &&
      languageIds.isEmpty &&
      visaSponsorship == null &&
      gender == null &&
      salaryTypes.isEmpty &&
      educations.isEmpty &&
      experiences.isEmpty &&
      siteIds.isEmpty &&
      countryIds.isEmpty;

  int get activeCount =>
      visaIds.length +
      categoryIds.length +
      regionIds.length +
      (salaryRange != null && salaryRange!.isNotEmpty ? 1 : 0) +
      employmentTypeIds.length +
      benefitIds.length +
      koreanLevelIds.length +
      workScheduleIds.length +
      languageIds.length +
      (visaSponsorship != null ? 1 : 0) +
      (gender != null ? 1 : 0) +
      salaryTypes.length +
      educations.length +
      experiences.length +
      siteIds.length +
      countryIds.length;

  FilterState copyWith({
    Set<String>? visaIds,
    Set<String>? categoryIds,
    Set<int>? regionIds,
    String? salaryRange,
    Set<String>? employmentTypeIds,
    Set<String>? benefitIds,
    Set<int>? koreanLevelIds,
    Set<int>? workScheduleIds,
    Set<int>? languageIds,
    bool? visaSponsorship,
    bool clearVisaSponsorship = false,
    String? gender,
    bool clearGender = false,
    Set<String>? salaryTypes,
    Set<String>? educations,
    Set<String>? experiences,
    Set<String>? siteIds,
    Set<String>? countryIds,
  }) {
    return FilterState(
      visaIds: visaIds ?? this.visaIds,
      categoryIds: categoryIds ?? this.categoryIds,
      regionIds: regionIds ?? this.regionIds,
      salaryRange: salaryRange ?? this.salaryRange,
      employmentTypeIds: employmentTypeIds ?? this.employmentTypeIds,
      benefitIds: benefitIds ?? this.benefitIds,
      koreanLevelIds: koreanLevelIds ?? this.koreanLevelIds,
      workScheduleIds: workScheduleIds ?? this.workScheduleIds,
      languageIds: languageIds ?? this.languageIds,
      visaSponsorship: clearVisaSponsorship ? null : (visaSponsorship ?? this.visaSponsorship),
      gender: clearGender ? null : (gender ?? this.gender),
      salaryTypes: salaryTypes ?? this.salaryTypes,
      educations: educations ?? this.educations,
      experiences: experiences ?? this.experiences,
      siteIds: siteIds ?? this.siteIds,
      countryIds: countryIds ?? this.countryIds,
    );
  }

  FilterState clearSalary() => copyWith(salaryRange: '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterState &&
          _setEq(visaIds, other.visaIds) &&
          _setEq(categoryIds, other.categoryIds) &&
          _setEq(regionIds, other.regionIds) &&
          salaryRange == other.salaryRange &&
          _setEq(employmentTypeIds, other.employmentTypeIds) &&
          _setEq(benefitIds, other.benefitIds) &&
          _setEq(koreanLevelIds, other.koreanLevelIds) &&
          _setEq(workScheduleIds, other.workScheduleIds) &&
          _setEq(languageIds, other.languageIds) &&
          visaSponsorship == other.visaSponsorship &&
          gender == other.gender &&
          _setEq(salaryTypes, other.salaryTypes) &&
          _setEq(educations, other.educations) &&
          _setEq(experiences, other.experiences) &&
          _setEq(siteIds, other.siteIds) &&
          _setEq(countryIds, other.countryIds);

  @override
  int get hashCode => Object.hash(
      visaIds.length, categoryIds.length, regionIds.length,
      salaryRange, employmentTypeIds.length, benefitIds.length,
      koreanLevelIds.length, workScheduleIds.length, languageIds.length,
      gender, visaSponsorship, salaryTypes.length,
      educations.length, experiences.length,
      siteIds.length, countryIds.length);

  static bool _setEq<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  static const FilterState empty = FilterState();

  /// SharedPreferences 저장용 JSON
  Map<String, dynamic> toJson() => {
    'visaIds': visaIds.toList(),
    'categoryIds': categoryIds.toList(),
    'regionIds': regionIds.toList(),
    'salaryRange': salaryRange,
    'employmentTypeIds': employmentTypeIds.toList(),
    'benefitIds': benefitIds.toList(),
    'koreanLevelIds': koreanLevelIds.toList(),
    'workScheduleIds': workScheduleIds.toList(),
    'languageIds': languageIds.toList(),
    'visaSponsorship': visaSponsorship,
    'gender': gender,
    'salaryTypes': salaryTypes.toList(),
    'educations': educations.toList(),
    'experiences': experiences.toList(),
    'siteIds': siteIds.toList(),
    'countryIds': countryIds.toList(),
  };

  factory FilterState.fromJson(Map<String, dynamic> json) => FilterState(
    visaIds: (json['visaIds'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    categoryIds: (json['categoryIds'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    regionIds: (json['regionIds'] as List?)?.map((e) => e is num ? e.toInt() : int.tryParse(e.toString()) ?? 0).where((e) => e != 0).toSet() ?? {},
    salaryRange: json['salaryRange'] as String?,
    employmentTypeIds: (json['employmentTypeIds'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    benefitIds: (json['benefitIds'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    koreanLevelIds: (json['koreanLevelIds'] as List?)?.map((e) => e is num ? e.toInt() : int.tryParse(e.toString()) ?? 0).where((e) => e != 0).toSet() ?? {},
    workScheduleIds: (json['workScheduleIds'] as List?)?.map((e) => e is num ? e.toInt() : int.tryParse(e.toString()) ?? 0).where((e) => e != 0).toSet() ?? {},
    languageIds: (json['languageIds'] as List?)?.map((e) => e is num ? e.toInt() : int.tryParse(e.toString()) ?? 0).where((e) => e != 0).toSet() ?? {},
    visaSponsorship: json['visaSponsorship'] as bool?,
    gender: json['gender'] as String?,
    salaryTypes: (json['salaryTypes'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    educations: (json['educations'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    experiences: (json['experiences'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    siteIds: (json['siteIds'] as List?)?.map((e) => e.toString()).toSet() ?? {},
    countryIds: (json['countryIds'] as List?)?.map((e) => e.toString()).toSet() ?? {},
  );
}

/// RPC get_filter_counts 응답 모델
class FilterCounts {
  final Map<String, int> visa;
  final Map<String, int> category;
  final Map<String, int> region;
  final Map<String, int> employmentType;
  final Map<String, int> benefit;
  final Map<String, int> koreanLevel;
  final Map<String, int> workSchedule;
  final Map<String, int> language;
  final int visaSponsorship;
  final Map<String, int> gender;
  final Map<String, int> salaryType;
  final Map<String, int> education;
  final Map<String, int> experience;

  const FilterCounts({
    this.visa = const {},
    this.category = const {},
    this.region = const {},
    this.employmentType = const {},
    this.benefit = const {},
    this.koreanLevel = const {},
    this.workSchedule = const {},
    this.language = const {},
    this.visaSponsorship = 0,
    this.gender = const {},
    this.salaryType = const {},
    this.education = const {},
    this.experience = const {},
  });

  factory FilterCounts.fromJson(Map<String, dynamic> json) {
    return FilterCounts(
      visa: _parseMap(json['visa']),
      category: _parseMap(json['category']),
      region: _parseMap(json['region']),
      employmentType: _parseMap(json['employment_type']),
      benefit: _parseMap(json['benefit']),
      koreanLevel: _parseMap(json['korean_level']),
      workSchedule: _parseMap(json['work_schedule']),
      language: _parseMap(json['language']),
      visaSponsorship: (json['visa_sponsorship'] as num?)?.toInt() ?? 0,
      gender: _parseMap(json['gender']),
      salaryType: _parseMap(json['salary_type']),
      education: _parseMap(json['education']),
      experience: _parseMap(json['experience']),
    );
  }

  static Map<String, int> _parseMap(dynamic data) {
    if (data == null || data is! Map) return {};
    return data.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
  }

  /// 특정 카테고리의 ID별 건수 조회
  int getCount(String category, String id) {
    switch (category) {
      case 'visa': return visa[id] ?? 0;
      case 'category': return this.category[id] ?? 0;
      case 'region': return region[id] ?? 0;
      case 'employment_type': return employmentType[id] ?? 0;
      case 'benefit': return benefit[id] ?? 0;
      case 'korean_level': return koreanLevel[id] ?? 0;
      case 'work_schedule': return workSchedule[id] ?? 0;
      case 'language': return language[id] ?? 0;
      default: return 0;
    }
  }
}
