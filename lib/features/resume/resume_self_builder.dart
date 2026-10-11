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

/// 지원 동기 (단일, 2026-10-11 — 자소서 4문단 구조의 ③).
enum SelfMotive { stable, learnSkill, family, settle }

/// 근무 조건 (복수, 2026-10-11 — ④ 포부에 포함. 외국인 채용에서 가치 큼).
enum SelfCond { shiftNight, weekend, dormNeeded }

class ResumeSelfInput {
  final String nationalityKo; // 한국어 국적명 (없으면 '')
  final String visaCode; // 예: E-9 (없으면 '')
  final KoreaStay? stay;
  final String koreanNm; // 한국어 수준 nm(사이트 원본 한국어, 이력서에서 자동)
  final int? topikLevel; // TOPIK 급수(이력서에서 자동, null=없음)
  final Set<SelfExp> exps; // careers 없을 때만 사용
  final List<ResumeCareer> careers; // 있으면 exps 대신 경력 문장
  final List<ResumeLicense> licenses; // 이력서 자격증(자동, 최대 2건 문장화)
  final Set<SelfStrength> strengths;
  final SelfMotive? motive;
  final Set<SelfCond> conds;
  final SelfResolve? resolve;
  final DateTime now; // 재직중 개월 계산용(테스트 주입)

  const ResumeSelfInput({
    this.nationalityKo = '',
    this.visaCode = '',
    this.stay,
    this.koreanNm = '',
    this.topikLevel,
    this.exps = const {},
    this.careers = const [],
    this.licenses = const [],
    this.strengths = const {},
    this.motive,
    this.conds = const {},
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

  static const _motiveKo = {
    SelfMotive.stable: '안정적인 일자리에서 꾸준히 일하고 싶어 지원했습니다.',
    SelfMotive.learnSkill: '기술을 배우며 성장하고 싶어 지원했습니다.',
    SelfMotive.family: '가족을 부양하기 위해 열심히 일하고 싶습니다.',
    SelfMotive.settle: '한국에 오래 정착하며 일하고 싶습니다.',
  };

  static const _condKo = {
    SelfCond.shiftNight: '교대·야간 근무도 가능합니다.',
    SelfCond.weekend: '주말 근무도 가능합니다.',
    SelfCond.dormNeeded: '기숙사 제공이 가능한 곳이면 더욱 좋습니다.',
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
    // 한국 자소서 4문단 구조(2026-10-11):
    // ①소개(국적·비자·거주·한국어) ②경력·강점(+자격증) ③지원 동기 ④입사 후 포부.
    final paragraphs = <String>[];

    // ── ① 소개 — 전부 프로필/이력서 데이터 자동.
    final intro = <String>['안녕하세요.'];
    if (i.nationalityKo.isNotEmpty && i.visaCode.isNotEmpty) {
      intro.add('저는 ${i.nationalityKo}에서 왔고 ${i.visaCode} 비자를 가지고 있습니다.');
    } else if (i.nationalityKo.isNotEmpty) {
      intro.add('저는 ${i.nationalityKo}에서 온 구직자입니다.');
    }
    switch (i.stay) {
      case KoreaStay.under1y:
        intro.add('한국에 온 지 1년이 안 됐지만 빠르게 적응하고 있습니다.');
      case KoreaStay.oneToThree:
        intro.add('한국에 거주한 지 1~3년 됐습니다.');
      case KoreaStay.overThree:
        intro.add('한국에 거주한 지 3년이 넘었습니다.');
      case null:
        break;
    }
    if (i.koreanNm.isNotEmpty && i.topikLevel != null) {
      intro.add('한국어는 ${i.koreanNm} 수준이며, TOPIK ${i.topikLevel}급 자격이 있습니다.');
    } else if (i.koreanNm.isNotEmpty) {
      intro.add('한국어는 ${i.koreanNm} 수준입니다.');
    } else if (i.topikLevel != null) {
      intro.add('TOPIK ${i.topikLevel}급 자격이 있습니다.');
    }
    paragraphs.add(intro.join(' '));

    // ── ② 경력 및 강점 (+자격증 자동).
    final body = <String>[];
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
    for (final l in i.licenses.take(2)) {
      if (l.name.isNotEmpty) body.add('${l.name} 자격증이 있습니다.');
    }
    body.addAll(i.strengths.take(2).map((s) => _strengthKo[s]!));
    if (body.isNotEmpty) paragraphs.add(body.join(' '));

    // ── ③ 지원 동기.
    if (i.motive != null) paragraphs.add(_motiveKo[i.motive]!);

    // ── ④ 입사 후 포부 (근무 조건 + 각오 + 맺음).
    final will = <String>[
      ...SelfCond.values.where(i.conds.contains).map((c) => _condKo[c]!),
      if (i.resolve != null) _resolveKo[i.resolve]!,
      '기회를 주시면 성실히 일하겠습니다. 감사합니다.',
    ];
    paragraphs.add(will.join(' '));

    return paragraphs.join('\n');
  }
}
