/// 문자 지원(K-HIRE TalkApply) 메시지 조립.
///
/// 칩 선택값 → K-HIRE 담당자에게 전송될 한국어 문장을 만든다.
/// 전송문은 한국어 고정(기업이 받는 글). 칩 라벨/화면 문구만 다국어 번역 대상.
/// 미선택 블록은 통째로 생략돼 문장이 자연스럽게 짧아진다.
///
/// 근무 요일은 월~일 개별 복수 선택, 시간대도 오전/오후/저녁/야간 복수 선택.
/// "화요일 빼고 다 가능" 같은 세밀한 조합을 요일 나열로 표현한다.
///
/// 순수 로직 — UI/프로바이더 의존 없음. 단위테스트로 커버.
library;

/// 한국어 수준
enum KoreanLevel { fluent, conversational, basic, learning }

/// 경력
enum ExperienceLevel { none, under1y, oneToThree, overThree }

/// 요일 (정렬·연속성 판정에 enum index 사용: 월=0 … 일=6)
enum Weekday { mon, tue, wed, thu, fri, sat, sun }

/// 시간대 (오전/오후/저녁/야간)
enum DayPart { morning, afternoon, evening, night }

/// 시작 가능일
enum StartDate { immediate, withinWeek, negotiable }

/// 학생 상태(선택 항목) — 재학 / 휴학
enum StudentStatus { enrolled, onLeave }

/// 한국 거주 기간(선택 항목)
enum KoreaStay { under1y, oneToThree, overThree }

/// 메시지 조립 입력값. 칩은 전부 미선택(빈 Set/null) = 생략.
class SmsMessageInput {
  final String nationalityLabel; // 예: 방글라데시
  final String visaCode; // 예: E-9
  final KoreanLevel? koreanLevel;
  final ExperienceLevel? experience;
  final StudentStatus? studentStatus; // 재학/휴학(선택 항목, null=해당 없음)
  final KoreaStay? koreaStay; // 한국 거주 기간(선택 항목)

  /// 근무 가능 요일(복수). [daysNegotiable]·[daysMatchPosting]이 true면 무시.
  final Set<Weekday> workDays;
  final bool daysNegotiable; // "요일 협의"
  final bool daysMatchPosting; // "공고에 맞춰 가능" — 요일 개별·협의와 배타(UI 보장)

  /// 근무 가능 시간대(복수). [timesNegotiable]·[timesMatchPosting]이 true면 무시.
  final Set<DayPart> workTimes;
  final bool timesNegotiable; // "시간 협의"
  final bool timesMatchPosting; // "공고에 맞춰 가능"

  final StartDate? startDate;

  const SmsMessageInput({
    required this.nationalityLabel,
    required this.visaCode,
    this.koreanLevel,
    this.experience,
    this.studentStatus,
    this.koreaStay,
    this.workDays = const {},
    this.daysNegotiable = false,
    this.daysMatchPosting = false,
    this.workTimes = const {},
    this.timesNegotiable = false,
    this.timesMatchPosting = false,
    this.startDate,
  });

  /// 국적·비자만 K-HIRE 계정 값으로 바꿔 복제 — 지원 시점에 K-HIRE를
  /// source of truth로 삼아 메시지를 재생성할 때 사용(2026-10-05).
  SmsMessageInput withNationalityVisa({
    required String nationalityLabel,
    required String visaCode,
  }) {
    return SmsMessageInput(
      nationalityLabel: nationalityLabel,
      visaCode: visaCode,
      koreanLevel: koreanLevel,
      experience: experience,
      studentStatus: studentStatus,
      koreaStay: koreaStay,
      workDays: workDays,
      daysNegotiable: daysNegotiable,
      daysMatchPosting: daysMatchPosting,
      workTimes: workTimes,
      timesNegotiable: timesNegotiable,
      timesMatchPosting: timesMatchPosting,
      startDate: startDate,
    );
  }
}

/// K-HIRE 메시지란(#comment) 최대 글자수 — 실물 확인 300자
/// (2026-10-04 talkapply.html: placeholder "최대 300자", limitTextNum 300).
const int kSmsMessageMaxLength = 300;

const _weekdayLabel = {
  Weekday.mon: '월',
  Weekday.tue: '화',
  Weekday.wed: '수',
  Weekday.thu: '목',
  Weekday.fri: '금',
  Weekday.sat: '토',
  Weekday.sun: '일',
};

const _dayPartLabel = {
  DayPart.morning: '오전',
  DayPart.afternoon: '오후',
  DayPart.evening: '저녁',
  DayPart.night: '야간',
};

const _weekdaysAll = {
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
  Weekday.sat,
  Weekday.sun,
};
const _weekdaysWeekday = {
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
};
const _weekdaysWeekend = {Weekday.sat, Weekday.sun};

/// 선택 종류: 구체값 있음 / 공고에 맞춤 / 협의 / 없음
enum _ClauseKind { specific, matchPosting, negotiable, none }

class SmsMessageBuilder {
  /// 칩 선택값으로 한국어 전송문을 조립한다.
  /// 관련 문장을 문단(자기소개 / 업무조건)으로 묶고, 문단 사이에만 줄바꿈 —
  /// 한 줄씩 끊기는 나열감을 줄여 편지처럼 읽히게 한다.
  static String build(SmsMessageInput input) {
    // 1문단: 자기소개 (국적·비자 → 거주 기간 → 학생 → 한국어)
    final intro = <String>[];
    if (input.nationalityLabel.isNotEmpty && input.visaCode.isNotEmpty) {
      intro.add(
        '저는 ${input.nationalityLabel}에서 왔고, ${input.visaCode} 비자를 가지고 있습니다.',
      );
    }
    final stay = _koreaStaySentence(input.koreaStay);
    if (stay != null) intro.add(stay);
    final student = _studentSentence(input.studentStatus);
    if (student != null) intro.add(student);
    final korean = _koreanSentence(input.koreanLevel);
    if (korean != null) intro.add(korean);

    // 2문단: 업무 조건 (경력 → 근무 가능 → 시작일)
    final work = <String>[];
    final exp = _experienceSentence(input.experience);
    if (exp != null) work.add(exp);
    final avail = _availabilitySentence(input);
    if (avail != null) work.add(avail);
    final start = _startSentence(input.startDate);
    if (start != null) work.add(start);

    final paragraphs = <String>['안녕하세요.'];
    if (intro.isNotEmpty) paragraphs.add(intro.join(' '));
    if (work.isNotEmpty) paragraphs.add(work.join(' '));
    paragraphs.add('기회를 주시면 열심히 일하겠습니다. 감사합니다.');

    final msg = paragraphs.join('\n');
    assert(
      msg.length <= kSmsMessageMaxLength,
      '조립 메시지가 $kSmsMessageMaxLength자를 초과: ${msg.length}자',
    );
    return msg;
  }

  /// "바로 가능" 선택 여부 — 주입 측에서 #gotoworkyn 체크에 사용.
  static bool wantsImmediateStart(SmsMessageInput input) =>
      input.startDate == StartDate.immediate;

  static String? _koreanSentence(KoreanLevel? level) {
    switch (level) {
      case KoreanLevel.fluent:
        return '한국어로 어려움 없이 대화할 수 있습니다.';
      case KoreanLevel.conversational:
        return '한국어로 기본적인 대화는 할 수 있습니다.';
      case KoreanLevel.basic:
        return '한국어는 조금 할 수 있고, 계속 배우고 있습니다.';
      case KoreanLevel.learning:
        return '한국어는 지금 열심히 배우고 있습니다.';
      case null:
        return null;
    }
  }

  static String? _koreaStaySentence(KoreaStay? stay) {
    switch (stay) {
      case KoreaStay.under1y:
        return '한국에 온 지 1년이 안 됐습니다.';
      case KoreaStay.oneToThree:
        return '한국에서 지낸 지 1~3년 정도 됐습니다.';
      case KoreaStay.overThree:
        return '한국에서 지낸 지 3년이 넘었습니다.';
      case null:
        return null;
    }
  }

  static String? _studentSentence(StudentStatus? status) {
    switch (status) {
      case StudentStatus.enrolled:
        return '현재 대학에 재학 중입니다.';
      case StudentStatus.onLeave:
        return '현재 대학을 휴학 중입니다.';
      case null:
        return null;
    }
  }

  static String? _experienceSentence(ExperienceLevel? exp) {
    switch (exp) {
      case ExperienceLevel.none:
        return '아직 경력은 없지만 성실하게 배우겠습니다.';
      case ExperienceLevel.under1y:
        return '관련 경력이 1년 미만 정도 있습니다.';
      case ExperienceLevel.oneToThree:
        return '관련 경력이 1~3년 정도 있습니다.';
      case ExperienceLevel.overThree:
        return '관련 경력이 3년 이상 있습니다.';
      case null:
        return null;
    }
  }

  /// 요일·시간 조합 문장. 종류 매트릭스(구체/공고맞춤/협의/없음)로 분기.
  static String? _availabilitySentence(SmsMessageInput input) {
    final dayKind = _kindOf(
        input.daysNegotiable, input.daysMatchPosting, input.workDays.isEmpty);
    final timeKind = _kindOf(input.timesNegotiable, input.timesMatchPosting,
        input.workTimes.isEmpty);

    if (dayKind == _ClauseKind.none && timeKind == _ClauseKind.none) {
      return null;
    }

    final dayLabel = _daysLabel(input.workDays);
    final timeLabel = _timesLabel(input.workTimes);

    // 둘 다 "전부 선택" → 전용 문장
    if (dayKind == _ClauseKind.specific &&
        timeKind == _ClauseKind.specific &&
        _setEquals(input.workDays, _weekdaysAll) &&
        input.workTimes.length == DayPart.values.length) {
      return '요일과 시간 모두 맞출 수 있습니다.';
    }

    switch ((dayKind, timeKind)) {
      case (_ClauseKind.specific, _ClauseKind.specific):
        return '$dayLabel $timeLabel 근무할 수 있습니다.';
      case (_ClauseKind.specific, _ClauseKind.none):
        return '$dayLabel 근무할 수 있습니다.';
      case (_ClauseKind.none, _ClauseKind.specific):
        return '$timeLabel 근무할 수 있습니다.';
      case (_ClauseKind.specific, _ClauseKind.negotiable):
        return '$dayLabel 근무할 수 있고, 시간은 협의 가능합니다.';
      case (_ClauseKind.negotiable, _ClauseKind.specific):
        return '$timeLabel 근무할 수 있고, 요일은 협의 가능합니다.';
      case (_ClauseKind.specific, _ClauseKind.matchPosting):
        return '$dayLabel 근무할 수 있고, 시간은 공고 조건에 맞출 수 있습니다.';
      case (_ClauseKind.matchPosting, _ClauseKind.specific):
        return '$timeLabel 근무할 수 있고, 요일은 공고 조건에 맞출 수 있습니다.';
      case (_ClauseKind.negotiable, _ClauseKind.none):
        return '근무 요일은 협의 가능합니다.';
      case (_ClauseKind.none, _ClauseKind.negotiable):
        return '근무 시간은 협의 가능합니다.';
      case (_ClauseKind.matchPosting, _ClauseKind.none):
        return '근무 요일은 공고 조건에 맞출 수 있습니다.';
      case (_ClauseKind.none, _ClauseKind.matchPosting):
        return '근무 시간은 공고 조건에 맞출 수 있습니다.';
      case (_ClauseKind.negotiable, _ClauseKind.negotiable):
        return '근무 요일과 시간은 협의 가능합니다.';
      case (_ClauseKind.matchPosting, _ClauseKind.matchPosting):
        return '공고에 안내된 근무 조건에 맞춰 일할 수 있습니다.';
      case (_ClauseKind.negotiable, _ClauseKind.matchPosting):
        return '근무 요일은 협의 가능하고, 시간은 공고 조건에 맞출 수 있습니다.';
      case (_ClauseKind.matchPosting, _ClauseKind.negotiable):
        return '근무 요일은 공고 조건에 맞추고, 시간은 협의 가능합니다.';
      case (_ClauseKind.none, _ClauseKind.none):
        return null; // 위에서 처리됨
    }
  }

  static _ClauseKind _kindOf(bool negotiable, bool matchPosting, bool empty) {
    if (negotiable) return _ClauseKind.negotiable;
    if (matchPosting) return _ClauseKind.matchPosting;
    return empty ? _ClauseKind.none : _ClauseKind.specific;
  }

  /// 요일 집합 → 한국어. 매일/평일/주말만 축약, 나머지는 요일순 나열.
  static String? _daysLabel(Set<Weekday> days) {
    if (days.isEmpty) return null;
    if (_setEquals(days, _weekdaysAll)) return '매일';
    if (_setEquals(days, _weekdaysWeekday)) return '평일';
    if (_setEquals(days, _weekdaysWeekend)) return '주말';
    final sorted = days.toList()..sort((a, b) => a.index.compareTo(b.index));
    return '${sorted.map((d) => _weekdayLabel[d]).join(', ')}요일';
  }

  /// 시간대 집합 → 한국어. 전부면 "하루 종일", 나머지는 선택순 나열.
  static String? _timesLabel(Set<DayPart> times) {
    if (times.isEmpty) return null;
    if (times.length == DayPart.values.length) return '하루 종일';
    final sorted = times.toList()..sort((a, b) => a.index.compareTo(b.index));
    return sorted.map((t) => _dayPartLabel[t]).join(', ');
  }

  static String? _startSentence(StartDate? start) {
    switch (start) {
      case StartDate.immediate:
        return '바로 출근 가능합니다.';
      case StartDate.withinWeek:
        return '일주일 안에 출근할 수 있습니다.';
      case StartDate.negotiable:
        return '출근일은 상의해서 정하면 좋겠습니다.';
      case null:
        return null;
    }
  }

  static bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
