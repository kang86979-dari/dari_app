import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/widgets/app_back_button.dart';
import '../../data/constants/world_countries.dart';
import '../../data/models/resume.dart';
import '../../providers/account_provider.dart';
import '../../providers/language_provider.dart';
import '../apply/sms/sms_message_builder.dart' show KoreaStay;
import 'resume_self_builder.dart';

/// 자기소개서 만들기 — 문자 만들기(SMS)와 같은 방식: 질문은 사용자 언어
/// 칩으로 답하고, 결과는 한국어 자소서로 조립(2026-10-09).
/// pop 결과: {'text': 조립/편집된 한국어 자소서, 'chips': 칩 상태 Map}.
class ResumeSelfComposeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialChips;
  final List<ResumeCareer> careers;
  const ResumeSelfComposeScreen({
    super.key,
    this.initialChips = const {},
    this.careers = const [],
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic> initialChips = const {},
    List<ResumeCareer> careers = const [],
  }) {
    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => ResumeSelfComposeScreen(
          initialChips: initialChips,
          careers: careers,
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
    _customText = c['custom'] as String?;
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
      now: DateTime.now(),
    );
  }

  String get _builtText => _customText ?? ResumeSelfBuilder.build(_input);

  Map<String, dynamic> get _chips => {
        if (_stay != null) 'stay': _stay!.name,
        'exps': _exps.map((e) => e.name).toList(),
        'strengths': _strengths.map((e) => e.name).toList(),
        if (_resolve != null) 'resolve': _resolve!.name,
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
                  // 거주 기간
                  _ChipGroup<KoreaStay>(
                    label: s.smsKoreaStayLabel,
                    options: const [
                      KoreaStay.under1y,
                      KoreaStay.oneToThree,
                      KoreaStay.overThree,
                    ],
                    labelOf: (v) => switch (v) {
                      KoreaStay.under1y => s.smsStayUnder1y,
                      KoreaStay.oneToThree => s.smsStayOneToThree,
                      KoreaStay.overThree => s.smsStayOverThree,
                    },
                    isSelected: (v) => _stay == v,
                    onTap: (v) => _onChipChanged(
                        () => _stay = _stay == v ? null : v),
                  ),
                  // 일 경험 — 경력사항이 있으면 질문 생략(경력으로 문장 생성).
                  if (widget.careers.isEmpty)
                    _ChipGroup<SelfExp>(
                      label: s.selfQExp,
                      options: SelfExp.values,
                      labelOf: (v) => switch (v) {
                        SelfExp.firstTime => s.selfExpFirst,
                        SelfExp.restaurant => s.selfExpRestaurant,
                        SelfExp.factory => s.selfExpFactory,
                        SelfExp.construction => s.selfExpConstruction,
                        SelfExp.farm => s.selfExpFarm,
                        SelfExp.logistics => s.selfExpLogistics,
                        SelfExp.cleaning => s.selfExpCleaning,
                        SelfExp.other => s.selfExpOther,
                      },
                      isSelected: _exps.contains,
                      onTap: (v) => _onChipChanged(() {
                        if (_exps.contains(v)) {
                          _exps.remove(v);
                        } else if (v == SelfExp.firstTime) {
                          _exps
                            ..clear()
                            ..add(v); // '처음'은 단독
                        } else {
                          _exps
                            ..remove(SelfExp.firstTime)
                            ..add(v);
                        }
                      }),
                    ),
                  // 강점 (최대 2)
                  _ChipGroup<SelfStrength>(
                    label: s.selfQStrength,
                    options: SelfStrength.values,
                    labelOf: (v) => switch (v) {
                      SelfStrength.diligent => s.selfStrDiligent,
                      SelfStrength.stamina => s.selfStrStamina,
                      SelfStrength.careful => s.selfStrCareful,
                      SelfStrength.fastLearner => s.selfStrFastLearner,
                      SelfStrength.bright => s.selfStrBright,
                      SelfStrength.punctual => s.selfStrPunctual,
                    },
                    isSelected: _strengths.contains,
                    onTap: (v) => _onChipChanged(() {
                      if (_strengths.contains(v)) {
                        _strengths.remove(v);
                      } else if (_strengths.length < 2) {
                        _strengths.add(v);
                      }
                    }),
                  ),
                  // 각오
                  _ChipGroup<SelfResolve>(
                    label: s.selfQResolve,
                    options: SelfResolve.values,
                    labelOf: (v) => switch (v) {
                      SelfResolve.longTerm => s.selfResLongTerm,
                      SelfResolve.learnHard => s.selfResLearnHard,
                      SelfResolve.startNow => s.selfResStartNow,
                    },
                    isSelected: (v) => _resolve == v,
                    onTap: (v) => _onChipChanged(
                        () => _resolve = _resolve == v ? null : v),
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
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.carrot,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    s.resumeSave,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 질문 라벨 + 칩 묶음 (필터 칩 스타일 — SMS 화면과 통일).
class _ChipGroup<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final bool Function(T) isSelected;
  final void Function(T) onTap;
  const _ChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.labelOf,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final on = isSelected(o);
              return GestureDetector(
                onTap: () => onTap(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: on ? AppColors.carrotLight : AppColors.gray50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: on ? AppColors.carrot : AppColors.gray100,
                    ),
                  ),
                  child: Text(
                    labelOf(o),
                    style: TextStyle(
                      color: on ? AppColors.carrotDark : AppColors.gray500,
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

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
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ctrl.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.carrot,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.saveLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
