import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../data/models/job.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/language_provider.dart';
import '../../home/widgets/ad_banner.dart';
import 'sms_message_builder.dart';
import 'sms_compose_prefs.dart';
import 'khire_apply_webview_screen.dart';

/// 문자 지원 메시지 화면 + 문자 관리 화면(공용).
/// - 지원 모드([job] 있음): 칩으로 문구 조립 → 저장 + K-HIRE 웹뷰로 이동.
/// - 관리 모드([job] null, 마이페이지 "문자 관리"): 문구를 미리 만들어 저장만.
/// 저장된 문구는 다음에 자동으로 불러와 재사용된다.
/// 5개 항목(한국어/경력/요일/시간/시작일)을 모두 선택해야 저장·진행할 수 있다.
/// 계정 화면들과 동일한 iOS 스타일 뒤로가기(<) — 타이틀 중앙 정렬과 함께 사용.
/// 좌측 16 패딩 + 40 폭(AppBackButton) = AppBar leadingWidth 기본값(56)과 맞아
/// 커스텀 헤더(패딩 16)와 `<` 위치가 동일해짐.
Widget _smsBackButton(BuildContext context) => Padding(
      padding: const EdgeInsets.only(left: 16),
      child: AppBackButton(onTap: () => Navigator.of(context).maybePop()),
    );

class SmsPrepareScreen extends ConsumerStatefulWidget {
  final Job? job; // null = 문자 관리 모드

  /// 요약본에서 "수정하기"로 들어온 경우 true — 요약 없이 바로 칩 편집.
  /// (별도 라우트로 push돼 스와이프백이 자연스럽게 요약본으로 돌아감)
  final bool startInEdit;

  /// 지원 유형 — 'talk'(문자) 또는 'simple'(간편). 웹뷰로 그대로 전달.
  final String applyType;

  const SmsPrepareScreen(
      {super.key, this.job, this.startInEdit = false, this.applyType = 'talk'});

  @override
  ConsumerState<SmsPrepareScreen> createState() => _SmsPrepareScreenState();
}

class _SmsPrepareScreenState extends ConsumerState<SmsPrepareScreen> {
  KoreanLevel? _korean;
  ExperienceLevel? _exp;
  KoreaStay? _koreaStay; // 한국 거주 기간(선택 항목)
  bool _isStudent = false; // 학생 여부 체크박스(선택 항목)
  StudentStatus? _student; // 체크 시 재학/휴학
  final Set<Weekday> _days = {};
  bool _daysNego = false;
  bool _daysMatch = false;
  final Set<DayPart> _times = {};
  bool _timesNego = false;
  bool _timesMatch = false;
  StartDate? _start;

  // 직접 수정한 메시지(저장 시 확정). null이면 칩 기반. 칩을 다시 만지면 폐기(A안).
  String? _customMessage;

  bool get _isManage => widget.job == null;

  // 저장된 설정이 있으면 요약본 먼저 보여주기(항목별 선택 요약).
  bool _showSummary = false;
  // "지원할 때 요약 보기" 설정 — 지원 요약본 "다시 보지 않기"와 연동(동일 플래그).
  bool _showSummaryOnApply = true;
  // 설정 로드·스킵 판정 전에는 화면을 그리지 않음(요약 깜빡임 방지).
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPrefs(allowSkip: true);
  }

  /// 저장해둔 문구(칩 설정)를 불러와 기본값으로 — 지원/관리 모드 공용.
  /// 저장본이 있으면 요약 화면부터. 단 지원 모드에서 "다시 보지 않기"면
  /// 요약을 건너뛰고 바로 K-HIRE 웹뷰로 간다([allowSkip]이 true인 최초 1회만).
  Future<void> _loadSavedPrefs({bool allowSkip = false}) async {
    final p = await SmsComposePrefs.load();
    if (!mounted) return;
    if (p == null) {
      setState(() => _ready = true); // 저장본 없음 — 바로 작성 화면
      return;
    }
    setState(() {
      _showSummary = !widget.startInEdit;
      _showSummaryOnApply = p.showSummaryOnApply;
      _korean = p.koreanLevel;
      _exp = p.experience;
      _koreaStay = p.koreaStay;
      _isStudent = p.isStudent;
      _student = p.studentStatus;
      _days
        ..clear()
        ..addAll(p.workDays);
      _daysNego = p.daysNegotiable;
      _daysMatch = p.daysMatchPosting;
      _times
        ..clear()
        ..addAll(p.workTimes);
      _timesNego = p.timesNegotiable;
      _timesMatch = p.timesMatchPosting;
      _start = p.startDate;
    });
    // 지원 모드 + "다시 보지 않기": 요약 건너뛰고 바로 웹뷰로(이 화면 대체).
    // _ready를 올리지 않아 깜빡임 없이 로딩만 보이다가 교체된다.
    if (allowSkip && !_isManage && !widget.startInEdit && !p.showSummaryOnApply) {
      final msg = _message.trim();
      if (msg.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => KhireApplyWebViewScreen(
              job: widget.job!,
              message: msg,
              wantsImmediateStart:
                  SmsMessageBuilder.wantsImmediateStart(_input),
              langCode: ref.read(languageProvider),
              applyType: widget.applyType,
              messageInput: _customMessage != null ? null : _input,
            ),
          ));
        });
        return;
      }
    }
    setState(() => _ready = true);
  }

  void _savePrefs() {
    SmsComposePrefs.save(SmsComposePrefs(
      koreanLevel: _korean,
      experience: _exp,
      koreaStay: _koreaStay,
      isStudent: _isStudent,
      studentStatus: _student,
      workDays: _days,
      daysNegotiable: _daysNego,
      daysMatchPosting: _daysMatch,
      workTimes: _times,
      timesNegotiable: _timesNego,
      timesMatchPosting: _timesMatch,
      startDate: _start,
      showSummaryOnApply: _showSummaryOnApply,
    ));
  }

  SmsMessageInput get _input {
    final profile = ref.read(accountProvider).profile;
    return SmsMessageInput(
      nationalityLabel: profile?.nationalityLabel ?? '',
      visaCode: profile?.visaCode ?? '',
      koreanLevel: _korean,
      experience: _exp,
      studentStatus: _isStudent ? _student : null,
      koreaStay: _koreaStay,
      workDays: _days,
      daysNegotiable: _daysNego,
      daysMatchPosting: _daysMatch,
      workTimes: _times,
      timesNegotiable: _timesNego,
      timesMatchPosting: _timesMatch,
      startDate: _start,
    );
  }

  bool get _daysChosen => _days.isNotEmpty || _daysNego || _daysMatch;
  bool get _timesChosen => _times.isNotEmpty || _timesNego || _timesMatch;

  /// 5개 항목 모두 선택됐는지 — 전부 골라야 문구가 완성된다.
  bool get _allSelected =>
      _korean != null &&
      _exp != null &&
      _daysChosen &&
      _timesChosen &&
      _start != null;

  /// 화면 타이틀 — 관리 모드 / 간편지원 / 문자지원 구분.
  String _screenTitle(AppStrings s) {
    if (_isManage) return s.myPageSmsManage;
    if (widget.applyType == 'simple') {
      return s.applyMethodLabel('simple') ?? s.smsApplyTitle;
    }
    return s.smsApplyTitle;
  }

  /// 메인 화면에 보이는 메시지 — 저장된 수정본이 있으면 그것, 없으면 칩 조립본.
  String get _message => _customMessage ?? SmsMessageBuilder.build(_input);

  /// 계속하기 가능 조건 — 수정본이 있으면 그걸로, 없으면 5개 항목 전부 선택.
  bool get _canContinue => _customMessage != null
      ? _customMessage!.trim().isNotEmpty
      : _allSelected;

  /// 직접 편집 — 별도 화면 push(스와이프백=취소). 저장하면 수정본 반영.
  Future<void> _openTextEditor() async {
    final s = AppStrings.of(ref.read(languageProvider));
    final result = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => _SmsTextEditScreen(
        initial: _message,
        title: s.smsEditOnKhire,
        koreanNote: s.smsPreviewKoreanNote,
        saveLabel: s.jobMemoSave,
      ),
    ));
    if (result == null || !mounted) return;
    final text = result.trim();
    setState(() => _customMessage = text.isEmpty ? null : text);
  }

  /// 칩을 건드리면 수정본 폐기(A안) — 이후 칩 조립본이 우선.
  void _onChipTouched() {
    _customMessage = null;
  }

  /// 칩 작성 화면 "저장하기" — 문구 저장 후,
  /// 요약본에서 수정하러 온 경우(pop으로 요약 복귀) / 처음 작성이면 요약으로 전환.
  void _saveAndShowSummary() {
    if (!_canContinue) return;
    _savePrefs();
    final s = AppStrings.of(ref.read(languageProvider));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.smsSavedToast),
      behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2),
    ));
    if (widget.startInEdit) {
      Navigator.of(context).pop(true); // 요약본으로 복귀(갱신 신호)
    } else {
      setState(() => _showSummary = true);
    }
  }

  /// 요약본 "확인" — 지원 모드는 K-HIRE 웹뷰로, 관리 모드는 닫기.
  void _confirm() {
    final msg = _message.trim();
    if (msg.isEmpty) return;
    if (_isManage) {
      Navigator.of(context).pop();
      return;
    }
    // pushReplacement — 요약본을 웹뷰로 교체. 웹뷰에서 X(미완료) 시 요약본이
    // 아니라 공고 상세로 바로 돌아가게 함(2026-10-05 사용자 확정).
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => KhireApplyWebViewScreen(
        job: widget.job!,
        message: msg,
        wantsImmediateStart: SmsMessageBuilder.wantsImmediateStart(_input),
        langCode: ref.read(languageProvider),
        applyType: widget.applyType,
        // 직접 입력 수정본이면 재생성하지 않음(사용자 작성 그대로).
        messageInput: _customMessage != null ? null : _input,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(ref.watch(languageProvider));
    // 설정 로드·스킵 판정 전 — 빈 로딩(요약 깜빡임 방지).
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.carrot),
          ),
        ),
      );
    }
    // 수정은 전부 별도 라우트 push — 스와이프백/백버튼이 자연스럽게 동작.
    return _showSummary ? _buildSummaryMode(s) : _buildMainMode(s);
  }

  /// 저장된 설정 요약 — 항목별 선택값을 사용자 언어로 보여준다.
  Widget _buildSummaryMode(AppStrings s) {
    final rows = _summaryRows(s);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.black,
        centerTitle: true,
        leading: _smsBackButton(context),
        title: Text(_screenTitle(s),
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.black)),
        actions: [
          TextButton(
            // 별도 라우트 push — 저장/스와이프백 모두 요약본으로 복귀.
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    SmsPrepareScreen(job: widget.job, startInEdit: true),
              ));
              _loadSavedPrefs(); // 수정 저장분 반영
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.carrot),
            child: Text(s.smsEditOnKhire,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // 광고는 관리 모드(마이페이지)만 — 지원 흐름 요약본엔 없음(사용자 확정).
                if (_isManage) ...[
                  const AdBanner(),
                  const SizedBox(height: 8),
                ],
                // 공고 상세 테이블과 동일 스타일(InfoRow 공용 위젯)로 통일.
                for (var i = 0; i < rows.length; i++)
                  InfoRow(
                    label: rows[i].$1,
                    value: rows[i].$2,
                    isLast: i == rows.length - 1,
                  ),
                const SizedBox(height: 16),
                // 한국어 전송 미리보기(참고용) — 요약본에선 수정 버튼 없음.
                Text(s.smsPreviewLabel,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900)),
                const SizedBox(height: 2),
                Text(s.smsPreviewKoreanNote,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.gray400)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Text(_message,
                      style: const TextStyle(
                          fontSize: 15, height: 1.5, color: AppColors.black)),
                ),
                const SizedBox(height: 14),
                // 지원 모드: "다시 보지 않기" / 관리 모드: "지원할 때 요약 보기"
                // — 같은 설정(showSummaryOnApply)을 반대 방향에서 제어.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _showSummaryOnApply = !_showSummaryOnApply);
                    _savePrefs();
                  },
                  child: Row(
                    children: [
                      Icon(
                        (_isManage ? _showSummaryOnApply : !_showSummaryOnApply)
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 22,
                        color: (_isManage
                                ? _showSummaryOnApply
                                : !_showSummaryOnApply)
                            ? AppColors.carrot
                            : AppColors.gray300,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isManage
                              ? s.smsShowSummaryOnApply
                              : s.smsDontShowAgain,
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.gray600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 관리 모드 요약본은 하단 버튼 없음(우상단 수정 + 뒤로가기로 충분).
          if (!_isManage)
            _BottomBar(
              label: s.smsContinueButton,
              enabled: true,
              onTap: _confirm,
            ),
        ],
      ),
    );
  }

  /// 항목별 (라벨, 선택값) 요약 — 사용자 언어 칩 라벨 재사용.
  List<(String, String)> _summaryRows(AppStrings s) {
    final rows = <(String, String)>[];
    final korean = _koreanText(s);
    if (korean != null) rows.add((s.smsKoreanLevelLabel, korean));
    final exp = _expText(s);
    if (exp != null) rows.add((s.smsExperienceLabel, exp));
    final stay = _stayText(s);
    if (stay != null) rows.add((s.smsKoreaStayLabel, stay));
    if (_isStudent) {
      final st = _studentText(s);
      if (st != null) rows.add((s.smsStudentLabel, st));
    }
    final days = _daysText(s);
    if (days != null) rows.add((s.smsWorkDaysLabel, days));
    final times = _timesText(s);
    if (times != null) rows.add((s.smsWorkTimeLabel, times));
    final start = _startText(s);
    if (start != null) rows.add((s.smsStartDateLabel, start));
    return rows;
  }

  String? _koreanText(AppStrings s) {
    switch (_korean) {
      case KoreanLevel.fluent:
        return s.smsKoreanFluent;
      case KoreanLevel.conversational:
        return s.smsKoreanConversational;
      case KoreanLevel.basic:
        return s.smsKoreanBasic;
      case KoreanLevel.learning:
        return s.smsKoreanLearning;
      case null:
        return null;
    }
  }

  String? _expText(AppStrings s) {
    switch (_exp) {
      case ExperienceLevel.none:
        return s.smsExpNone;
      case ExperienceLevel.under1y:
        return s.smsExpUnder1y;
      case ExperienceLevel.oneToThree:
        return s.smsExpOneToThree;
      case ExperienceLevel.overThree:
        return s.smsExpOverThree;
      case null:
        return null;
    }
  }

  String? _stayText(AppStrings s) {
    switch (_koreaStay) {
      case KoreaStay.under1y:
        return s.smsStayUnder1y;
      case KoreaStay.oneToThree:
        return s.smsStayOneToThree;
      case KoreaStay.overThree:
        return s.smsStayOverThree;
      case null:
        return null;
    }
  }

  String? _studentText(AppStrings s) {
    switch (_student) {
      case StudentStatus.enrolled:
        return s.smsStudentEnrolled;
      case StudentStatus.onLeave:
        return s.smsStudentOnLeave;
      case null:
        return null;
    }
  }

  String? _daysText(AppStrings s) {
    if (_daysMatch) return s.smsMatchPosting;
    if (_daysNego) return s.smsNegotiable;
    if (_days.isEmpty) return null;
    final sorted = _days.toList()..sort((a, b) => a.index.compareTo(b.index));
    return sorted.map((w) => _weekdayLabel(s, w)).join(', ');
  }

  String? _timesText(AppStrings s) {
    if (_timesMatch) return s.smsMatchPosting;
    if (_timesNego) return s.smsNegotiable;
    if (_times.isEmpty) return null;
    final sorted = _times.toList()..sort((a, b) => a.index.compareTo(b.index));
    return sorted.map((t) => _dayPartText(s, t)).join(', ');
  }

  String _dayPartText(AppStrings s, DayPart t) {
    switch (t) {
      case DayPart.morning:
        return s.smsTimeMorning;
      case DayPart.afternoon:
        return s.smsTimeAfternoon;
      case DayPart.evening:
        return s.smsTimeEvening;
      case DayPart.night:
        return s.smsTimeNight;
    }
  }

  String? _startText(AppStrings s) {
    switch (_start) {
      case StartDate.immediate:
        return s.smsStartImmediate;
      case StartDate.withinWeek:
        return s.smsStartWithinWeek;
      case StartDate.negotiable:
        return s.smsNegotiable;
      case null:
        return null;
    }
  }

  Widget _buildMainMode(AppStrings s) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.black,
        centerTitle: true,
        leading: _smsBackButton(context),
        title: Text(_screenTitle(s),
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.black)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // 안내 영역 — 연한 박스로 묶어 아래 입력 항목과 구분.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.carrotLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.smsComposeTitle,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carrotDark)),
                      const SizedBox(height: 3),
                      Text(s.smsComposeDesc,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: AppColors.carrotDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ..._chipSections(s, lang),
                const SizedBox(height: 8),
                _PreviewBox(
                  message: _message,
                  previewLabel: s.smsPreviewLabel,
                  koreanNote: s.smsPreviewKoreanNote,
                  onEdit: _openTextEditor,
                  editLabel: s.smsEditOnKhire,
                ),
              ],
            ),
          ),
          _BottomBar(
            label: s.jobMemoSave,
            enabled: _canContinue,
            onTap: _saveAndShowSummary,
          ),
        ],
      ),
    );
  }

  List<Widget> _chipSections(AppStrings s, String lang) {
    final postingSchedule = widget.job?.getWorkSchedule(lang) ?? '';
    final postingTime = widget.job?.displayWorkTime ?? '';
    return [
      _ChipGroup(
        label: s.smsKoreanLevelLabel,
        chips: [
          _chip(s.smsKoreanFluent, _korean == KoreanLevel.fluent,
              () => _setKorean(KoreanLevel.fluent)),
          _chip(s.smsKoreanConversational, _korean == KoreanLevel.conversational,
              () => _setKorean(KoreanLevel.conversational)),
          _chip(s.smsKoreanBasic, _korean == KoreanLevel.basic,
              () => _setKorean(KoreanLevel.basic)),
          _chip(s.smsKoreanLearning, _korean == KoreanLevel.learning,
              () => _setKorean(KoreanLevel.learning)),
        ],
      ),
      _ChipGroup(
        label: s.smsExperienceLabel,
        chips: [
          _chip(s.smsExpNone, _exp == ExperienceLevel.none,
              () => _setExp(ExperienceLevel.none)),
          _chip(s.smsExpUnder1y, _exp == ExperienceLevel.under1y,
              () => _setExp(ExperienceLevel.under1y)),
          _chip(s.smsExpOneToThree, _exp == ExperienceLevel.oneToThree,
              () => _setExp(ExperienceLevel.oneToThree)),
          _chip(s.smsExpOverThree, _exp == ExperienceLevel.overThree,
              () => _setExp(ExperienceLevel.overThree)),
        ],
      ),
      _ChipGroup(
        label: s.smsKoreaStayLabel,
        optionalLabel: s.smsOptional,
        chips: [
          _chip(s.smsStayUnder1y, _koreaStay == KoreaStay.under1y,
              () => _setKoreaStay(KoreaStay.under1y)),
          _chip(s.smsStayOneToThree, _koreaStay == KoreaStay.oneToThree,
              () => _setKoreaStay(KoreaStay.oneToThree)),
          _chip(s.smsStayOverThree, _koreaStay == KoreaStay.overThree,
              () => _setKoreaStay(KoreaStay.overThree)),
        ],
      ),
      _ChipGroup(
        label: s.smsWorkDaysLabel,
        postingInfo: postingSchedule.isNotEmpty
            ? '${s.smsPostingLabel} · $postingSchedule'
            : null,
        chips: [
          for (final w in Weekday.values)
            _chip(_weekdayLabel(s, w), !_daysNego && !_daysMatch && _days.contains(w),
                () => _toggleDay(w)),
          _chip(s.smsMatchPosting, _daysMatch, _toggleDaysMatch),
          _chip(s.smsNegotiable, _daysNego, _toggleDaysNego),
        ],
      ),
      _ChipGroup(
        label: s.smsWorkTimeLabel,
        postingInfo: postingTime.isNotEmpty
            ? '${s.smsPostingLabel} · $postingTime'
            : null,
        chips: [
          _chip(s.smsTimeMorning,
              !_timesNego && !_timesMatch && _times.contains(DayPart.morning),
              () => _toggleTime(DayPart.morning)),
          _chip(s.smsTimeAfternoon,
              !_timesNego && !_timesMatch && _times.contains(DayPart.afternoon),
              () => _toggleTime(DayPart.afternoon)),
          _chip(s.smsTimeEvening,
              !_timesNego && !_timesMatch && _times.contains(DayPart.evening),
              () => _toggleTime(DayPart.evening)),
          _chip(s.smsTimeNight,
              !_timesNego && !_timesMatch && _times.contains(DayPart.night),
              () => _toggleTime(DayPart.night)),
          _chip(s.smsMatchPosting, _timesMatch, _toggleTimesMatch),
          _chip(s.smsNegotiable, _timesNego, _toggleTimesNego),
        ],
      ),
      _ChipGroup(
        label: s.smsStartDateLabel,
        chips: [
          _chip(s.smsStartImmediate, _start == StartDate.immediate,
              () => _setStart(StartDate.immediate)),
          _chip(s.smsStartWithinWeek, _start == StartDate.withinWeek,
              () => _setStart(StartDate.withinWeek)),
          _chip(s.smsNegotiable, _start == StartDate.negotiable,
              () => _setStart(StartDate.negotiable)),
        ],
      ),
      // 학생 여부(선택) — 맨 마지막. 체크 시에만 재학/휴학 선택 노출.
      _StudentSection(
        label: s.smsStudentLabel,
        optionalLabel: s.smsOptional,
        checked: _isStudent,
        onToggle: _toggleStudentCheck,
        status: _student,
        enrolledLabel: s.smsStudentEnrolled,
        onLeaveLabel: s.smsStudentOnLeave,
        onSelect: _setStudent,
      ),
    ];
  }

  String _weekdayLabel(AppStrings s, Weekday w) {
    switch (w) {
      case Weekday.mon:
        return s.smsMon;
      case Weekday.tue:
        return s.smsTue;
      case Weekday.wed:
        return s.smsWed;
      case Weekday.thu:
        return s.smsThu;
      case Weekday.fri:
        return s.smsFri;
      case Weekday.sat:
        return s.smsSat;
      case Weekday.sun:
        return s.smsSun;
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      _SelectChip(label: label, selected: selected, onTap: onTap);

  void _setKorean(KoreanLevel v) => setState(() {
        _onChipTouched();
        _korean = _korean == v ? null : v;
      });
  void _setExp(ExperienceLevel v) => setState(() {
        _onChipTouched();
        _exp = _exp == v ? null : v;
      });
  void _toggleStudentCheck() => setState(() {
        _onChipTouched();
        _isStudent = !_isStudent;
        if (!_isStudent) _student = null; // 체크 해제 시 하위 선택 초기화
      });
  void _setStudent(StudentStatus v) => setState(() {
        _onChipTouched();
        _student = _student == v ? null : v;
      });
  void _setKoreaStay(KoreaStay v) => setState(() {
        _onChipTouched();
        _koreaStay = _koreaStay == v ? null : v;
      });
  void _setStart(StartDate v) => setState(() {
        _onChipTouched();
        _start = _start == v ? null : v;
      });

  void _toggleDay(Weekday w) {
    setState(() {
      _onChipTouched();
      _daysNego = false;
      _daysMatch = false;
      _days.contains(w) ? _days.remove(w) : _days.add(w);
    });
  }

  void _toggleDaysNego() {
    setState(() {
      _onChipTouched();
      _daysNego = !_daysNego;
      if (_daysNego) {
        _days.clear();
        _daysMatch = false;
      }
    });
  }

  void _toggleDaysMatch() {
    setState(() {
      _onChipTouched();
      _daysMatch = !_daysMatch;
      if (_daysMatch) {
        _days.clear();
        _daysNego = false;
      }
    });
  }

  void _toggleTime(DayPart p) {
    setState(() {
      _onChipTouched();
      _timesNego = false;
      _timesMatch = false;
      _times.contains(p) ? _times.remove(p) : _times.add(p);
    });
  }

  void _toggleTimesNego() {
    setState(() {
      _onChipTouched();
      _timesNego = !_timesNego;
      if (_timesNego) {
        _times.clear();
        _timesMatch = false;
      }
    });
  }

  void _toggleTimesMatch() {
    setState(() {
      _onChipTouched();
      _timesMatch = !_timesMatch;
      if (_timesMatch) {
        _times.clear();
        _timesNego = false;
      }
    });
  }
}

/// 미리보기 직접 편집 전용 화면 — 별도 라우트(스와이프백=취소), 하단 "저장".
class _SmsTextEditScreen extends StatefulWidget {
  final String initial;
  final String title;
  final String koreanNote;
  final String saveLabel;
  const _SmsTextEditScreen({
    required this.initial,
    required this.title,
    required this.koreanNote,
    required this.saveLabel,
  });

  @override
  State<_SmsTextEditScreen> createState() => _SmsTextEditScreenState();
}

class _SmsTextEditScreenState extends State<_SmsTextEditScreen> {
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
        foregroundColor: AppColors.black,
        centerTitle: true,
        leading: _smsBackButton(context),
        title: Text(widget.title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.black)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.koreanNote,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray400)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      maxLength: kSmsMessageMaxLength,
                      autofocus: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.gray50,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.gray100),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.gray100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.carrot),
                        ),
                      ),
                      style: const TextStyle(
                          fontSize: 15, height: 1.5, color: AppColors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(
            label: widget.saveLabel,
            enabled: true,
            onTap: () => Navigator.of(context).pop(_ctrl.text),
          ),
        ],
      ),
    );
  }
}

/// 학생 여부(선택) — 체크박스 + 체크 시 재학/휴학 칩.
class _StudentSection extends StatelessWidget {
  final String label;
  final String optionalLabel;
  final bool checked;
  final VoidCallback onToggle;
  final StudentStatus? status;
  final String enrolledLabel;
  final String onLeaveLabel;
  final void Function(StudentStatus) onSelect;
  const _StudentSection({
    required this.label,
    required this.optionalLabel,
    required this.checked,
    required this.onToggle,
    required this.status,
    required this.enrolledLabel,
    required this.onLeaveLabel,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: [
                Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 22,
                  color: checked ? AppColors.carrot : AppColors.gray300,
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900)),
                const SizedBox(width: 6),
                Text(optionalLabel,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.gray400)),
              ],
            ),
          ),
          if (checked) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _SelectChip(
                  label: enrolledLabel,
                  selected: status == StudentStatus.enrolled,
                  onTap: () => onSelect(StudentStatus.enrolled)),
              _SelectChip(
                  label: onLeaveLabel,
                  selected: status == StudentStatus.onLeave,
                  onTap: () => onSelect(StudentStatus.onLeave)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final String label;
  final String? postingInfo;
  final String? optionalLabel; // "(선택)" 등 — 필수 아님 표시
  final List<Widget> chips;
  const _ChipGroup(
      {required this.label,
      this.postingInfo,
      this.optionalLabel,
      required this.chips});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900)),
              if (optionalLabel != null) ...[
                const SizedBox(width: 6),
                Text(optionalLabel!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray400)),
              ],
              if (postingInfo != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(postingInfo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray400)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // 필터 화면 칩과 동일 — 선택 시 연주황(carrotLight), 테두리 없음.
          color: selected ? AppColors.carrotLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.gray100,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.carrotDark : AppColors.gray600)),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final String message;
  final String previewLabel;
  final String koreanNote;
  final VoidCallback onEdit;
  final String editLabel;
  const _PreviewBox({
    required this.message,
    required this.previewLabel,
    required this.koreanNote,
    required this.onEdit,
    required this.editLabel,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Text(previewLabel,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(koreanNote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray400)),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              label: Text(editLabel),
              style: TextButton.styleFrom(foregroundColor: AppColors.carrot),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Text(message,
              style: const TextStyle(
                  fontSize: 15, height: 1.5, color: AppColors.black)),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text('${message.characters.length}/$kSmsMessageMaxLength',
              style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _BottomBar(
      {required this.label, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.carrot,
              disabledBackgroundColor: AppColors.gray200,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(label,
                maxLines: 1,
                // 한글 받침 세로 잘림 방지(2026-10-05 캡처).
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
          ),
        ),
      ),
    );
  }
}
