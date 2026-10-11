import 'dart:convert';

/// Dari 이력서 원본(canonical) 모델.
///
/// 사이트 중립 포맷으로 1회 저장 → 주입 시에만 사이트별 코드/필드로 매핑
/// (K-HIRE lasteducd/jobkind 등). 한 번 입력 → 전 사이트 재사용이 핵심 가치.
/// 코드값은 K-HIRE 코드표(assets/khire_resume)를 기준으로 보관한다.
const Object _unset = Object();

class Resume {
  final String? id; // Dari resumes.id (서버)
  final String site; // 대상 사이트 (현재 'khire')
  final String title; // 이력서 제목 (자동 생성 + 수정 가능)
  final String selfIntro; // 자기소개서 본문

  // 학력 (최종)
  final String? lastEduCd; // 최종학력 코드 (education.json cd)
  final String? eduStateCd; // 졸업상태 코드 (edu_state.json)
  final List<ResumeEdu> educations; // 상세학력(선택)

  // 경력 — K-HIRE 필수 섹션(신입/경력 탭). 'new'=신입, 'exp'=경력,
  // null=미선택(미완성). 경력이면 careers 최소 1건(2026-10-09).
  final String? careerType;
  final List<ResumeCareer> careers;

  // 희망 근무지 (복수)
  final List<ResumeArea> areas;

  // 희망 업직종 (복수)
  final List<ResumeJobKind> jobKinds;

  // 희망 근무조건
  final String? workPeriodCd;
  final String? workWeekCd;
  final List<String> employmentCds; // 고용형태 optioncd 복수
  final String? payCd;
  final int pay;

  // 한국어 능력
  final String? koreanLevelCd; // korean_level.json cd
  final int? topikLevel; // TOPIK 급수 1~6 (null=없음, 선택 입력 2026-10-11)

  // 선택 입력
  final List<ResumeLicense> licenses;
  final List<ResumeForeignLang> foreignLangs;
  final List<ResumeSkill> skills;
  final List<ResumeOa> oaList;

  // 자기소개서 만들기 칩 선택 상태(재편집 복원용). 조립 결과는 selfIntro.
  final Map<String, dynamic> selfChips;

  // K-HIRE 이력서 식별 (주입/업데이트용)
  final String? khireResumeId; // 생성 후 확보 → ModifyProc 대상

  // 동기화 A안(2026-10-09): Dari를 통해 K-HIRE에 최초 등록됐는지,
  // 등록 후 Dari에서 수정돼 사이트 반영 대기 중인지.
  final bool khireRegistered;
  final bool khireDirty;

  final String? updatedAt;

  const Resume({
    this.id,
    this.site = 'khire',
    this.title = '',
    this.selfIntro = '',
    this.lastEduCd,
    this.eduStateCd,
    this.educations = const [],
    this.careerType,
    this.careers = const [],
    this.selfChips = const {},
    this.khireRegistered = false,
    this.khireDirty = false,
    this.areas = const [],
    this.jobKinds = const [],
    this.workPeriodCd,
    this.workWeekCd,
    this.employmentCds = const [],
    this.payCd,
    this.pay = 0,
    this.koreanLevelCd,
    this.topikLevel,
    this.licenses = const [],
    this.foreignLangs = const [],
    this.skills = const [],
    this.oaList = const [],
    this.khireResumeId,
    this.updatedAt,
  });

  /// 필수 항목이 채워졌는지(온라인 지원 가능 여부).
  // K-HIRE 희망 근무조건은 기간·요일·형태 3종 필수 세트(실물 폼 확인,
  // 2026-10-09) — 요일·고용형태도 필수.
  bool get isComplete =>
      title.trim().isNotEmpty &&
      selfIntro.trim().isNotEmpty &&
      lastEduCd != null &&
      // 경력: 신입/경력 명시 선택 필수, 경력이면 최소 1건.
      (careerType == 'new' ||
          (careerType == 'exp' && careers.isNotEmpty)) &&
      areas.isNotEmpty &&
      jobKinds.isNotEmpty &&
      workPeriodCd != null &&
      workWeekCd != null &&
      employmentCds.isNotEmpty &&
      koreanLevelCd != null;

  Resume copyWith({
    String? id,
    String? site,
    String? title,
    String? selfIntro,
    String? lastEduCd,
    String? eduStateCd,
    List<ResumeEdu>? educations,
    String? careerType,
    List<ResumeCareer>? careers,
    Map<String, dynamic>? selfChips,
    bool? khireRegistered,
    bool? khireDirty,
    List<ResumeArea>? areas,
    List<ResumeJobKind>? jobKinds,
    String? workPeriodCd,
    String? workWeekCd,
    List<String>? employmentCds,
    String? payCd,
    int? pay,
    String? koreanLevelCd,
    Object? topikLevel = _unset, // null로 지우기 허용(선택 입력)
    List<ResumeLicense>? licenses,
    List<ResumeForeignLang>? foreignLangs,
    List<ResumeSkill>? skills,
    List<ResumeOa>? oaList,
    String? khireResumeId,
    String? updatedAt,
  }) {
    return Resume(
      id: id ?? this.id,
      site: site ?? this.site,
      title: title ?? this.title,
      selfIntro: selfIntro ?? this.selfIntro,
      lastEduCd: lastEduCd ?? this.lastEduCd,
      eduStateCd: eduStateCd ?? this.eduStateCd,
      educations: educations ?? this.educations,
      careerType: careerType ?? this.careerType,
      careers: careers ?? this.careers,
      selfChips: selfChips ?? this.selfChips,
      khireRegistered: khireRegistered ?? this.khireRegistered,
      khireDirty: khireDirty ?? this.khireDirty,
      areas: areas ?? this.areas,
      jobKinds: jobKinds ?? this.jobKinds,
      workPeriodCd: workPeriodCd ?? this.workPeriodCd,
      workWeekCd: workWeekCd ?? this.workWeekCd,
      employmentCds: employmentCds ?? this.employmentCds,
      payCd: payCd ?? this.payCd,
      pay: pay ?? this.pay,
      koreanLevelCd: koreanLevelCd ?? this.koreanLevelCd,
      topikLevel:
          identical(topikLevel, _unset) ? this.topikLevel : topikLevel as int?,
      licenses: licenses ?? this.licenses,
      foreignLangs: foreignLangs ?? this.foreignLangs,
      skills: skills ?? this.skills,
      oaList: oaList ?? this.oaList,
      khireResumeId: khireResumeId ?? this.khireResumeId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Supabase resumes.data(jsonb) 직렬화 (canonical).
  Map<String, dynamic> toData() => {
        'title': title,
        'self_intro': selfIntro,
        'last_edu_cd': lastEduCd,
        'edu_state_cd': eduStateCd,
        'educations': educations.map((e) => e.toJson()).toList(),
        'career_type': careerType,
        'careers': careers.map((e) => e.toJson()).toList(),
        'self_chips': selfChips,
        'khire_registered': khireRegistered,
        'khire_dirty': khireDirty,
        'areas': areas.map((e) => e.toJson()).toList(),
        'job_kinds': jobKinds.map((e) => e.toJson()).toList(),
        'work_period_cd': workPeriodCd,
        'work_week_cd': workWeekCd,
        'employment_cds': employmentCds,
        'pay_cd': payCd,
        'pay': pay,
        'korean_level_cd': koreanLevelCd,
        'topik_level': topikLevel,
        'licenses': licenses.map((e) => e.toJson()).toList(),
        'foreign_langs': foreignLangs.map((e) => e.toJson()).toList(),
        'skills': skills.map((e) => e.toJson()).toList(),
        'oa_list': oaList.map((e) => e.toJson()).toList(),
        'khire_resume_id': khireResumeId,
      };

  factory Resume.fromRow(Map<String, dynamic> row) {
    final data = _asMap(row['data']);
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((data[key] as List?) ?? const [])
            .map((e) => f(_asMap(e)))
            .toList();
    return Resume(
      id: row['id'] as String?,
      site: row['site'] as String? ?? 'khire',
      title: data['title'] as String? ?? '',
      selfIntro: data['self_intro'] as String? ?? '',
      lastEduCd: data['last_edu_cd'] as String?,
      eduStateCd: data['edu_state_cd'] as String?,
      educations: parse('educations', ResumeEdu.fromJson),
      careerType: data['career_type'] as String?,
      careers: parse('careers', ResumeCareer.fromJson),
      selfChips: _asMap(data['self_chips'] ?? const {}),
      khireRegistered: data['khire_registered'] as bool? ?? false,
      khireDirty: data['khire_dirty'] as bool? ?? false,
      areas: parse('areas', ResumeArea.fromJson),
      jobKinds: parse('job_kinds', ResumeJobKind.fromJson),
      workPeriodCd: data['work_period_cd'] as String?,
      workWeekCd: data['work_week_cd'] as String?,
      employmentCds:
          ((data['employment_cds'] as List?) ?? const []).map((e) => '$e').toList(),
      payCd: data['pay_cd'] as String?,
      pay: (data['pay'] as num?)?.toInt() ?? 0,
      koreanLevelCd: data['korean_level_cd'] as String?,
      topikLevel: (data['topik_level'] as num?)?.toInt(),
      licenses: parse('licenses', ResumeLicense.fromJson),
      foreignLangs: parse('foreign_langs', ResumeForeignLang.fromJson),
      skills: parse('skills', ResumeSkill.fromJson),
      oaList: parse('oa_list', ResumeOa.fromJson),
      khireResumeId: data['khire_resume_id'] as String?,
      updatedAt: row['updated_at'] as String?,
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is String && v.isNotEmpty) {
      final decoded = jsonDecode(v);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return <String, dynamic>{};
  }
}

/// 상세 학력 (선택).
class ResumeEdu {
  final String? eduCd; // 20104 등
  final String major;
  final String enterYear;
  final String graduateYear;
  final String schoolName;
  const ResumeEdu({
    this.eduCd,
    this.major = '',
    this.enterYear = '',
    this.graduateYear = '',
    this.schoolName = '',
  });
  Map<String, dynamic> toJson() => {
        'edu_cd': eduCd,
        'major': major,
        'enter_year': enterYear,
        'graduate_year': graduateYear,
        'school_name': schoolName,
      };
  factory ResumeEdu.fromJson(Map<String, dynamic> j) => ResumeEdu(
        eduCd: j['edu_cd']?.toString(),
        major: j['major'] as String? ?? '',
        enterYear: j['enter_year'] as String? ?? '',
        graduateYear: j['graduate_year'] as String? ?? '',
        schoolName: j['school_name'] as String? ?? '',
      );
}

/// 경력 1건 — 회사명(유일한 키패드 입력) + 기간(년월)·재직중 +
/// "지원 분야와 유사 업무" 체크(JK_CAREERYN 매핑, 2026-10-09).
class ResumeCareer {
  final String company;
  final String startYm; // YYYYMM
  final String endYm; // 재직중이면 ''
  final bool inWork; // 재직중
  final bool similar; // 지원(희망) 분야와 유사한 업무였는지

  const ResumeCareer({
    this.company = '',
    this.startYm = '',
    this.endYm = '',
    this.inWork = false,
    this.similar = false,
  });

  /// 근무 개월 수 (총 경력 합산·자소서 문장용). 재직중이면 now까지.
  int months(DateTime now) {
    if (startYm.length != 6) return 0;
    final sy = int.tryParse(startYm.substring(0, 4)) ?? 0;
    final sm = int.tryParse(startYm.substring(4)) ?? 0;
    int ey, em;
    if (inWork || endYm.length != 6) {
      ey = now.year;
      em = now.month;
    } else {
      ey = int.tryParse(endYm.substring(0, 4)) ?? sy;
      em = int.tryParse(endYm.substring(4)) ?? sm;
    }
    final m = (ey - sy) * 12 + (em - sm) + 1; // 같은 달 = 1개월
    return m < 0 ? 0 : m;
  }

  Map<String, dynamic> toJson() => {
        'company': company,
        'start_ym': startYm,
        'end_ym': endYm,
        'in_work': inWork,
        'similar': similar,
      };
  factory ResumeCareer.fromJson(Map<String, dynamic> j) => ResumeCareer(
        company: j['company'] as String? ?? '',
        startYm: j['start_ym'] as String? ?? '',
        endYm: j['end_ym'] as String? ?? '',
        inWork: j['in_work'] as bool? ?? false,
        similar: j['similar'] as bool? ?? false,
      );
}

/// 희망 근무지.
class ResumeArea {
  final String areaCd; // 042
  final String areaNm;
  final int localCd; // 1511
  final String localNm;
  const ResumeArea(this.areaCd, this.areaNm, this.localCd, this.localNm);
  Map<String, dynamic> toJson() => {
        'area_cd': areaCd,
        'area_nm': areaNm,
        'local_cd': localCd,
        'local_nm': localNm,
      };
  factory ResumeArea.fromJson(Map<String, dynamic> j) => ResumeArea(
        j['area_cd'] as String? ?? '',
        j['area_nm'] as String? ?? '',
        (j['local_cd'] as num?)?.toInt() ?? 0,
        j['local_nm'] as String? ?? '',
      );
}

/// 희망 업직종.
class ResumeJobKind {
  final String jk1Cd;
  final String jk1Nm;
  final String jk2Cd;
  final String jk2Nm;
  final bool careerYn;
  const ResumeJobKind(
      this.jk1Cd, this.jk1Nm, this.jk2Cd, this.jk2Nm, this.careerYn);
  Map<String, dynamic> toJson() => {
        'jk1_cd': jk1Cd,
        'jk1_nm': jk1Nm,
        'jk2_cd': jk2Cd,
        'jk2_nm': jk2Nm,
        'career_yn': careerYn,
      };
  factory ResumeJobKind.fromJson(Map<String, dynamic> j) => ResumeJobKind(
        j['jk1_cd'] as String? ?? '',
        j['jk1_nm'] as String? ?? '',
        j['jk2_cd'] as String? ?? '',
        j['jk2_nm'] as String? ?? '',
        j['career_yn'] as bool? ?? false,
      );
}

/// 자격증 (선택).
class ResumeLicense {
  final String name;
  final String organ;
  final String year;
  const ResumeLicense({this.name = '', this.organ = '', this.year = ''});
  Map<String, dynamic> toJson() =>
      {'name': name, 'organ': organ, 'year': year};
  factory ResumeLicense.fromJson(Map<String, dynamic> j) => ResumeLicense(
        name: j['name'] as String? ?? '',
        organ: j['organ'] as String? ?? '',
        year: j['year'] as String? ?? '',
      );
}

/// 외국어 (선택).
class ResumeForeignLang {
  final String groupCd; // 언어 코드
  final String groupNm;
  final String gradeCd; // 능력 코드
  const ResumeForeignLang(
      {this.groupCd = '', this.groupNm = '', this.gradeCd = ''});
  Map<String, dynamic> toJson() =>
      {'group_cd': groupCd, 'group_nm': groupNm, 'grade_cd': gradeCd};
  factory ResumeForeignLang.fromJson(Map<String, dynamic> j) =>
      ResumeForeignLang(
        groupCd: j['group_cd'] as String? ?? '',
        groupNm: j['group_nm'] as String? ?? '',
        gradeCd: j['grade_cd'] as String? ?? '',
      );
}

/// 보유 스킬 (선택).
class ResumeSkill {
  final int code;
  final String name;
  const ResumeSkill(this.code, this.name);
  Map<String, dynamic> toJson() => {'code': code, 'name': name};
  factory ResumeSkill.fromJson(Map<String, dynamic> j) => ResumeSkill(
        (j['code'] as num?)?.toInt() ?? 0,
        j['name'] as String? ?? '',
      );
}

/// OA 능력 (선택).
class ResumeOa {
  final String oaCd;
  final String oaNm;
  final String gradeCd;
  const ResumeOa({this.oaCd = '', this.oaNm = '', this.gradeCd = ''});
  Map<String, dynamic> toJson() =>
      {'oa_cd': oaCd, 'oa_nm': oaNm, 'grade_cd': gradeCd};
  factory ResumeOa.fromJson(Map<String, dynamic> j) => ResumeOa(
        oaCd: j['oa_cd'] as String? ?? '',
        oaNm: j['oa_nm'] as String? ?? '',
        gradeCd: j['grade_cd'] as String? ?? '',
      );
}
