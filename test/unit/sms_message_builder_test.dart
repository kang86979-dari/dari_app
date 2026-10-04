import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/features/apply/sms/sms_message_builder.dart';

void main() {
  const profile = SmsMessageInput(
    nationalityLabel: '방글라데시',
    visaCode: 'E-9',
  );

  SmsMessageInput withChips({
    KoreanLevel? korean,
    ExperienceLevel? exp,
    Set<Weekday> days = const {},
    bool daysNego = false,
    bool daysMatch = false,
    Set<DayPart> times = const {},
    bool timesNego = false,
    bool timesMatch = false,
    StartDate? start,
  }) {
    return SmsMessageInput(
      nationalityLabel: '방글라데시',
      visaCode: 'E-9',
      koreanLevel: korean,
      experience: exp,
      workDays: days,
      daysNegotiable: daysNego,
      daysMatchPosting: daysMatch,
      workTimes: times,
      timesNegotiable: timesNego,
      timesMatchPosting: timesMatch,
      startDate: start,
    );
  }

  group('블록 1·2·7 (고정/프로필)', () {
    test('칩 전부 미선택: 인사+자기소개+맺음만 (줄바꿈 구분)', () {
      expect(
        SmsMessageBuilder.build(profile),
        '안녕하세요.\n저는 방글라데시에서 왔고, E-9 비자를 가지고 있습니다.\n기회를 주시면 열심히 일하겠습니다. 감사합니다.',
      );
    });
    test('국적/비자 비면 자기소개 생략', () {
      const empty = SmsMessageInput(nationalityLabel: '', visaCode: '');
      expect(SmsMessageBuilder.build(empty), '안녕하세요.\n기회를 주시면 열심히 일하겠습니다. 감사합니다.');
    });
  });

  group('블록 3 한국어', () {
    test('각 단계 문장', () {
      expect(SmsMessageBuilder.build(withChips(korean: KoreanLevel.fluent)),
          contains('한국어로 어려움 없이 대화할 수 있습니다.'));
      expect(
          SmsMessageBuilder.build(withChips(korean: KoreanLevel.conversational)),
          contains('한국어로 기본적인 대화는 할 수 있습니다.'));
      expect(SmsMessageBuilder.build(withChips(korean: KoreanLevel.basic)),
          contains('한국어는 조금 할 수 있고, 계속 배우고 있습니다.'));
      expect(SmsMessageBuilder.build(withChips(korean: KoreanLevel.learning)),
          contains('한국어는 지금 열심히 배우고 있습니다.'));
    });
  });

  group('블록 4 경력', () {
    test('처음/기간별', () {
      expect(SmsMessageBuilder.build(withChips(exp: ExperienceLevel.none)),
          contains('아직 경력은 없지만 성실하게 배우겠습니다.'));
      expect(SmsMessageBuilder.build(withChips(exp: ExperienceLevel.under1y)),
          contains('관련 경력이 1년 미만 정도 있습니다.'));
      expect(SmsMessageBuilder.build(withChips(exp: ExperienceLevel.oneToThree)),
          contains('관련 경력이 1~3년 정도 있습니다.'));
      expect(SmsMessageBuilder.build(withChips(exp: ExperienceLevel.overThree)),
          contains('관련 경력이 3년 이상 있습니다.'));
    });
  });

  group('블록 5 요일 나열', () {
    test('평일 전체 → "평일"', () {
      expect(
        SmsMessageBuilder.build(withChips(
            days: {Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri})),
        contains('평일 근무할 수 있습니다.'),
      );
    });
    test('주말 → "주말"', () {
      expect(
        SmsMessageBuilder.build(withChips(days: {Weekday.sat, Weekday.sun})),
        contains('주말 근무할 수 있습니다.'),
      );
    });
    test('전체 7일 + 시간 미선택 → "매일"', () {
      expect(
        SmsMessageBuilder.build(withChips(days: Weekday.values.toSet())),
        contains('매일 근무할 수 있습니다.'),
      );
    });
    test('비연속 월·수·금 → 나열', () {
      expect(
        SmsMessageBuilder.build(
            withChips(days: {Weekday.mon, Weekday.wed, Weekday.fri})),
        contains('월, 수, 금요일 근무할 수 있습니다.'),
      );
    });
    test('화요일 빼고 6일 → 나열', () {
      final days = Weekday.values.toSet()..remove(Weekday.tue);
      expect(
        SmsMessageBuilder.build(withChips(days: days)),
        contains('월, 수, 목, 금, 토, 일요일 근무할 수 있습니다.'),
      );
    });
  });

  group('블록 5 시간대', () {
    test('오전만', () {
      expect(SmsMessageBuilder.build(withChips(times: {DayPart.morning})),
          contains('오전 근무할 수 있습니다.'));
    });
    test('오전+야간 나열', () {
      expect(
        SmsMessageBuilder.build(
            withChips(times: {DayPart.morning, DayPart.night})),
        contains('오전, 야간 근무할 수 있습니다.'),
      );
    });
    test('시간대 전부 → "하루 종일"', () {
      expect(
        SmsMessageBuilder.build(withChips(times: DayPart.values.toSet())),
        contains('하루 종일 근무할 수 있습니다.'),
      );
    });
  });

  group('블록 5 요일+시간 조합', () {
    test('평일 오전·오후', () {
      expect(
        SmsMessageBuilder.build(withChips(
            days: _weekdays, times: {DayPart.morning, DayPart.afternoon})),
        contains('평일 오전, 오후 근무할 수 있습니다.'),
      );
    });
    test('월·수·금 저녁', () {
      expect(
        SmsMessageBuilder.build(withChips(
            days: {Weekday.mon, Weekday.wed, Weekday.fri},
            times: {DayPart.evening})),
        contains('월, 수, 금요일 저녁 근무할 수 있습니다.'),
      );
    });
    test('둘 다 전부 → 전용 문장', () {
      expect(
        SmsMessageBuilder.build(withChips(
            days: Weekday.values.toSet(), times: DayPart.values.toSet())),
        contains('요일과 시간 모두 맞출 수 있습니다.'),
      );
    });
  });

  group('블록 5 협의', () {
    test('요일·시간 둘 다 협의', () {
      expect(
        SmsMessageBuilder.build(withChips(daysNego: true, timesNego: true)),
        contains('근무 요일과 시간은 협의 가능합니다.'),
      );
    });
    test('요일 협의만', () {
      expect(SmsMessageBuilder.build(withChips(daysNego: true)),
          contains('근무 요일은 협의 가능합니다.'));
    });
    test('시간 협의만', () {
      expect(SmsMessageBuilder.build(withChips(timesNego: true)),
          contains('근무 시간은 협의 가능합니다.'));
    });
    test('요일 구체 + 시간 협의', () {
      expect(
        SmsMessageBuilder.build(
            withChips(days: _weekdays, timesNego: true)),
        contains('평일 근무할 수 있고, 시간은 협의 가능합니다.'),
      );
    });
    test('요일 협의 + 시간 구체', () {
      expect(
        SmsMessageBuilder.build(
            withChips(daysNego: true, times: {DayPart.morning})),
        contains('오전 근무할 수 있고, 요일은 협의 가능합니다.'),
      );
    });
    test('아무것도 선택 안 함 → 근무 블록 생략', () {
      expect(SmsMessageBuilder.build(profile), isNot(contains('근무')));
    });
  });

  group('블록 5 공고에 맞춤', () {
    test('요일·시간 둘 다 공고맞춤', () {
      expect(
        SmsMessageBuilder.build(withChips(daysMatch: true, timesMatch: true)),
        contains('공고에 안내된 근무 조건에 맞춰 일할 수 있습니다.'),
      );
    });
    test('요일 공고맞춤만', () {
      expect(SmsMessageBuilder.build(withChips(daysMatch: true)),
          contains('근무 요일은 공고 조건에 맞출 수 있습니다.'));
    });
    test('시간 공고맞춤만', () {
      expect(SmsMessageBuilder.build(withChips(timesMatch: true)),
          contains('근무 시간은 공고 조건에 맞출 수 있습니다.'));
    });
    test('요일 구체 + 시간 공고맞춤', () {
      expect(
        SmsMessageBuilder.build(withChips(days: _weekdays, timesMatch: true)),
        contains('평일 근무할 수 있고, 시간은 공고 조건에 맞출 수 있습니다.'),
      );
    });
    test('요일 공고맞춤 + 시간 구체', () {
      expect(
        SmsMessageBuilder.build(
            withChips(daysMatch: true, times: {DayPart.morning})),
        contains('오전 근무할 수 있고, 요일은 공고 조건에 맞출 수 있습니다.'),
      );
    });
    test('요일 공고맞춤 + 시간 협의', () {
      expect(
        SmsMessageBuilder.build(withChips(daysMatch: true, timesNego: true)),
        contains('근무 요일은 공고 조건에 맞추고, 시간은 협의 가능합니다.'),
      );
    });
  });

  group('한국 거주 기간(선택)', () {
    test('기간별 문구', () {
      expect(
        SmsMessageBuilder.build(SmsMessageInput(
            nationalityLabel: '네팔',
            visaCode: 'E-9',
            koreaStay: KoreaStay.under1y)),
        contains('한국에 온 지 1년이 안 됐습니다.'),
      );
      expect(
        SmsMessageBuilder.build(SmsMessageInput(
            nationalityLabel: '네팔',
            visaCode: 'E-9',
            koreaStay: KoreaStay.oneToThree)),
        contains('한국에서 지낸 지 1~3년 정도 됐습니다.'),
      );
      expect(
        SmsMessageBuilder.build(SmsMessageInput(
            nationalityLabel: '네팔',
            visaCode: 'E-9',
            koreaStay: KoreaStay.overThree)),
        contains('한국에서 지낸 지 3년이 넘었습니다.'),
      );
    });
    test('미선택이면 거주 기간 문구 없음', () {
      expect(SmsMessageBuilder.build(profile), isNot(contains('한국에')));
    });
  });

  group('학생 상태(선택)', () {
    test('재학/휴학 문구', () {
      expect(
        SmsMessageBuilder.build(SmsMessageInput(
            nationalityLabel: '방글라데시',
            visaCode: 'D-2',
            studentStatus: StudentStatus.enrolled)),
        contains('현재 대학에 재학 중입니다.'),
      );
      expect(
        SmsMessageBuilder.build(SmsMessageInput(
            nationalityLabel: '방글라데시',
            visaCode: 'D-2',
            studentStatus: StudentStatus.onLeave)),
        contains('현재 대학을 휴학 중입니다.'),
      );
    });
    test('미선택이면 학생 문구 없음', () {
      expect(SmsMessageBuilder.build(profile), isNot(contains('대학')));
    });
  });

  group('블록 6 시작일', () {
    test('각 문장', () {
      expect(SmsMessageBuilder.build(withChips(start: StartDate.immediate)),
          contains('바로 출근 가능합니다.'));
      expect(SmsMessageBuilder.build(withChips(start: StartDate.withinWeek)),
          contains('일주일 안에 출근할 수 있습니다.'));
      expect(SmsMessageBuilder.build(withChips(start: StartDate.negotiable)),
          contains('출근일은 상의해서 정하면 좋겠습니다.'));
    });
    test('바로 가능 → gotoworkyn 플래그', () {
      expect(
          SmsMessageBuilder.wantsImmediateStart(
              withChips(start: StartDate.immediate)),
          isTrue);
      expect(SmsMessageBuilder.wantsImmediateStart(profile), isFalse);
    });
  });

  group('글자수·순서', () {
    test('최악 조합(요일 6개 나열 등)도 400자 미만', () {
      final days = Weekday.values.toSet()..remove(Weekday.tue);
      final msg = SmsMessageBuilder.build(
        SmsMessageInput(
          nationalityLabel: '보스니아헤르체고비나',
          visaCode: 'E-7-4R',
          koreanLevel: KoreanLevel.conversational,
          experience: ExperienceLevel.oneToThree,
          workDays: days,
          workTimes: {DayPart.morning, DayPart.afternoon, DayPart.evening},
          startDate: StartDate.withinWeek,
        ),
      );
      expect(msg.length, lessThanOrEqualTo(kSmsMessageMaxLength));
    });
    test('블록 순서', () {
      final msg = SmsMessageBuilder.build(withChips(
        korean: KoreanLevel.fluent,
        exp: ExperienceLevel.oneToThree,
        days: _weekdays,
        times: {DayPart.morning},
        start: StartDate.immediate,
      ));
      final idx = [
        msg.indexOf('안녕하세요'),
        msg.indexOf('저는'),
        msg.indexOf('한국어'),
        msg.indexOf('경력'),
        msg.indexOf('평일'),
        msg.indexOf('바로 출근'),
        msg.indexOf('감사합니다'),
      ];
      expect(idx, orderedEquals([...idx]..sort()));
    });
  });
}

const _weekdays = {
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
};
