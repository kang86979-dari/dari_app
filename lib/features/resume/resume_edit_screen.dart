import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/widgets/app_back_button.dart';
import '../../data/models/resume.dart';
import '../../data/services/khire_resume_codes.dart';
import '../../providers/account_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/resume_provider.dart';
import '../apply/address/address_input_screen.dart';
import 'khire_code_labels.dart';
import 'resume_manage_screen.dart';
import 'resume_self_compose_screen.dart';
import 'widgets/resume_section.dart';
import 'widgets/resume_pickers.dart';

/// 이력서 작성/수정 화면 (canonical). Dari가 원본 — 여기서 저장하면
/// 마이페이지·온라인 지원 양쪽이 같은 이력서를 공유(2026-10-05).
/// 저장만 담당, K-HIRE 주입은 온라인 지원 흐름에서(Phase 3).
class ResumeEditScreen extends ConsumerStatefulWidget {
  final String site;
  const ResumeEditScreen({super.key, this.site = 'khire'});

  static Future<bool?> show(BuildContext context, {String site = 'khire'}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ResumeEditScreen(site: site)),
    );
  }

  @override
  ConsumerState<ResumeEditScreen> createState() => _ResumeEditScreenState();
}

class _ResumeEditScreenState extends ConsumerState<ResumeEditScreen> {
  final _codes = KhireResumeCodes.instance;
  bool _loading = true;
  bool _saving = false;

  // K-HIRE 실물 제약: 제목 25자, 희망 근무지 최대 3개(2026-10-09 덤프 확인).
  static const _kTitleMax = 25;
  static const _kMaxAreas = 3;
  // 신규 기본 제목 — 어필형 고정 문구 1개(편집 가능). 비자·기간 등
  // 사실 주장이 없어 누구에게나 성립. 한국 담당자가 읽으므로 항상 한국어.
  static const _kDefaultTitle = '맡은 업무에 항상 최선을 다하겠습니다.';

  // 편집 상태 (canonical Resume에서 복원).
  final _titleCtrl = TextEditingController();
  // 자소서 — 직접 타이핑 대신 '만들기'(칩 조립, 2026-10-09).
  String _selfText = '';
  Map<String, dynamic> _selfChips = {};
  String? _lastEduCd;
  String? _eduStateCd;
  // 경력 — K-HIRE 필수 섹션: 신입('new')/경력('exp') 명시 선택.
  String? _careerType;
  final List<ResumeCareer> _careers = [];
  final List<ResumeArea> _areas = [];
  final List<ResumeJobKind> _jobKinds = [];
  String? _workPeriodCd;
  String? _workWeekCd;
  final List<String> _employmentCds = [];
  String? _payCd;
  String? _koreanLevelCd;
  int? _topikLevel; // TOPIK 급수(선택, 2026-10-11)
  // 선택 입력
  final List<ResumeLicense> _licenses = [];
  final List<ResumeForeignLang> _foreignLangs = [];

  Resume? _original;

  // 이탈 확인용 기준선 — _init 직후 상태의 직렬화본.
  String _baseline = '';

  @override
  void initState() {
    super.initState();
    // 제목 타이핑 → 저장 버튼 문구 갱신(isComplete가 텍스트 의존).
    _titleCtrl.addListener(_onTextChanged);
    _init();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    await _codes.ensureLoaded();
    final existing = await ref.read(resumeProvider(widget.site).future);
    if (!mounted) return;
    if (existing != null) {
      _original = existing;
      // 25자 초과 기존 저장본(옛 초안 등)은 주입 시 잘리므로 로드 때 정리.
      _titleCtrl.text = existing.title.length > _kTitleMax
          ? existing.title.substring(0, _kTitleMax)
          : existing.title;
      _selfText = existing.selfIntro;
      _selfChips = Map.of(existing.selfChips);
      _lastEduCd = existing.lastEduCd;
      _eduStateCd = existing.eduStateCd;
      _careerType = existing.careerType;
      _careers.addAll(existing.careers);
      _areas.addAll(existing.areas);
      _jobKinds.addAll(existing.jobKinds);
      _workPeriodCd = existing.workPeriodCd;
      _workWeekCd = existing.workWeekCd;
      _employmentCds.addAll(existing.employmentCds);
      _payCd = existing.payCd;
      _koreanLevelCd = existing.koreanLevelCd;
      _topikLevel = existing.topikLevel;
      _licenses.addAll(existing.licenses);
      _foreignLangs.addAll(existing.foreignLangs);
    } else {
      // 신규: 기본 제목 자동 입력(편집 가능).
      _titleCtrl.text = _kDefaultTitle;
    }
    _baseline = jsonEncode(_collect().toData());
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Resume _collect() {
    return (_original ?? Resume(site: widget.site)).copyWith(
      site: widget.site,
      title: _titleCtrl.text.trim(),
      selfIntro: _selfText.trim(),
      selfChips: Map.of(_selfChips),
      lastEduCd: _lastEduCd,
      eduStateCd: _eduStateCd,
      careerType: _careerType,
      careers: List.of(_careers),
      areas: List.of(_areas),
      jobKinds: List.of(_jobKinds),
      workPeriodCd: _workPeriodCd,
      workWeekCd: _workWeekCd,
      employmentCds: List.of(_employmentCds),
      payCd: _payCd,
      koreanLevelCd: _koreanLevelCd,
      topikLevel: _topikLevel,
      licenses: List.of(_licenses),
      foreignLangs: List.of(_foreignLangs),
    );
  }

  // 주소는 Resume가 아닌 프로필에 저장되지만 K-HIRE 온라인 지원 폼(거주지)
  // 필수라 저장 조건에 포함(2026-10-09).
  bool get _hasAddress =>
      (ref.read(accountProvider).profile?.addrRoad ?? '').isNotEmpty;

  bool get _canSave => _collect().isComplete && _hasAddress;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      var r = _collect();
      final changed = jsonEncode(r.toData()) != _baseline;
      // 동기화 A안: Dari 경유로 K-HIRE에 등록된 이력서를 수정하면
      // '반영 대기'로 표시 → 다음 지원 때 자동 반영(2026-10-09).
      final syncPending = r.khireRegistered && changed;
      if (syncPending) r = r.copyWith(khireDirty: true);
      await ref.read(resumeActionsProvider).save(r);
      if (mounted) {
        if (syncPending) {
          final s = AppStrings.of(ref.read(languageProvider));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.resumeSyncPendingToast),
            behavior: SnackBarBehavior.floating,
          ));
        }
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      // 네트워크/인증 실패 — 조용히 삼키지 않고 안내(재시도 가능 상태 유지).
      if (mounted) {
        final s = AppStrings.of(ref.read(languageProvider));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.accountSaveFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 피커 호출 ──
  Future<void> _pickEducation() async {
    final lang = ref.read(languageProvider);
    final s = AppStrings.of(lang);
    final cd = await ResumePickers.pickCode(
      context,
      title: s.resumeEducationLabel,
      items: _codes.education,
      selected: _lastEduCd,
      labelOf: (c) => khireItemLabel(c, lang),
    );
    if (cd != null) {
      setState(() {
        _lastEduCd = cd;
        // 졸업상태 기본: 해당 학력 첫 옵션(사용자가 바꿀 수 있음).
        final states = _codes.eduStateFor(cd);
        _eduStateCd = states.isNotEmpty ? states.first.cd : null;
      });
    }
  }

  Future<void> _pickEduState() async {
    if (_lastEduCd == null) return;
    final lang = ref.read(languageProvider);
    final s = AppStrings.of(lang);
    final cd = await ResumePickers.pickCode(
      context,
      title: s.resumeEduStateLabel,
      items: _codes.eduStateFor(_lastEduCd!),
      selected: _eduStateCd,
      labelOf: (c) => khireItemLabel(c, lang),
    );
    if (cd != null) setState(() => _eduStateCd = cd);
  }

  Future<void> _addArea() async {
    final lang = ref.read(languageProvider);
    if (_areas.length >= _kMaxAreas) {
      final s = AppStrings.of(lang);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.resumeAreaLimit),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final area = await ResumePickers.pickArea(context, lang, _codes);
    if (area != null &&
        !_areas.any((a) => a.areaCd == area.areaCd && a.localCd == area.localCd)) {
      setState(() => _areas.add(area));
    }
  }

  Future<void> _addJobKind() async {
    final lang = ref.read(languageProvider);
    final jk = await ResumePickers.pickJobKind(context, lang, _codes);
    if (jk != null && !_jobKinds.any((j) => j.jk2Cd == jk.jk2Cd)) {
      setState(() => _jobKinds.add(jk));
    }
  }

  Future<void> _pickWorkPeriod() async {
    final lang = ref.read(languageProvider);
    final s = AppStrings.of(lang);
    final cd = await ResumePickers.pickCode(
      context,
      title: s.resumeWorkPeriodLabel,
      items: _codes.workPeriod(),
      selected: _workPeriodCd,
      labelOf: (c) => khireItemLabel(c, lang),
    );
    if (cd != null) setState(() => _workPeriodCd = cd);
  }

  Future<void> _pickWorkWeek() async {
    final lang = ref.read(languageProvider);
    final s = AppStrings.of(lang);
    final cd = await ResumePickers.pickCode(
      context,
      title: s.resumeWorkWeekLabel,
      items: _codes.workWeek(),
      selected: _workWeekCd,
      labelOf: (c) => khireItemLabel(c, lang),
    );
    if (cd != null) setState(() => _workWeekCd = cd);
  }

  Future<void> _pickKorean() async {
    final lang = ref.read(languageProvider);
    final s = AppStrings.of(lang);
    final cd = await ResumePickers.pickCode(
      context,
      title: s.resumeKoreanLabel,
      items: _codes.koreanLevel,
      selected: _koreanLevelCd,
      labelOf: (c) => khireItemLabel(c, lang),
      subtitleOf: (c) => khireLevelTitle(c, lang),
    );
    if (cd != null) setState(() => _koreanLevelCd = cd);
  }

  Future<void> _pickTopik() async {
    final lang = ref.read(languageProvider);
    final s = AppStrings.of(lang);
    final items = [
      CodeItem('0', s.resumeTopikNone),
      for (var i = 1; i <= 6; i++) CodeItem('$i', 'TOPIK $i급'),
    ];
    final cd = await ResumePickers.pickCode(
      context,
      title: s.resumeTopikHint,
      items: items,
      selected: _topikLevel == null ? '0' : '${_topikLevel}',
    );
    if (cd != null) {
      setState(() => _topikLevel = cd == '0' ? null : int.parse(cd));
    }
  }

  // 코드 → 사용자 언어 표시명 (주입은 한국어 원본, 표시만 번역 — 2026-10-09).
  String? _nameOf(List<CodeItem> items, String? cd) {
    if (cd == null) return null;
    final lang = ref.read(languageProvider);
    for (final c in items) {
      if (c.cd == cd) return khireItemLabel(c, lang);
    }
    return null;
  }

  // ── 자기소개서 만들기 ──
  Widget _selfRow(AppStrings s) {
    if (_selfText.trim().isEmpty) {
      return ResumePickerRow(
        value: null,
        hint: s.resumeSelfCompose,
        onTap: _openSelfCompose,
      );
    }
    return GestureDetector(
      onTap: _openSelfCompose,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _selfText,
          style: const TextStyle(
              fontSize: 14, height: 1.6, color: AppColors.gray900),
        ),
      ),
    );
  }

  Future<void> _openSelfCompose() async {
    String koreanNm = '';
    for (final c in _codes.koreanLevel) {
      if (c.cd == _koreanLevelCd) koreanNm = c.nm;
    }
    final r = await ResumeSelfComposeScreen.show(
      context,
      initialChips: _selfChips,
      careers: _careerType == 'exp' ? List.of(_careers) : const [],
      koreanNm: koreanNm,
      topikLevel: _topikLevel,
      licenses: List.of(_licenses),
    );
    if (r != null && mounted) {
      setState(() {
        _selfText = r['text'] as String? ?? '';
        _selfChips = Map<String, dynamic>.from(r['chips'] as Map? ?? {});
      });
    }
  }

  // ── 경력사항 ──
  String _careerLabel(ResumeCareer c, AppStrings s) {
    String ym(String v) =>
        v.length == 6 ? '${v.substring(0, 4)}.${v.substring(4)}' : v;
    final end = c.inWork ? s.resumeCareerInWork : ym(c.endYm);
    return '${c.company} · ${ym(c.startYm)} ~ $end';
  }

  // 년 → 월 2단 피커로 YYYYMM 선택 (키패드 없음).
  Future<String?> _pickYm(String title) async {
    final now = DateTime.now();
    final years = [
      for (var y = now.year; y >= now.year - 40; y--) CodeItem('$y', '$y')
    ];
    final y = await ResumePickers.pickCode(context,
        title: title, items: years);
    if (y == null || !mounted) return null;
    final months = [
      for (var m = 1; m <= 12; m++)
        CodeItem(m.toString().padLeft(2, '0'), m.toString().padLeft(2, '0'))
    ];
    final m = await ResumePickers.pickCode(context, title: y, items: months);
    if (m == null) return null;
    return '$y$m';
  }

  Future<void> _addCareer() async {
    final s = AppStrings.of(ref.read(languageProvider));
    final companyCtrl = TextEditingController();
    var startYm = '';
    var endYm = '';
    var inWork = false;
    var similar = false;
    String fmtYm(String v) =>
        v.length == 6 ? '${v.substring(0, 4)}.${v.substring(4)}' : '';

    final result = await showDialog<ResumeCareer>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final valid = companyCtrl.text.trim().isNotEmpty &&
              startYm.isNotEmpty &&
              (inWork ||
                  (endYm.isNotEmpty && endYm.compareTo(startYm) >= 0));
          Widget ymRow(String hint, String value, bool enabled,
              void Function(String) onPicked) {
            return InkWell(
              onTap: enabled
                  ? () async {
                      final v = await _pickYm(hint);
                      if (v != null) setLocal(() => onPicked(v));
                    }
                  : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gray100),
                  color: enabled ? null : AppColors.gray50,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.isEmpty ? hint : fmtYm(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: value.isEmpty
                              ? AppColors.gray300
                              : AppColors.gray900,
                          fontWeight: value.isEmpty
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.gray300),
                  ],
                ),
              ),
            );
          }

          Widget checkRow(String label, bool on, VoidCallback onTap) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Row(
                children: [
                  Icon(
                    on ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 20,
                    color: on ? AppColors.carrot : AppColors.gray300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.gray600)),
                  ),
                ],
              ),
            );
          }

          // 공용 셸 — 라운드·패딩 통일, 액션은 유효성 게이트라 자체 유지(2026-10-10).
          return AppDialogShell(
            title: s.resumeCareerLabel,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: companyCtrl,
                    onChanged: (_) => setLocal(() {}),
                    decoration: InputDecoration(
                      hintText: s.resumeCareerCompany,
                      hintStyle: const TextStyle(
                          color: AppColors.gray300, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.gray100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.carrot),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ymRow(s.resumeCareerStart, startYm, true,
                            (v) => startYm = v),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ymRow(s.resumeCareerEnd, endYm, !inWork,
                            (v) => endYm = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  checkRow(s.resumeCareerInWork, inWork, () {
                    setLocal(() {
                      inWork = !inWork;
                      if (inWork) endYm = '';
                    });
                  }),
                  const SizedBox(height: 8),
                  checkRow(s.resumeCareerSimilar, similar,
                      () => setLocal(() => similar = !similar)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(s.cancel,
                    style: const TextStyle(color: AppColors.gray400)),
              ),
              TextButton(
                onPressed: valid
                    ? () => Navigator.of(ctx).pop(ResumeCareer(
                          company: companyCtrl.text.trim(),
                          startYm: startYm,
                          endYm: inWork ? '' : endYm,
                          inWork: inWork,
                          similar: similar,
                        ))
                    : null,
                child: Text(
                  s.resumeAdd,
                  style: TextStyle(
                    color: valid ? AppColors.carrot : AppColors.gray200,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (result != null && mounted) {
      setState(() => _careers.add(result));
    }
  }

  // ── 뒤로가기: 미저장 변경이 있으면 임시저장 확인(버튼 탭에만 —
  // PopScope는 iOS 스와이프백을 죽이므로 금지, 2026-10-09) ──
  Future<void> _onBackTap() async {
    final changed = jsonEncode(_collect().toData()) != _baseline;
    if (!changed || _saving) {
      Navigator.of(context).pop();
      return;
    }
    final s = AppStrings.of(ref.read(languageProvider));
    // 공용 팝업 모듈(2026-10-10) — 디자인 확정안.
    final save = await showAppDialog(
      context,
      title: s.resumeDraftAskTitle,
      message: s.resumeDraftAskBody,
      cancelLabel: s.no,
      confirmLabel: s.yes,
    );
    if (!mounted || save == null) return;
    if (save) {
      await _save(); // 저장 성공 시 내부에서 pop
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final s = AppStrings.of(lang);
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _appBar(s),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.carrot),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(s),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // 안내 — 관리 화면과 동일 목록형(자동입력+한국어 작성),
                    // 온라인 지원 진입 경로에도 노출(2026-10-11).
                    ResumeIntroBox([s.resumeManageIntro, s.resumeIntroKorean]),
                    const SizedBox(height: 20),

                    // 제목 — K-HIRE 25자 제한, 기본 문구 자동 입력(편집 가능).
                    ResumeSection(title: s.resumeTitleLabel, required: true),
                    _textField(_titleCtrl, s.resumeTitleHint,
                        maxLines: 1, maxLength: _kTitleMax),
                    const SizedBox(height: 24),

                    // 최종학력
                    ResumeSection(title: s.resumeEducationLabel, required: true),
                    ResumePickerRow(
                      value: _nameOf(_codes.education, _lastEduCd),
                      hint: s.resumeSelectHint,
                      onTap: _pickEducation,
                    ),
                    if (_lastEduCd != null) ...[
                      const SizedBox(height: 8),
                      ResumePickerRow(
                        value: _nameOf(
                            _codes.eduStateFor(_lastEduCd!), _eduStateCd),
                        hint: s.resumeEduStateLabel,
                        onTap: _pickEduState,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // 경력사항 — K-HIRE 필수 섹션(신입/경력). 키패드는 회사명만.
                    ResumeSection(
                      title: s.resumeCareerLabel,
                      required: true,
                      onAdd: _careerType == 'exp' ? _addCareer : null,
                    ),
                    _CareerTypeChips(
                      newLabel: s.resumeCareerNew,
                      expLabel: s.resumeCareerExp,
                      selected: _careerType,
                      onSelect: (t) => setState(() => _careerType = t),
                    ),
                    if (_careerType == 'exp') ...[
                      const SizedBox(height: 10),
                      ..._careers.asMap().entries.map((e) => ResumeChipRow(
                            label: _careerLabel(e.value, s),
                            onRemove: () =>
                                setState(() => _careers.removeAt(e.key)),
                          )),
                      if (_careers.isEmpty) _emptyHint(s.resumeAddHint),
                    ],
                    const SizedBox(height: 24),

                    // 희망 근무지
                    ResumeSection(
                      title: s.resumeAreaLabel,
                      required: true,
                      onAdd: _addArea,
                    ),
                    ..._areas.map((a) => ResumeChipRow(
                          label: '${a.areaNm} ${a.localNm}',
                          onRemove: () => setState(() => _areas.remove(a)),
                        )),
                    if (_areas.isEmpty) _emptyHint(s.resumeAddHint),
                    const SizedBox(height: 24),

                    // 희망 업직종
                    ResumeSection(
                      title: s.resumeJobKindLabel,
                      required: true,
                      onAdd: _addJobKind,
                    ),
                    ..._jobKinds.map((j) => ResumeChipRow(
                          label: '${j.jk1Nm} > ${j.jk2Nm}',
                          onRemove: () => setState(() => _jobKinds.remove(j)),
                        )),
                    if (_jobKinds.isEmpty) _emptyHint(s.resumeAddHint),
                    const SizedBox(height: 24),

                    // 희망 근무조건
                    ResumeSection(
                        title: s.resumeWorkConditionLabel, required: true),
                    ResumePickerRow(
                      value: _nameOf(_codes.workPeriod(), _workPeriodCd),
                      hint: s.resumeWorkPeriodLabel,
                      onTap: _pickWorkPeriod,
                    ),
                    const SizedBox(height: 8),
                    ResumePickerRow(
                      value: _nameOf(_codes.workWeek(), _workWeekCd),
                      hint: s.resumeWorkWeekLabel,
                      onTap: _pickWorkWeek,
                    ),
                    const SizedBox(height: 8),
                    _EmploymentChips(
                      options: _codes.workEmployment(),
                      selected: _employmentCds,
                      label: s.resumeEmploymentLabel,
                      labelOf: (c) => khireItemLabel(c, lang),
                      onToggle: (cd) => setState(() {
                        _employmentCds.contains(cd)
                            ? _employmentCds.remove(cd)
                            : _employmentCds.add(cd);
                      }),
                    ),
                    const SizedBox(height: 24),

                    // 한국어능력
                    ResumeSection(title: s.resumeKoreanLabel, required: true),
                    ResumePickerRow(
                      value: _nameOf(_codes.koreanLevel, _koreanLevelCd),
                      hint: s.resumeSelectHint,
                      onTap: _pickKorean,
                    ),
                    const SizedBox(height: 10),
                    // TOPIK 급수(선택) — 있으면 자소서에 자동 포함(2026-10-11).
                    ResumePickerRow(
                      value: _topikLevel == null
                          ? ''
                          : 'TOPIK ${_topikLevel}급',
                      hint: s.resumeTopikHint,
                      onTap: _pickTopik,
                    ),
                    const SizedBox(height: 28),

                    // 주소 — 회원정보와 공유. K-HIRE 온라인 지원 폼(거주지)
                    // 필수 항목이라 여기서도 필수(2026-10-09).
                    ResumeSection(title: s.addressTitle, required: true),
                    _addressRow(),
                    const SizedBox(height: 28),

                    // ── 선택 입력 ──
                    Text(
                      s.resumeOptionalHeader,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ResumeSection(
                      title: s.resumeLicenseLabel,
                      onAdd: _addLicense,
                    ),
                    ..._licenses.asMap().entries.map((e) => ResumeChipRow(
                          label: e.value.name,
                          onRemove: () =>
                              setState(() => _licenses.removeAt(e.key)),
                        )),
                    const SizedBox(height: 28),

                    // 자기소개서 — 다른 항목(국적·비자·한국어·경력·자격증)을
                    // 재료로 자동 조립하므로 **맨 마지막**(2026-10-11).
                    ResumeSection(title: s.resumeSelfLabel, required: true),
                    _selfRow(s),
                  ],
                ),
              ),
            ),
            _saveBar(s),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(AppStrings s) => AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBackButton(onTap: _loading ? null : _onBackTap),
        ),
        title: Text(
          s.resumeScreenTitle,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      );

  // 임시저장 허용(2026-10-09 사용자 확정) — 버튼은 항상 활성,
  // 필수+주소를 다 채우면 '저장', 아니면 '임시저장' 문구.
  Widget _saveBar(AppStrings s) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        // 공용 CTA 모듈 — 저장 중 스피너 포함(2026-10-10).
        child: AppPrimaryButton(
          label: _canSave ? s.resumeSave : s.resumeSaveDraft,
          onTap: _save,
          loading: _saving,
        ),
      );

  Widget _textField(TextEditingController ctrl, String hint,
      {int maxLines = 1, int? maxLength}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        counterStyle:
            const TextStyle(color: AppColors.gray300, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray300, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gray100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.carrot),
        ),
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.gray300, fontSize: 13),
        ),
      );

  // 주소 요약 행 (탭 → AddressInputScreen).
  Widget _addressRow() {
    final p = ref.watch(accountProvider).profile;
    final road = p?.addrRoad ?? '';
    final detail = p?.addrDetail ?? '';
    final s = AppStrings.of(ref.read(languageProvider));
    final text = road.isEmpty
        ? null
        : [road, detail].where((e) => e.isNotEmpty).join(' ');
    return ResumePickerRow(
      value: text,
      hint: s.addressTapHint,
      onTap: () => AddressInputScreen.show(context),
    );
  }

  // ── 선택 입력 추가 다이얼로그 ──
  Future<void> _addLicense() async {
    final r = await ResumePickers.inputLicense(
        context, ref.read(languageProvider));
    if (r != null) setState(() => _licenses.add(r));
  }
}

/// 신입/경력 단일 선택 칩 — 한번 고르면 서로 전환만 가능(해제 없음).
class _CareerTypeChips extends StatelessWidget {
  final String newLabel;
  final String expLabel;
  final String? selected; // 'new' | 'exp' | null(미선택)
  final void Function(String) onSelect;
  const _CareerTypeChips({
    required this.newLabel,
    required this.expLabel,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String value, String label) {
      final on = selected == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(value),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: on ? AppColors.carrotLight : AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: on ? AppColors.carrot : AppColors.gray100,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: on ? AppColors.carrotDark : AppColors.gray500,
                fontSize: 14,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('new', newLabel),
        const SizedBox(width: 8),
        chip('exp', expLabel),
      ],
    );
  }
}

/// 고용형태 복수 선택 칩 (필터 칩 스타일).
class _EmploymentChips extends StatelessWidget {
  final List<CodeItem> options;
  final List<String> selected;
  final String label;
  final String Function(CodeItem)? labelOf;
  final void Function(String cd) onToggle;
  const _EmploymentChips({
    required this.options,
    required this.selected,
    required this.label,
    this.labelOf,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray400,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
        final on = selected.contains(o.cd);
        return GestureDetector(
          onTap: () => onToggle(o.cd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: on ? AppColors.carrotLight : AppColors.gray50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: on ? AppColors.carrot : AppColors.gray100,
              ),
            ),
            child: Text(
              labelOf?.call(o) ?? o.nm,
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
    );
  }
}
