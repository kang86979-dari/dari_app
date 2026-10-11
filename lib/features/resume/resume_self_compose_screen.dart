import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/picker_field.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/widgets/app_back_button.dart';
import '../../data/constants/world_countries.dart';
import '../../data/models/resume.dart';
import '../../providers/account_provider.dart';
import '../../providers/language_provider.dart';
import '../apply/sms/sms_compose_prefs.dart';
import '../apply/sms/sms_message_builder.dart' show KoreaStay;
import 'resume_self_builder.dart';

/// 자기소개서 만들기 — 문자 만들기(SMS)와 같은 방식: 질문은 사용자 언어
/// 칩으로 답하고, 결과는 한국어 자소서로 조립(2026-10-09).
/// pop 결과: {'text': 조립/편집된 한국어 자소서, 'chips': 칩 상태 Map}.
class ResumeSelfComposeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialChips;
  final List<ResumeCareer> careers;
  // 자동 조립 재료(이력서에서 전달, 2026-10-11): 한국어 수준·TOPIK·자격증.
  final String koreanNm;
  final int? topikLevel;
  final List<ResumeLicense> licenses;
  const ResumeSelfComposeScreen({
    super.key,
    this.initialChips = const {},
    this.careers = const [],
    this.koreanNm = '',
    this.topikLevel,
    this.licenses = const [],
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic> initialChips = const {},
    List<ResumeCareer> careers = const [],
    String koreanNm = '',
    int? topikLevel,
    List<ResumeLicense> licenses = const [],
  }) {
    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => ResumeSelfComposeScreen(
          initialChips: initialChips,
          careers: careers,
          koreanNm: koreanNm,
          topikLevel: topikLevel,
          licenses: licenses,
        ),
      ),
    );
  }

  @override
  ConsumerState<ResumeSelfComposeScreen> createState() =>
      _ResumeSelfComposeScreenState();
}

class _ResumeSelfComposeScreenState
    extends ConsumerState<ResumeSelfComposeScreen> {
  KoreaStay? _stay;
  final Set<SelfExp> _exps = {};
  final Set<SelfStrength> _strengths = {};
  SelfResolve? _resolve;
  SelfMotive? _motive; // 지원 동기(2026-10-11)
  final Set<SelfCond> _conds = {}; // 근무 조건(2026-10-11)
  String? _customText; // 직접편집본 — 칩 바꾸면 폐기(SMS와 동일 A안)

  @override
  void initState() {
    super.initState();
    final c = widget.initialChips;
    _stay = _enumByName(KoreaStay.values, c['stay'] as String?);
    for (final e in (c['exps'] as List?) ?? const []) {
      final v = _enumByName(SelfExp.values, e as String?);
      if (v != null) _exps.add(v);
    }
    for (final e in (c['strengths'] as List?) ?? const []) {
      final v = _enumByName(SelfStrength.values, e as String?);
      if (v != null) _strengths.add(v);
    }
    _resolve = _enumByName(SelfResolve.values, c['resolve'] as String?);
    _motive = _enumByName(SelfMotive.values, c['motive'] as String?);
    for (final e in (c['conds'] as List?) ?? const []) {
      final v = _enumByName(SelfCond.values, e as String?);
      if (v != null) _conds.add(v);
    }
    _customText = c['custom'] as String?;
    // 거주기간: 자소서에 저장값이 없으면 SMS 요약 설정에서 프리필
    // (같은 KoreaStay enum 공유, 2026-10-11).
    if (_stay == null) {
      SmsComposePrefs.load().then((prefs) {
        if (!mounted || _stay != null) return;
        final stay = prefs?.koreaStay;
        if (stay != null) setState(() => _stay = stay);
      });
    }
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  // 국적 한국어명 — 코드로 worldCountries 재조회(저장 라벨은 언어가
  // 섞일 수 있어 신뢰하지 않음).
  String get _nationalityKo {
    final p = ref.read(accountProvider).profile;
    final code = p?.nationalityCode ?? '';
    for (final (c, _, ko) in worldCountries) {
      if (c == code) return ko;
    }
    return '';
  }

  ResumeSelfInput get _input {
    final p = ref.read(accountProvider).profile;
    return ResumeSelfInput(
      nationalityKo: _nationalityKo,
      visaCode: p?.visaCode ?? '',
      stay: _stay,
      exps: Set.of(_exps),
      careers: widget.careers,
      strengths: Set.of(_strengths),
      resolve: _resolve,
      motive: _motive,
      conds: Set.of(_conds),
      koreanNm: widget.koreanNm,
      topikLevel: widget.topikLevel,
      licenses: widget.licenses,
      now: DateTime.now(),
    );
  }

  String get _builtText => _customText ?? ResumeSelfBuilder.build(_input);

  Map<String, dynamic> get _chips => {
        if (_stay != null) 'stay': _stay!.name,
        'exps': _exps.map((e) => e.name).toList(),
        'strengths': _strengths.map((e) => e.name).toList(),
        if (_resolve != null) 'resolve': _resolve!.name,
        if (_motive != null) 'motive': _motive!.name,
        'conds': _conds.map((e) => e.name).toList(),
        if (_customText != null) 'custom': _customText,
      };

  void _onChipChanged(VoidCallback update) {
    setState(() {
      _customText = null; // 칩 변경 = 직접편집본 폐기
      update();
    });
  }

  Future<void> _openDirectEdit() async {
    final s = AppStrings.of(ref.read(languageProvider));
    final edited = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _SelfTextEditScreen(
          initial: _builtText,
          title: s.resumeSelfLabel,
          saveLabel: s.resumeSave,
        ),
      ),
    );
    if (edited != null && edited.trim().isNotEmpty) {
      setState(() => _customText = edited.trim());
    }
  }

  // 옵션 라벨 (사용자 언어 — 조립 결과는 한국어).
  String _expLabel(SelfExp v) {
    final s = AppStrings.of(ref.read(languageProvider));
    return switch (v) {
      SelfExp.firstTime => s.selfExpFirst,
      SelfExp.restaurant => s.selfExpRestaurant,
      SelfExp.factory => s.selfExpFactory,
      SelfExp.construction => s.selfExpConstruction,
      SelfExp.farm => s.selfExpFarm,
      SelfExp.logistics => s.selfExpLogistics,
      SelfExp.cleaning => s.selfExpCleaning,
      SelfExp.other => s.selfExpOther,
    };
  }

  String _strengthLabel(SelfStrength v) {
    final s = AppStrings.of(ref.read(languageProvider));
    return switch (v) {
      SelfStrength.diligent => s.selfStrDiligent,
      SelfStrength.stamina => s.selfStrStamina,
      SelfStrength.careful => s.selfStrCareful,
      SelfStrength.fastLearner => s.selfStrFastLearner,
      SelfStrength.bright => s.selfStrBright,
      SelfStrength.punctual => s.selfStrPunctual,
    };
  }

  String _motiveLabel(SelfMotive v) {
    final s = AppStrings.of(ref.read(languageProvider));
    return switch (v) {
      SelfMotive.stable => s.selfMotiveStable,
      SelfMotive.learnSkill => s.selfMotiveLearn,
      SelfMotive.family => s.selfMotiveFamily,
      SelfMotive.settle => s.selfMotiveSettle,
    };
  }

  String _condLabel(SelfCond v) {
    final s = AppStrings.of(ref.read(languageProvider));
    return switch (v) {
      SelfCond.shiftNight => s.selfCondShiftNight,
      SelfCond.weekend => s.selfCondWeekend,
      SelfCond.dormNeeded => s.selfCondDorm,
    };
  }

  String _resolveLabel(SelfResolve v) {
    final s = AppStrings.of(ref.read(languageProvider));
    return switch (v) {
      SelfResolve.longTerm => s.selfResLongTerm,
      SelfResolve.learnHard => s.selfResLearnHard,
      SelfResolve.startNow => s.selfResStartNow,
    };
  }

  // 공용 피커 시트 래퍼 — 선택 결과를 칩 상태에 반영(_onChipChanged).
  Future<void> _pickOne<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T? selected,
    required void Function(T?) onPicked,
  }) async {
    final r = await PickerSheet.pickOne<T>(context,
        title: title, options: options, labelOf: labelOf, selected: selected);
    if (r == null) return;
    _onChipChanged(() => onPicked(r is PickerUnset ? null : r as T));
  }

  Future<void> _pickMulti<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required Set<T> selected,
    required void Function(Set<T>) onPicked,
    int? max,
    void Function(Set<T> next, T tapped)? normalize,
  }) async {
    final r = await PickerSheet.pickMulti<T>(context,
        title: title,
        options: options,
        labelOf: labelOf,
        selected: selected,
        confirmLabel: AppStrings.of(ref.read(languageProvider)).confirm,
        max: max,
        normalize: normalize);
    if (r == null) return;
    _onChipChanged(() => onPicked(r));
  }

  void _save() {
    Navigator.of(context).pop({'text': _builtText, 'chips': _chips});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(ref.watch(languageProvider));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: Text(
          s.resumeSelfCompose,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  // ① 거주 기간 (소개 문단 재료)
                  PickerField(
                    label: s.smsKoreaStayLabel,
                    value: switch (_stay) {
                      KoreaStay.under1y => s.smsStayUnder1y,
                      KoreaStay.oneToThree => s.smsStayOneToThree,
                      KoreaStay.overThree => s.smsStayOverThree,
                      null => '',
                    },
                    hint: s.resumeSelectHint,
                    onTap: () => _pickOne<KoreaStay>(
                      title: s.smsKoreaStayLabel,
                      options: KoreaStay.values,
                      labelOf: (v) => switch (v) {
                        KoreaStay.under1y => s.smsStayUnder1y,
                        KoreaStay.oneToThree => s.smsStayOneToThree,
                        KoreaStay.overThree => s.smsStayOverThree,
                      },
                      selected: _stay,
                      onPicked: (v) => _stay = v,
                    ),
                  ),
                  // ② 일 경험 — 경력사항 있으면 생략(경력으로 문장 생성).
                  if (widget.careers.isEmpty)
                    PickerField(
                      label: s.selfQExp,
                      value: SelfExp.values
                          .where(_exps.contains)
                          .map(_expLabel)
                          .join(', '),
                      hint: s.resumeSelectHint,
                      onTap: () => _pickMulti<SelfExp>(
                        title: s.selfQExp,
                        options: SelfExp.values,
                        labelOf: _expLabel,
                        selected: _exps,
                        normalize: (next, tapped) {
                          // '처음'은 단독 선택.
                          if (tapped == SelfExp.firstTime &&
                              next.contains(SelfExp.firstTime)) {
                            next
                              ..clear()
                              ..add(SelfExp.firstTime);
                          } else if (next.length > 1) {
                            next.remove(SelfExp.firstTime);
                          }
                        },
                        onPicked: (v) => _exps
                          ..clear()
                          ..addAll(v),
                      ),
                    ),
                  // ③ 강점 (최대 2)
                  PickerField(
                    label: s.selfQStrength,
                    value: SelfStrength.values
                        .where(_strengths.contains)
                        .map(_strengthLabel)
                        .join(', '),
                    hint: s.resumeSelectHint,
                    onTap: () => _pickMulti<SelfStrength>(
                      title: s.selfQStrength,
                      options: SelfStrength.values,
                      labelOf: _strengthLabel,
                      selected: _strengths,
                      max: 2,
                      onPicked: (v) => _strengths
                        ..clear()
                        ..addAll(v),
                    ),
                  ),
                  // ④ 지원 동기 (2026-10-11 신규 — 자소서 3문단)
                  PickerField(
                    label: s.selfQMotive,
                    value: _motive == null ? '' : _motiveLabel(_motive!),
                    hint: s.resumeSelectHint,
                    onTap: () => _pickOne<SelfMotive>(
                      title: s.selfQMotive,
                      options: SelfMotive.values,
                      labelOf: _motiveLabel,
                      selected: _motive,
                      onPicked: (v) => _motive = v,
                    ),
                  ),
                  // ⑤ 근무 조건 (2026-10-11 신규 — 외국인 채용 가치)
                  PickerField(
                    label: s.selfQCond,
                    value: SelfCond.values
                        .where(_conds.contains)
                        .map(_condLabel)
                        .join(', '),
                    hint: s.resumeSelectHint,
                    onTap: () => _pickMulti<SelfCond>(
                      title: s.selfQCond,
                      options: SelfCond.values,
                      labelOf: _condLabel,
                      selected: _conds,
                      onPicked: (v) => _conds
                        ..clear()
                        ..addAll(v),
                    ),
                  ),
                  // ⑥ 각오
                  PickerField(
                    label: s.selfQResolve,
                    value: _resolve == null ? '' : _resolveLabel(_resolve!),
                    hint: s.resumeSelectHint,
                    onTap: () => _pickOne<SelfResolve>(
                      title: s.selfQResolve,
                      options: SelfResolve.values,
                      labelOf: _resolveLabel,
                      selected: _resolve,
                      onPicked: (v) => _resolve = v,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 미리보기 (한국어 전송본) + 직접편집
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.smsPreviewKoreanNote,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.gray400),
                        ),
                      ),
                      GestureDetector(
                        onTap: _openDirectEdit,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Text(
                            s.smsEditOnKhire,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.carrot,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _builtText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AppPrimaryButton(
                // 공용 CTA 모듈(2026-10-10).
                label: s.resumeSave,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 질문 라벨 + 칩 묶음 (필터 칩 스타일 — SMS 화면과 통일).
/// 직접편집 — 별도 라우트(화면 내 모드전환 금지: iOS 스와이프백 보존).
class _SelfTextEditScreen extends StatefulWidget {
  final String initial;
  final String title;
  final String saveLabel;
  const _SelfTextEditScreen({
    required this.initial,
    required this.title,
    required this.saveLabel,
  });

  @override
  State<_SelfTextEditScreen> createState() => _SelfTextEditScreenState();
}

class _SelfTextEditScreenState extends State<_SelfTextEditScreen> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _ctrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.gray100),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.carrot),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AppPrimaryButton(
                // 공용 CTA 모듈(2026-10-10).
                label: widget.saveLabel,
                onTap: () =>
                      Navigator.of(context).pop(_ctrl.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

