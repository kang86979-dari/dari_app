import 'dart:convert';

import '../../../data/models/resume.dart';
import '../../../data/services/khire_resume_codes.dart';

/// canonical Resume → K-HIRE localStorage RESUME_*_JSON 매핑.
///
/// K-HIRE 이력서 폼(Regist.asp)은 init에서 섹션별 localStorage JSON을 읽어
/// 템플릿 렌더 → 각 키를 넣으면 팝업/버튼 조작 없이 전 섹션이 채워진다
/// (2026-10-05 실캡처: scratchpad/dari_docs/resume_localstorage_capture.json).
///
/// ⚠️ RESUME_MAIN_JSON의 hashdata(서버토큰)는 라이브 페이지 값을 유지해야 함 —
/// 여기서는 내용만 만들고, 주입 JS가 기존 hashdata를 읽어 머지한다.
class KhireResumeInjector {
  KhireResumeInjector._();

  /// 주입 JS 생성. Regist.asp 도달 후 evaluateJavascript로 실행.
  /// 1) 기존 RESUME_MAIN_JSON에서 hashdata/regtype 보존 → 머지 set
  /// 2) 섹션 키 set → 3) location.reload()로 폼 재구성.
  ///
  /// [birthYm] YYYYMM — CAREER_JSON parambirthdt(실캡처 "198202").
  /// 호출 전 KhireResumeCodes.ensureLoaded() 필요(근무조건 이름 조회).
  static String buildInjectionJs(Resume r, {String birthYm = ''}) {
    final sections = _sectionJsons(r, birthYm: birthYm);
    final mainPatch = jsonEncode({
      'title': r.title,
      'resumeopenyn': 'Y',
      'formtype': 'NORMAL',
    });
    final setters = sections.entries
        .map((e) =>
            'localStorage.setItem(${jsonEncode(e.key)}, ${jsonEncode(e.value)});')
        .join('\n    ');
    return '''
(function(){
  try {
    // 1) MAIN — hashdata(서버토큰)·regtype·adid는 라이브 값 보존, 내용만 머지.
    var main = {};
    try { main = JSON.parse(localStorage.getItem('RESUME_MAIN_JSON') || '{}'); } catch(e) {}
    var patch = $mainPatch;
    for (var k in patch) { main[k] = patch[k]; }
    localStorage.setItem('RESUME_MAIN_JSON', JSON.stringify(main));
    // 2) 섹션 키
    $setters
    // 3) 폼 재구성 — 페이지 init이 localStorage를 다시 읽게 리로드.
    if (!window.__dariResumeInjected) {
      window.__dariResumeInjected = true;
      sessionStorage.setItem('DARI_RESUME_INJECTED', '1');
      location.reload();
      return 'reloading';
    }
    return 'done';
  } catch(e) { return 'error: ' + e; }
})();
''';
  }

  /// 리로드 후 중복 주입 방지 체크 JS (true면 이미 주입됨).
  static const String checkInjectedJs = '''
(function(){ return sessionStorage.getItem('DARI_RESUME_INJECTED') === '1'; })();
''';

  static String _nmOf(List<CodeItem> items, String? cd) {
    if (cd == null) return '';
    for (final c in items) {
      if (c.cd == cd) return c.nm;
    }
    return '';
  }

  /// 섹션별 localStorage JSON 문자열 (실캡처 스키마 준수).
  static Map<String, String> _sectionJsons(Resume r, {String birthYm = ''}) {
    final codes = KhireResumeCodes.instance;
    final map = <String, String>{};

    // 자기소개서 — contents 본문.
    map['RESUME_SELF_JSON'] = jsonEncode({
      'result': true,
      'contents': r.selfIntro,
      'list': const [],
      'errormsg': '',
    });

    // 학력 — lasteducd/lastedustatecd (+상세 리스트는 선택).
    map['RESUME_EDU_JSON'] = jsonEncode({
      'result': true,
      'list': r.educations
          .map((e) => {
                'educd': int.tryParse(e.eduCd ?? '') ?? 0,
                'edunm': '',
                'major': e.major,
                'enteryyyy': e.enterYear,
                'graduateyyyy': e.graduateYear,
                'schoolcd': '99999',
                'schoolnm': e.schoolName,
              })
          .toList(),
      'totalcnt': r.educations.length,
      'lasteducd': r.lastEduCd ?? '',
      'lastedustatecd': r.eduStateCd ?? '',
      // 페이지 기본 eduJson에 있는 키 — 비우면 기본값과 동일(덤프 확인).
      'selectcd': '',
      'selectnm': '',
      'selectgroupno': '',
      'errormsg': '',
    });

    // 경력 — careerType 'exp'면 리스트+총합산, 아니면 신입(00).
    // item 키는 목록 템플릿 확정분(comnm/join·retire/inworkyn)만 전송,
    // careercd 등 서버 발번 필드는 비움(실캡처 재확인 대상, 2026-10-09).
    // parambirthdt(YYYYMM)는 실캡처에 존재.
    final now = DateTime.now();
    final careers =
        r.careerType == 'exp' ? r.careers : const <ResumeCareer>[];
    final totalMonths =
        careers.fold<int>(0, (sum, c) => sum + c.months(now));
    String p2(int v) => v.toString().padLeft(2, '0');
    map['RESUME_CAREER_JSON'] = jsonEncode({
      'result': true,
      'totalcareeryy': p2(totalMonths ~/ 12),
      'totalcareermm': p2(totalMonths % 12),
      'totalcareerdd': '00',
      'list': careers
          .asMap()
          .entries
          .map((e) => {
                'careercd': '',
                'comnm': e.value.company,
                'joinyyyy': e.value.startYm.length == 6
                    ? e.value.startYm.substring(0, 4)
                    : '',
                'joinmm': e.value.startYm.length == 6
                    ? e.value.startYm.substring(4)
                    : '',
                'retireyyyy': e.value.inWork || e.value.endYm.length != 6
                    ? ''
                    : e.value.endYm.substring(0, 4),
                'retiremm': e.value.inWork || e.value.endYm.length != 6
                    ? ''
                    : e.value.endYm.substring(4),
                'inworkyn': e.value.inWork ? 'Y' : 'N',
                'lessjoinyyyy': '',
                'lessjoinmm': '',
                'workday': '',
              })
          .toList(),
      'errormsg': '',
      if (birthYm.isNotEmpty) 'parambirthdt': birthYm,
    });

    // 희망 근무지.
    map['RESUME_AREA_JSON'] = jsonEncode({
      'result': true,
      'list': r.areas
          .map((a) => {
                'AREACD': a.areaCd,
                'AREANM': a.areaNm,
                'LOCALCD': a.localCd,
                'LOCALNM': a.localNm,
              })
          .toList(),
      'errormsg': '',
    });

    // 희망 업직종 — 경력여부는 "지원 분야와 유사 업무" 체크된 경력이
    // 있으면 Y(2026-10-09).
    final jkCareerYn = r.careerType == 'exp' && r.careers.any((c) => c.similar)
        ? 'Y'
        : 'N';
    map['RESUME_JOBKIND_JSON'] = jsonEncode({
      'result': true,
      'cnt': r.jobKinds.length,
      'list': r.jobKinds
          .map((j) => {
                'JK1CD': j.jk1Cd,
                'JK1NM': j.jk1Nm,
                'JK2CD': j.jk2Cd,
                'JK2NM': j.jk2Nm,
                'JK_CAREERYN': jkCareerYn,
              })
          .toList(),
      'errormsg': '',
    });

    // 희망 근무조건 — *nm은 페이지 템플릿이 그대로 렌더하므로 코드표
    // 한국어명 필수. 'free'/'all'은 Dari 자체 코드(K-HIRE 실코드는
    // 30100~30103): free→freelanceryn, all→4종 전체(2026-10-09).
    const realEmploymentCds = ['30100', '30101', '30102', '30103'];
    final employment = <String>[];
    var freelancer = false;
    for (final cd in r.employmentCds) {
      if (cd == 'free') {
        freelancer = true;
      } else if (cd == 'all') {
        employment.addAll(realEmploymentCds.where((c) => !employment.contains(c)));
      } else if (!employment.contains(cd)) {
        employment.add(cd);
      }
    }
    final empItems = codes.workEmployment();
    map['RESUME_WORK_JSON'] = jsonEncode({
      'result': true,
      'workperiodcd': r.workPeriodCd ?? '',
      'workperiodnm': _nmOf(codes.workPeriod(), r.workPeriodCd),
      'workweekcd': r.workWeekCd ?? '',
      'workweeknm': _nmOf(codes.workWeek(), r.workWeekCd),
      'freelanceryn': freelancer ? 'Y' : 'N',
      'homeworkyn': 'N',
      'paycd': r.payCd ?? '0',
      'pay': r.pay,
      'minpay': '',
      'list': employment
          .map((cd) =>
              {'groupcd': 30, 'optioncd': cd, 'optionnm': _nmOf(empItems, cd)})
          .toList(),
      'errormsg': '',
    });

    // 자격증 (선택) — licensecd 99999 = 직접입력.
    if (r.licenses.isNotEmpty) {
      map['RESUME_LICENSE_JSON'] = jsonEncode({
        'result': true,
        'licensetext': '',
        'list': r.licenses
            .asMap()
            .entries
            .map((e) => {
                  'intnum': e.key + 1,
                  'certificateyyyy': e.value.year,
                  'licensecd': '99999',
                  'licensenm': e.value.name,
                  'organ': e.value.organ,
                })
            .toList(),
        'errormsg': '',
      });
    }

    // 한국어능력 — TEMPSAVE에 저장(실캡처 확인). datetime은 실캡처 포맷
    // '2026.10.05 18:19:24' 준수(복원 배너가 표시할 수 있음).
    map['RESUME_TEMPSAVE_JSON'] = jsonEncode({
      'tempsaveyn': 'Y',
      'datetime': '${now.year}.${p2(now.month)}.${p2(now.day)} '
          '${p2(now.hour)}:${p2(now.minute)}:${p2(now.second)}',
      'title': r.title,
      'koreanlevel': r.koreanLevelCd ?? '',
    });

    return map;
  }
}
