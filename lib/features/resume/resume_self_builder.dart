import '../../data/models/resume.dart';
import '../apply/sms/sms_message_builder.dart' show KoreaStay;

/// 자기소개서 칩 선택값 → 한국어 자소서 조립 (2026-10-09).
///
/// SMS 메시지 빌더와 같은 원칙: 질문·칩은 사용자 언어, 조립 결과는
/// 항상 한국어(읽는 사람 = 한국 채용 담당자). 문단 사이만 \n.

/// 한국에서 일한 경험 (경력사항이 없을 때만 질문).
enum SelfExp {
  firstTime,
  restaurant,
  factory,
  construction,
  farm,
  logistics,
  cleaning,
  other,
}

/// 강점 (최대 2개).
enum SelfStrength { diligent, stamina, careful, fastLearner, bright, punctual }

/// 각오 (단일).
enum SelfResolve { longTerm, learnHard, startNow }

class ResumeSelfInput {
  final String nationalityKo; // 한국어 국적명 (없으면 '')
  final String visaCode; // 예: E-9 (없으면 '')
  final KoreaStay? stay;
  final Set<SelfExp> exps; // careers 없을 때만 사용
  final List<ResumeCareer> careers; // 있으면 exps 대신 경력 문장
  final Set<SelfStrength> strengths;
  final SelfResolve? resolve;
  final DateTime now; // 재직중 개월 계산용(테스트 주입)

  const ResumeSelfInput({
    this.nationalityKo = '',
    this.visaCode = '',
    this.stay,
    this.exps = const {},
    this.careers = const [],
    this.strengths = const {},
    this.resolve,
    required this.now,
  });
}

class ResumeSelfBuilder {
  ResumeSelfBuilder._();

  static const _expPlaceKo = {
    SelfExp.restaurant: '식당',
    SelfExp.factory: '공장',
    SelfExp.construction: '건설 현장',
    SelfExp.farm: '농장',
    SelfExp.logistics: '물류 센터',
    SelfExp.cleaning: '청소 현장',
  };

  static const _strengthKo = {
    SelfStrength.diligent: '맡은 일은 끝까지 성실하게 해냅니다.',
    SelfStrength.stamina: '체력에 자신이 있습니다.',
    SelfStrength.careful: '꼼꼼하게 일합니다.',
    SelfStrength.fastLearner: '새로운 일도 빨리 배웁니다.',
    SelfStrength.bright: '밝은 성격으로 즐겁게 일합니다.',
    SelfStrength.punctual: '시간 약속을 잘 지킵니다.',
  };

  static const _resolveKo = {
    SelfResolve.longTerm: '한곳에서 오래 일하고 싶습니다.',
    SelfResolve.learnHard: '열심히 배우며 최선을 다하겠습니다.',
    SelfResolve.startNow: '바로 출근할 수 있습니다.',
  };

  /// 개월 수 → '10개월' / '1년' / '1년 3개월'.
  static String formatMonths(int months) {
    if (months <= 0) return '';
    final y = months ~/ 12;
    final m = months % 12;
    if (y == 0) return '$m개월';
    if (m == 0) return '$y년';
    return '$y년 $m개월';
  }

  static String build(ResumeSelfInput i) {
    final paragraphs = <String>[];

    // ① 인사 + 소개 (국적·비자는 프로필에서 자동).
    final intro = <String>['안녕하세요.'];
    if (i.nationalityKo.isNotEmpty && i.visaCode.isNotEmpty) {
      intro.add('저는 ${i.nationalityKo}에서 왔고 ${i.visaCode} 비자를 가지고 있습니다.');
    } else if (i.nationalityKo.isNotEmpty) {
      intro.add('저는 ${i.nationalityKo}에서 온 구직자입니다.');
    }
    paragraphs.add(intro.join(' '));

    // ② 거주 기간 + 일 경험.
    final body = <String>[];
    switch (i.stay) {
      case KoreaStay.under1y:
        body.add('한국에 온 지 1년이 안 됐지만 빠르게 적응하고 있습니다.');
      case KoreaStay.oneToThree:
        body.add('한국에 거주한 지 1~3년 됐습니다.');
      case KoreaStay.overThree:
        body.add('한국에 거주한 지 3년이 넘었습니다.');
      case null:
        break;
    }
    if (i.careers.isNotEmpty) {
      // 경력 최대 2건 문장화.
      for (final c in i.careers.take(2)) {
        final dur = formatMonths(c.months(i.now));
        if (c.company.isEmpty) continue;
        body.add(dur.isEmpty
            ? '${c.company}에서 일했습니다.'
            : '${c.company}에서 $dur 일했습니다.');
      }
      if (i.careers.any((c) => c.similar)) {
        body.add('지원하는 분야와 비슷한 일을 해봐서 빨리 적응할 수 있습니다.');
      }
    } else if (i.exps.contains(SelfExp.firstTime)) {
      body.add('한국에서 일하는 것은 처음이지만 성실하게 배우겠습니다.');
    } else {
      final places = i.exps
          .where(_expPlaceKo.containsKey)
          .map((e) => _expPlaceKo[e]!)
          .toList();
      if (places.isNotEmpty) {
        body.add('${places.join(', ')}에서 일한 경험이 있습니다.');
      } else if (i.exps.contains(SelfExp.other)) {
        body.add('한국에서 일한 경험이 있습니다.');
      }
    }
    if (body.isNotEmpty) paragraphs.add(body.join(' '));

    // ③ 강점 + 각오.
    final will = <String>[
      ...i.strengths.take(2).map((s) => _strengthKo[s]!),
      if (i.resolve != null) _resolveKo[i.resolve]!,
    ];
    if (will.isNotEmpty) paragraphs.add(will.join(' '));

    // ④ 맺음.
    paragraphs.add('기회를 주시면 성실히 일하겠습니다. 감사합니다.');

    return paragraphs.join('\n');
  }
}
