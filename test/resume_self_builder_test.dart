import 'package:flutter_test/flutter_test.dart';

import 'package:korea_job/data/models/resume.dart';
import 'package:korea_job/features/apply/sms/sms_message_builder.dart'
    show KoreaStay;
import 'package:korea_job/features/resume/resume_self_builder.dart';

void main() {
  final now = DateTime(2026, 10, 9);

  group('ResumeSelfBuilder', () {
    test('전체 선택 — 국적·비자·거주·경험·강점·각오', () {
      final text = ResumeSelfBuilder.build(ResumeSelfInput(
        nationalityKo: '방글라데시',
        visaCode: 'E-9',
        stay: KoreaStay.overThree,
        exps: {SelfExp.factory, SelfExp.restaurant},
        strengths: {SelfStrength.diligent, SelfStrength.stamina},
        resolve: SelfResolve.longTerm,
        now: now,
      ));
      expect(text, contains('안녕하세요. 저는 방글라데시에서 왔고 E-9 비자를 가지고 있습니다.'));
      expect(text, contains('3년이 넘었습니다'));
      expect(text, contains('일한 경험이 있습니다'));
      expect(text, contains('맡은 일은 끝까지 성실하게 해냅니다.'));
      expect(text, contains('체력에 자신이 있습니다.'));
      expect(text, contains('한곳에서 오래 일하고 싶습니다.'));
      expect(text, contains('기회를 주시면 성실히 일하겠습니다. 감사합니다.'));
      expect(text.split('\n').length, 4); // 문단 4개
    });

    test('아무것도 없음 — 인사+맺음만', () {
      final text = ResumeSelfBuilder.build(ResumeSelfInput(now: now));
      expect(text, '안녕하세요.\n기회를 주시면 성실히 일하겠습니다. 감사합니다.');
    });

    test('처음이에요 — 다른 경험 칩 무시', () {
      final text = ResumeSelfBuilder.build(ResumeSelfInput(
        exps: {SelfExp.firstTime, SelfExp.factory},
        now: now,
      ));
      expect(text, contains('처음이지만 성실하게 배우겠습니다'));
      expect(text, isNot(contains('공장')));
    });

    test('경력 있으면 경험 칩 대신 경력 문장 + 유사 분야 문장', () {
      final text = ResumeSelfBuilder.build(ResumeSelfInput(
        exps: {SelfExp.cleaning},
        careers: [
          const ResumeCareer(
              company: '버거킹 송도점',
              startYm: '202403',
              endYm: '202501',
              similar: true),
        ],
        now: now,
      ));
      expect(text, contains('버거킹 송도점에서 11개월 일했습니다.'));
      expect(text, contains('비슷한 일을 해봐서'));
      expect(text, isNot(contains('청소')));
    });

    test('재직중 경력 — now까지 계산, 년/개월 포맷', () {
      final text = ResumeSelfBuilder.build(ResumeSelfInput(
        careers: [
          const ResumeCareer(company: '공장A', startYm: '202409', inWork: true),
        ],
        now: now,
      ));
      // 2024.09~2026.10 = 26개월 = 2년 2개월
      expect(text, contains('공장A에서 2년 2개월 일했습니다.'));
    });

    test('경력 3건이어도 2건까지만 문장화', () {
      final text = ResumeSelfBuilder.build(ResumeSelfInput(
        careers: const [
          ResumeCareer(company: 'A', startYm: '202401', endYm: '202402'),
          ResumeCareer(company: 'B', startYm: '202403', endYm: '202404'),
          ResumeCareer(company: 'C', startYm: '202405', endYm: '202406'),
        ],
        now: now,
      ));
      expect(text, contains('A에서'));
      expect(text, contains('B에서'));
      expect(text, isNot(contains('C에서')));
    });

    test('강점 3개 선택돼도 2개까지만', () {
      final text = ResumeSelfBuilder.build(ResumeSelfInput(
        strengths: {
          SelfStrength.diligent,
          SelfStrength.careful,
          SelfStrength.punctual,
        },
        now: now,
      ));
      final count = ['성실하게 해냅니다', '꼼꼼하게 일합니다', '시간 약속을']
          .where(text.contains)
          .length;
      expect(count, 2);
    });

    test('formatMonths', () {
      expect(ResumeSelfBuilder.formatMonths(1), '1개월');
      expect(ResumeSelfBuilder.formatMonths(12), '1년');
      expect(ResumeSelfBuilder.formatMonths(15), '1년 3개월');
      expect(ResumeSelfBuilder.formatMonths(0), '');
    });

    test('ResumeCareer.months — 같은 달 1개월, 역순 0', () {
      expect(
          const ResumeCareer(startYm: '202403', endYm: '202403')
              .months(now),
          1);
      expect(
          const ResumeCareer(startYm: '202403', endYm: '202401')
              .months(now),
          0);
    });
  });
}
