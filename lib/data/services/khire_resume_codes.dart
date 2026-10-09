import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// 코드-이름 한 쌍 (K-HIRE 이력서 옵션).
class CodeItem {
  final String cd;
  final String nm;
  final String? title; // 한국어능력 설명 등 부가
  const CodeItem(this.cd, this.nm, {this.title});
  factory CodeItem.fromJson(Map<String, dynamic> j) =>
      CodeItem(j['cd'] as String? ?? '', j['nm'] as String? ?? '',
          title: j['title'] as String?);
}

/// K-HIRE 희망 근무지 지역(시도/시군구).
class AreaItem {
  final String areaCd; // AREACD (시도, 예 042)
  final String areaNm; // AREANM (대전)
  final int localCd; // LOCALCD (시군구, 예 1511)
  final String localNm; // LOCALNM (동구)
  final int step; // 1=시도
  const AreaItem(this.areaCd, this.areaNm, this.localCd, this.localNm, this.step);
  factory AreaItem.fromJson(Map<String, dynamic> j) => AreaItem(
        j['AREACD'] as String? ?? '',
        j['AREANM'] as String? ?? '',
        (j['LOCALCD'] as num?)?.toInt() ?? 0,
        j['LOCALNM'] as String? ?? '',
        (j['STEP'] as num?)?.toInt() ?? 0,
      );
  bool get isSido => step == 1;
}

/// K-HIRE 이력서 코드표(에셋 번들, assets/khire_resume/*.json) 로더.
/// 소스: ResumeOptJson.js / AreaCodeJson.asp / JkCodeJson.asp /
/// RegistWorkCondition.asp (2026-10-05 추출). 코드 매핑·선택 UI에서 사용.
class KhireResumeCodes {
  KhireResumeCodes._();
  static final KhireResumeCodes instance = KhireResumeCodes._();

  List<CodeItem>? _education; // 최종학력
  List<CodeItem>? _koreanLevel; // 한국어능력
  List<CodeItem>? _employment; // 고용형태(경력 WORKSTATECD)
  Map<String, List<CodeItem>>? _eduState; // 학력별 졸업상태
  List<AreaItem>? _areas; // 희망 근무지
  List<CodeItem>? _jobkind1; // 업직종 대분류
  Map<String, List<CodeItem>>? _jobkind2; // 대분류별 중분류
  Map<String, List<CodeItem>>? _work; // 근무조건(period/week/employment/pay)

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    Future<dynamic> j(String f) async =>
        jsonDecode(await rootBundle.loadString('assets/khire_resume/$f'));
    List<CodeItem> list(dynamic a) =>
        (a as List).map((e) => CodeItem.fromJson(e as Map<String, dynamic>)).toList();

    _education = list(await j('education.json'));
    _koreanLevel = list(await j('korean_level.json'));
    _employment = list(await j('employment_type.json'));
    final es = await j('edu_state.json') as Map<String, dynamic>;
    _eduState = es.map((k, v) => MapEntry(k, list(v)));
    _areas = (await j('areas.json') as List)
        .map((e) => AreaItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final jk = await j('jobkind.json') as Map<String, dynamic>;
    _jobkind1 = list(jk['j1']);
    _jobkind2 = (jk['j2'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, list(v)));
    final w = await j('work_condition.json') as Map<String, dynamic>;
    _work = w.map((k, v) => MapEntry(k, list(v)));
    _loaded = true;
  }

  // 접근자 (ensureLoaded 이후).
  List<CodeItem> get education => _education ?? const [];
  List<CodeItem> get koreanLevel => _koreanLevel ?? const [];
  List<CodeItem> get employment => _employment ?? const [];
  List<CodeItem> eduStateFor(String eduCd) => _eduState?[eduCd] ?? const [];
  List<AreaItem> get areas => _areas ?? const [];
  List<AreaItem> get sido => areas.where((a) => a.isSido).toList();
  List<AreaItem> localsOf(String areaCd) =>
      areas.where((a) => a.areaCd == areaCd && !a.isSido).toList();
  List<CodeItem> get jobkind1 => _jobkind1 ?? const [];
  List<CodeItem> jobkind2Of(String j1cd) => _jobkind2?[j1cd] ?? const [];
  List<CodeItem> workPeriod() => _work?['period'] ?? const [];
  List<CodeItem> workWeek() => _work?['week'] ?? const [];
  List<CodeItem> workEmployment() => _work?['employment'] ?? const [];
  List<CodeItem> workPay() => _work?['pay'] ?? const [];
}
