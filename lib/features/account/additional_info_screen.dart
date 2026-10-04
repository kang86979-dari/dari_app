import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/district_names.dart';
import '../../core/utils/region_mapper.dart';
import '../../core/widgets/info_row.dart';
import '../apply/sms/khire_jit_sheet.dart' show showKhireListPicker;
import '../../data/services/khire_area_service.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../core/utils/flag_emoji.dart';
import '../../data/models/applicant_profile.dart';
import '../../providers/account_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/language_provider.dart';
import 'legal_document_screen.dart';
import 'nationality_select_screen.dart';
import 'visa_type_select_screen.dart';
import '../home/widgets/ad_banner.dart';
import 'widgets/account_app_bar.dart';

final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _hangulOnlyRegex = RegExp(r'^[가-힣\s]+$');
final _englishOnlyRegex = RegExp(r"^[A-Za-z\s'\-.]+$");

bool _isValidEmail(String value) => _emailRegex.hasMatch(value);

/// 한글만 또는 영어만 허용, 혼용·숫자·특수문자 금지 (여권·신분증 이름 표기 규칙에 맞춤).
bool _isMixedScript(String value) {
  if (value.isEmpty) return false;
  return !_hangulOnlyRegex.hasMatch(value) &&
      !_englishOnlyRegex.hasMatch(value);
}

bool _isValidBirthDate(String digits) {
  if (digits.length != 8) return false;
  final year = int.tryParse(digits.substring(0, 4));
  final month = int.tryParse(digits.substring(4, 6));
  final day = int.tryParse(digits.substring(6, 8));
  if (year == null || month == null || day == null) return false;
  if (year < 1900 || year > DateTime.now().year) return false;
  if (month < 1 || month > 12) return false;
  final daysInMonth = DateTime(year, month + 1, 0).day;
  if (day < 1 || day > daysInMonth) return false;
  return true;
}

/// 화면2: 추가정보 입력 (신규 가입자만). 소셜 인증 직후 등장.
/// 비자 발급일·만료일은 이번 단계 제외(추후 검토, docs/apply_signup_scenario_2026-09-19.md 참고).
class AdditionalInfoScreen extends ConsumerStatefulWidget {
  /// null = 신규 회원가입 흐름. 값이 있으면 마이페이지 "이력서 관리"에서 온 수정 모드.
  final ApplicantProfile? initialProfile;

  /// 신규 가입 흐름에서만 사용 — 소셜 인증 결과(임시 stub, SNS 연동 전).
  final String? snsProvider;
  final String? initialEmail;

  /// 요약본에서 "수정하기"로 들어온 경우 true — 요약 없이 바로 편집 폼.
  /// (별도 라우트로 push돼 스와이프백이 자연스럽게 요약본으로 돌아감)
  final bool startInEdit;

  const AdditionalInfoScreen({
    super.key,
    this.initialProfile,
    this.snsProvider,
    this.initialEmail,
    this.startInEdit = false,
  });

  @override
  ConsumerState<AdditionalInfoScreen> createState() =>
      _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends ConsumerState<AdditionalInfoScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  final _phoneController = TextEditingController();

  final _emailFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _birthFocus = FocusNode();
  final _phoneFocus = FocusNode();
  // 보이지 않는 포커스 흡수용 — 라우트 복귀 시 Flutter가 첫 텍스트필드(이메일)에
  // 자동으로 포커스를 주는 현상을 막기 위해 여기로 포커스를 돌림(2026-09-20).
  final _dummyFocus = FocusNode(debugLabel: 'focus_absorber');

  final _emailKey = GlobalKey();
  final _nameKey = GlobalKey();
  final _birthKey = GlobalKey();
  final _genderKey = GlobalKey();
  final _nationalityKey = GlobalKey();
  final _visaKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _consentKey = GlobalKey();

  String? _snsProvider;
  String? _gender;
  String? _nationalityCode;
  String? _nationalityLabel;
  String? _visaCode;
  String? _visaLabel;

  bool _termsChecked = false;
  bool _privacyChecked = false;
  bool _thirdPartyChecked = false;

  final Map<String, bool> _errors = {};

  bool get _isEditMode => widget.initialProfile != null;

  // 수정 모드(마이페이지 진입)는 요약본 먼저. startInEdit면 바로 편집 폼.
  // 수정은 별도 화면 push라 토글하지 않음(final).
  late final bool _showSummary =
      widget.initialProfile != null && !widget.startInEdit;

  // 주소(수정 모드 전용) — 시/구는 리스트 수정, 동은 시/구 변경 시 초기화.
  String? _addrSido;
  String? _addrSigungu;
  String? _addrDong;

  String _localSido(String si) {
    final lang = ref.read(languageProvider);
    if (lang == 'ko') return si;
    final en = RegionMapper.getLocalizedName(si, lang);
    return en == si ? si : '$en ($si)';
  }

  String _localGu(String gu) {
    final lang = ref.read(languageProvider);
    if (lang == 'ko') return gu;
    final en = DistrictNames.getLocalizedGuName(gu, _addrSido ?? '', lang);
    return en == gu ? gu : '$en ($gu)';
  }

  Future<void> _pickSido() async {
    final regions =
        await ref.read(jobRepositoryProvider).getAllRegionsPublic();
    if (!mounted) return;
    final seen = <String>{};
    final items = <String>[
      for (final r in regions)
        if (r['si_name'] != null && seen.add(r['si_name'] as String))
          r['si_name'] as String,
    ];
    final picked = await showKhireListPicker(context,
        title: '시/도', items: items, selected: _addrSido,
        display: _localSido);
    if (picked != null && mounted) {
      setState(() {
        _addrSido = picked;
        _addrSigungu = null;
        _addrDong = null; // 상위 변경 → 동 무효(다음 문자지원 때 재선택)
      });
    }
  }

  Future<void> _pickDong() async {
    if (_addrSido == null || _addrSigungu == null) return;
    final items =
        await KhireAreaService.dongList(_addrSido!, _addrSigungu!);
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(stringsProvider).accountSaveFailed),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final picked = await showKhireListPicker(context,
        title: '읍/면/동', items: items, selected: _addrDong);
    if (picked != null && mounted) setState(() => _addrDong = picked);
  }

  Future<void> _pickSigungu() async {
    if (_addrSido == null) return;
    final regions =
        await ref.read(jobRepositoryProvider).getAllRegionsPublic();
    if (!mounted) return;
    final items = <String>[
      for (final r in regions)
        if (r['si_name'] == _addrSido &&
            (r['gu_name'] as String?)?.isNotEmpty == true)
          r['gu_name'] as String,
    ];
    final picked = await showKhireListPicker(context,
        title: '시/군/구', items: items, selected: _addrSigungu,
        display: _localGu);
    if (picked != null && mounted) {
      setState(() {
        _addrSigungu = picked;
        _addrDong = null; // 구 변경 → 동 무효
      });
    }
  }

  // 포커스가 필드 간 이동할 때 키패드 액세서리 바(Done/Next 구성)를 갱신.
  void _onFocusChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    for (final f in [_emailFocus, _nameFocus, _birthFocus, _phoneFocus]) {
      f.addListener(_onFocusChange);
    }
    final p = widget.initialProfile;
    if (p != null) {
      _snsProvider = p.snsProvider;
      _emailController.text = p.email;
      // 대문자 정책 이전에 저장된 프로필도 표시·재저장 시 대문자로 통일.
      _nameController.text = p.name.toUpperCase();
      _birthController.text = p.birthDate;
      _phoneController.text = p.phone;
      _gender = p.gender;
      _nationalityCode = p.nationalityCode;
      _nationalityLabel = p.nationalityLabel;
      _visaCode = p.visaCode;
      _visaLabel = p.visaLabel;
      _addrSido = p.addrSido;
      _addrSigungu = p.addrSigungu;
      _addrDong = p.addrDong;
    } else {
      _snsProvider = widget.snsProvider;
      _emailController.text = widget.initialEmail ?? '';
      // 이름은 자동 세팅하지 않음 — 여권·신분증 이름과 다를 수 있어 사용자가 직접 입력.
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    _emailFocus.dispose();
    _nameFocus.dispose();
    _birthFocus.dispose();
    _phoneFocus.dispose();
    _dummyFocus.dispose();
    super.dispose();
  }

  bool get _allConsented =>
      _termsChecked && _privacyChecked && _thirdPartyChecked;

  void _setAllConsent(bool value) {
    setState(() {
      _termsChecked = value;
      _privacyChecked = value;
      _thirdPartyChecked = value;
      if (value) _errors['consent'] = false;
    });
  }

  // 다른 입력필드에 포커스(키보드)가 떠 있는 채로 선택 필드를 탭하면 키보드가
  // 안 닫히고, 그 상태로 화면을 이동했다 돌아오면 플러터가 엉뚱한 필드에
  // 포커스를 넘겨버림 — 이동 직전에 더미 노드로 포커스를 미리 뺏어와서
  // 키보드를 즉시 닫고, 이동 중엔 어떤 실제 필드도 포커스를 갖지 않게 함
  // (2026-09-20 실기기 확인).
  Future<void> _pickNationality() async {
    _dummyFocus.requestFocus();
    final result = await Navigator.of(context)
        .push<({String code, String label})>(
          MaterialPageRoute(
            builder: (_) =>
                NationalitySelectScreen(currentCode: _nationalityCode),
          ),
        );
    if (mounted) _dummyFocus.requestFocus();
    if (result != null) {
      setState(() {
        _nationalityCode = result.code;
        _nationalityLabel = result.label;
        _errors['nationality'] = false;
      });
    }
  }

  Future<void> _pickVisaType() async {
    _dummyFocus.requestFocus();
    final result = await showVisaTypeSheet(context, currentCode: _visaCode);
    if (mounted) _dummyFocus.requestFocus();
    if (result != null) {
      setState(() {
        _visaCode = result.code;
        _visaLabel = result.label;
        _errors['visa'] = false;
      });
    }
  }

  Future<void> _openLegal(String title, String body) async {
    _dummyFocus.requestFocus();
    await showLegalDocument(
      context,
      title: title,
      body: body,
      draftNotice: ref.read(stringsProvider).legalDraftNotice,
    );
    if (mounted) _dummyFocus.requestFocus();
  }

  void _scrollAndFocus(GlobalKey key, FocusNode? focus) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    }
    focus?.requestFocus();
  }

  /// 프로필 비자코드(예: E-9)를 홈 비자 필터에 추가 — 이미 선택돼 있으면 그대로.
  /// visaOptions의 label이 비자 코드라 코드 매칭으로 id를 찾는다.
  Future<void> _applyVisaToFilter(String visaCode) async {
    if (visaCode.isEmpty) return;
    try {
      final options = await ref.read(visaOptionsProvider.future);
      String? visaId;
      for (final o in options) {
        if (o.label == visaCode) {
          visaId = o.id;
          break;
        }
      }
      if (visaId == null) return;
      final fs = ref.read(filterStateProvider);
      if (!fs.visaIds.contains(visaId)) {
        ref.read(filterStateProvider.notifier).toggleVisa(visaId);
      }
    } catch (_) {
      // 옵션 로드 실패 등 — 자동설정은 부가기능이라 조용히 무시.
    }
  }

  Future<void> _onComplete() async {
    FocusScope.of(context).unfocus();
    final errors = {
      'email':
          _emailController.text.trim().isEmpty ||
          !_isValidEmail(_emailController.text.trim()),
      'name':
          _nameController.text.trim().isEmpty ||
          _isMixedScript(_nameController.text.trim()),
      'birth': !_isValidBirthDate(_birthController.text.trim()),
      'gender': _gender == null,
      'nationality': _nationalityCode == null,
      'visa': _visaCode == null,
      'phone':
          _phoneController.text.trim().isEmpty ||
          !_phoneController.text.trim().startsWith('010'),
      // 수정 모드는 약관 동의 UI 자체가 없으므로 검증에서도 제외.
      'consent': !_isEditMode && !_allConsented,
    };
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });

    // 포커스 이동 순서 = 화면 상단부터
    const order = [
      'email',
      'name',
      'birth',
      'gender',
      'nationality',
      'visa',
      'phone',
      'consent',
    ];
    for (final key in order) {
      if (errors[key] == true) {
        final targetKey = switch (key) {
          'email' => _emailKey,
          'name' => _nameKey,
          'birth' => _birthKey,
          'gender' => _genderKey,
          'nationality' => _nationalityKey,
          'visa' => _visaKey,
          'phone' => _phoneKey,
          _ => _consentKey,
        };
        final focus = switch (key) {
          'email' => _emailFocus,
          'name' => _nameFocus,
          'birth' => _birthFocus,
          'phone' => _phoneFocus,
          _ => null,
        };
        _scrollAndFocus(targetKey, focus);
        return;
      }
    }

    // 전부 통과 → 회원가입 성공 → 자동 로그인
    final profile = ApplicantProfile(
      snsProvider: _snsProvider ?? '',
      email: _emailController.text.trim(),
      name: _nameController.text.trim().toUpperCase(),
      birthDate: _birthController.text.trim(),
      gender: _gender!,
      nationalityCode: _nationalityCode!,
      nationalityLabel: _nationalityLabel!,
      visaCode: _visaCode!,
      visaLabel: _visaLabel!,
      phone: _phoneController.text.trim(),
    );
    // 서버 저장(applicant_profiles upsert)이 성공해야 완료 — 실패하면 화면에
    // 남아서 재시도 가능(2026-09-24 서버 저장 전환).
    try {
      await ref.read(accountProvider.notifier).completeSignup(profile);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).accountSaveFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    // 수정 모드: 주소 변경분 저장(completeSignup upsert엔 주소 미포함 — 분리 저장).
    final oldP = widget.initialProfile;
    if (_isEditMode &&
        (oldP?.addrSido != _addrSido ||
            oldP?.addrSigungu != _addrSigungu ||
            oldP?.addrDong != _addrDong)) {
      await ref.read(accountProvider.notifier).saveSmsFields(
            addrSido: _addrSido,
            addrSigungu: _addrSigungu,
            addrDong: _addrDong,
          );
    } else if (_isEditMode) {
      // completeSignup이 로컬 상태를 주소 없는 객체로 교체하므로 서버값으로
      // 복원 — 주소가 화면에서 사라지던 버그 수정(2026-10-04).
      await ref.read(accountProvider.notifier).refreshFromServer();
    }
    if (!mounted) return;
    // 신규 가입 1회: 프로필 비자를 홈 필터에 자동 반영(필터에 없을 때만) —
    // 가입하면 바로 본인 비자 공고가 보이도록(2026-10-04). 수정 모드는 제외.
    if (!_isEditMode) await _applyVisaToFilter(profile.visaCode);
    if (!mounted) return;
    if (!_isEditMode) HapticFeedback.mediumImpact(); // 가입 완료(2026-09-26)
    // 완료 토스트 — ScaffoldMessenger는 앱 루트 소속이라 pop 후에도 이전 화면
    // 위에 정상 표시됨. 신규 가입은 항상, 수정 모드는 실제 변경이 있을 때만.
    // 이름은 저장 시 대문자로 통일되므로 기존값도 대문자로 맞춰 비교(대문자
    // 정책 이전 프로필이 정책 적용만으로 "수정됨" 처리되지 않게).
    final old = widget.initialProfile;
    final edited =
        old != null &&
        (profile.email != old.email ||
            profile.name != old.name.toUpperCase() ||
            profile.birthDate != old.birthDate ||
            profile.gender != old.gender ||
            profile.nationalityCode != old.nationalityCode ||
            profile.visaCode != old.visaCode ||
            profile.phone != old.phone);
    if (!_isEditMode || edited) {
      final s = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? s.accountProfileUpdatedToast
                : s.accountSignupDoneToast,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  /// 개인정보 요약본 — 설정 리스트형(B안): 라벨 왼쪽 회색 / 값 오른쪽 굵은 검정.
  Widget _buildSummary(dynamic s) {
    // 저장 후 돌아와도 최신값 반영되게 provider를 watch(없으면 push 당시 값).
    final p = ref.watch(accountProvider).profile ?? widget.initialProfile!;
    final rows = <(String, String)>[
      // 가입 방법 최상단(2026-10-04 사용자 확정)
      if (p.snsProvider.isNotEmpty)
        (
          s.accountLabelLoginType,
          p.snsProvider[0].toUpperCase() + p.snsProvider.substring(1)
        ),
      (s.accountLabelName, p.name),
      (s.accountFieldEmail, p.email),
      (s.accountLabelBirthDate, _fmtBirth(p.birthDate)),
      (
        s.accountFieldGender,
        p.gender == 'female' ? s.accountGenderFemale : s.accountGenderMale
      ),
      (s.accountFieldNationality, p.nationalityLabel),
      (s.accountFieldVisaType, p.visaLabel),
      (s.accountFieldPhone, p.phone),
      if ((p.addrSido ?? '').isNotEmpty)
        (
          s.smsAddressLabel,
          [p.addrSido, p.addrSigungu, p.addrDong]
              .where((e) => e != null && e.isNotEmpty)
              .join(' ')
        ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AccountAppBar(
              title: s.accountProfileTitle,
              // SMS 요약본과 동일한 텍스트 버튼(통일) — 타이틀은 AppBar가
              // Stack 중앙 배치라 버튼 폭과 무관하게 정중앙.
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdditionalInfoScreen(
                      initialProfile: p,
                      startInEdit: true,
                    ),
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.carrot),
                child: Text(s.smsEditOnKhire,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const AdBanner(),
                  const SizedBox(height: 8),
                  // 공고 상세 테이블과 동일 스타일(InfoRow 공용 위젯)로 통일.
                  for (var i = 0; i < rows.length; i++)
                    InfoRow(
                      label: rows[i].$1,
                      value: rows[i].$2,
                      isLast: i == rows.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// YYYYMMDD → YYYY.MM.DD (8자리 아니면 원본).
  String _fmtBirth(String b) {
    if (b.length != 8) return b;
    return '${b.substring(0, 4)}.${b.substring(4, 6)}.${b.substring(6, 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    // 수정 모드: 요약본 먼저. 우측 상단 수정하기 → 편집 폼.
    if (_showSummary) return _buildSummary(s);

    // 헬프 문구(경고)와 테두리 색(hasError)을 완전히 동기화 — Done을 누르기
    // 전이라도 실시간으로 값이 유효하지 않으면 테두리도 바로 빨간색이 되고,
    // 포커스가 빠져도 유효해지기 전까지는 계속 빨간색을 유지함(2026-09-20).
    final emailInvalid =
        _emailController.text.isNotEmpty &&
        !_isValidEmail(_emailController.text);
    final nameInvalid = _isMixedScript(_nameController.text);
    final birthInvalid =
        _birthController.text.length == 8 &&
        !_isValidBirthDate(_birthController.text);
    final phoneInvalid =
        _phoneController.text.length >= 3 &&
        !_phoneController.text.startsWith('010');

    // 생년월일은 8자리를 다 채워야 검증 가능하므로, 입력 중(1~7자리)에는
    // 에러가 아니라 회색 "n/8" 진행 카운터를 보여주고, Done을 눌렀는데
    // 아직 미완성/무효인 경우에만 빨간 에러로 전환함(2026-09-20).
    final birthLen = _birthController.text.length;
    final birthHasError = _errors['birth'] == true || birthInvalid;
    final String? birthHelperText;
    final Color birthHelperColor;
    final double birthHelperLeftPadding;
    if (birthHasError) {
      // 에러 문구는 다른 필드 경고와 성격이 같으므로 라벨 기준(좌측 0) 정렬.
      birthHelperText = s.accountBirthDateInvalid;
      birthHelperColor = AppColors.urgent;
      birthHelperLeftPadding = 0;
    } else if (birthLen > 0 && birthLen < 8) {
      // 진행 카운터는 입력 중인 숫자와 시각적으로 이어지도록 입력 텍스트
      // 시작 위치(contentPadding과 동일한 좌측 12) 기준 정렬(2026-09-20).
      birthHelperText = '$birthLen/8';
      birthHelperColor = AppColors.gray400;
      birthHelperLeftPadding = 12;
    } else {
      birthHelperText = null;
      birthHelperColor = AppColors.urgent;
      birthHelperLeftPadding = 0;
    }

    // 키보드가 떠 있는 동안은 Done 버튼을 숨김(B안, 2026-09-24). Scaffold의
    // 기본 화면 축소(resizeToAvoidBottomInset)는 그대로 둬야 포커스된 필드가
    // 키패드 위로 자동 스크롤됨 — resize를 끄면 필드가 키패드에 가려짐(실기기
    // 확인). 이 폼은 약관 체크까지 스크롤해야 완료라 입력 중 Done은 불필요.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // 키패드 액세서리 바 구성 — 현재 포커스된 텍스트필드 기준으로 다음 필드가
    // 있으면 [Done|Next], 없으면 [Done]만. 이메일→이름→생년월일 순서는 키패드
    // 리턴 키(TextInputAction) 체인과 동일하게 유지. 생년월일·전화번호는 다음이
    // 텍스트필드가 아니라서 Next 없음 — iOS 숫자 키패드는 리턴 키 자체가 없어
    // 이 바의 Done이 키보드를 내리는 유일한 수단(2026-09-24).
    FocusNode? focusedField;
    for (final f in [_emailFocus, _nameFocus, _birthFocus, _phoneFocus]) {
      if (f.hasFocus) {
        focusedField = f;
        break;
      }
    }
    final FocusNode? nextField = focusedField == _emailFocus
        ? _nameFocus
        : focusedField == _nameFocus
        ? _birthFocus
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Focus(focusNode: _dummyFocus, child: const SizedBox.shrink()),
            AccountAppBar(
              title: _isEditMode
                  ? s.accountEditProfileTitle
                  : s.accountAdditionalInfoTitle,
            ),
            Expanded(
              // 배경 탭 시 키보드 내림 — Done 버튼과는 별개 영역(형제)으로 둬서
              // 포커스가 남아있는 채로 Done을 눌러도 이 제스처가 탭을 가로채
              // _onComplete가 실행 안 되던 버그 수정(2026-09-20 실기기 확인).
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  children: [
                    // 광고는 요약본 상단으로 이동(2026-10-04). 수정 폼엔 없음.
                    // 신규 가입 흐름에는 광고를 넣지 않음(온보딩 무광고 정책).
                    if (!_isEditMode) ...[
                      Text(
                        s.accountSignupBigTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    _TextField(
                      fieldKey: _emailKey,
                      label: s.accountFieldEmail,
                      controller: _emailController,
                      focusNode: _emailFocus,
                      placeholder: 'name@email.com',
                      keyboardType: TextInputType.emailAddress,
                      hasError: _errors['email'] == true || emailInvalid,
                      onChanged: (_) =>
                          setState(() => _errors['email'] = false),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(_nameFocus),
                      prefixIcon: _snsProvider == null || _snsProvider!.isEmpty
                          ? null
                          : _snsProviderIcon(_snsProvider!),
                      helperText: emailInvalid ? s.accountEmailInvalid : null,
                    ),
                    const SizedBox(height: 16),

                    _TextField(
                      fieldKey: _nameKey,
                      label: s.accountFieldName,
                      controller: _nameController,
                      focusNode: _nameFocus,
                      placeholder: s.accountNamePlaceholder,
                      // 여권 이름 표기에 맞춰 영문은 실시간 대문자 변환(한글 무영향).
                      inputFormatters: [_UpperCaseTextFormatter()],
                      hasError: _errors['name'] == true || nameInvalid,
                      onChanged: (_) => setState(() => _errors['name'] = false),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(_birthFocus),
                      helperText: nameInvalid ? s.accountNameMixedScript : null,
                    ),
                    const SizedBox(height: 16),

                    _TextField(
                      fieldKey: _birthKey,
                      label: s.accountFieldBirthDate,
                      controller: _birthController,
                      focusNode: _birthFocus,
                      placeholder: s.accountBirthDatePlaceholder,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      hasError: birthHasError,
                      onChanged: (_) =>
                          setState(() => _errors['birth'] = false),
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                      helperText: birthHelperText,
                      helperColor: birthHelperColor,
                      helperLeftPadding: birthHelperLeftPadding,
                    ),
                    const SizedBox(height: 16),

                    _GenderField(
                      fieldKey: _genderKey,
                      label: s.accountFieldGender,
                      maleLabel: s.accountGenderMale,
                      femaleLabel: s.accountGenderFemale,
                      value: _gender,
                      hasError: _errors['gender'] == true,
                      onChanged: (v) => setState(() {
                        _gender = v;
                        _errors['gender'] = false;
                      }),
                    ),
                    const SizedBox(height: 16),

                    _SelectField(
                      fieldKey: _nationalityKey,
                      label: s.accountFieldNationality,
                      value: _nationalityLabel,
                      placeholder: s.accountSelectHint,
                      hasError: _errors['nationality'] == true,
                      onTap: _pickNationality,
                      flagCode: _nationalityCode,
                    ),
                    const SizedBox(height: 16),

                    _SelectField(
                      fieldKey: _visaKey,
                      label: s.accountFieldVisaType,
                      value: _visaLabel,
                      placeholder: s.accountSelectHint,
                      hasError: _errors['visa'] == true,
                      onTap: _pickVisaType,
                    ),
                    const SizedBox(height: 16),

                    _TextField(
                      fieldKey: _phoneKey,
                      label: s.accountFieldPhone,
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      placeholder: '010-1234-5678',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_PhoneNumberFormatter()],
                      hasError: _errors['phone'] == true || phoneInvalid,
                      onChanged: (_) =>
                          setState(() => _errors['phone'] = false),
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                      helperText: phoneInvalid
                          ? s.accountPhoneMustStart010
                          : null,
                    ),

                    // 주소 — 수정 모드에서만(가입 땐 안 받음, just-in-time 정책).
                    // 시/도·시군구는 리스트 수정, 동은 시/구 변경 시 초기화되고
                    // 다음 문자지원 때 팝업으로 재선택(동 목록=K-HIRE 페이지에만 존재).
                    if (_isEditMode) ...[
                      const SizedBox(height: 16),
                      _FieldLabel(s.smsAddressLabel),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _AddrSelect(
                              value: _addrSido == null
                                  ? null
                                  : _localSido(_addrSido!),
                              hint: '시/도',
                              onTap: _pickSido,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _AddrSelect(
                              value: _addrSigungu == null
                                  ? null
                                  : _localGu(_addrSigungu!),
                              hint: '시/군/구',
                              onTap: _addrSido == null ? null : _pickSigungu,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _AddrSelect(
                        value: _addrDong,
                        hint: '읍/면/동',
                        onTap: _addrSigungu == null ? null : _pickDong,
                      ),
                    ],

                    // 약관 동의는 가입 시 1회로 충분 — 수정 모드에서는 숨김(2026-09-24).
                    if (!_isEditMode)
                      Container(
                        key: _consentKey,
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _errors['consent'] == true
                                ? AppColors.urgent
                                : AppColors.gray100,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ConsentRow(
                              label: s.accountConsentAll,
                              bold: true,
                              checked: _allConsented,
                              onChanged: _setAllConsent,
                            ),
                            const Divider(height: 20, color: AppColors.gray100),
                            _ConsentRow(
                              label: s.accountConsentTerms,
                              required: s.accountConsentRequired,
                              checked: _termsChecked,
                              onChanged: (v) => setState(() {
                                _termsChecked = v;
                                if (_allConsented) _errors['consent'] = false;
                              }),
                              viewLabel: s.accountConsentView,
                              onView: () => _openLegal(
                                s.accountConsentTerms,
                                s.legalTermsBody,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ConsentRow(
                              label: s.accountConsentPrivacy,
                              required: s.accountConsentRequired,
                              checked: _privacyChecked,
                              onChanged: (v) => setState(() {
                                _privacyChecked = v;
                                if (_allConsented) _errors['consent'] = false;
                              }),
                              viewLabel: s.accountConsentView,
                              onView: () => _openLegal(
                                s.accountConsentPrivacy,
                                s.legalPrivacyBody,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ConsentRow(
                              label: s.accountConsentThirdParty,
                              required: s.accountConsentRequired,
                              checked: _thirdPartyChecked,
                              onChanged: (v) => setState(() {
                                _thirdPartyChecked = v;
                                if (_allConsented) _errors['consent'] = false;
                              }),
                              viewLabel: s.accountConsentView,
                              onView: () => _openLegal(
                                s.accountConsentThirdParty,
                                s.legalThirdPartyBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (keyboardOpen)
              _KeyboardAccessoryBar(
                doneLabel: s.accountKeypadDone,
                nextLabel: s.accountKeypadNext,
                onDone: () => FocusScope.of(context).unfocus(),
                onNext: nextField == null
                    ? null
                    : () => FocusScope.of(context).requestFocus(nextField),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.carrot,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      s.accountComplete,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

/// 키패드 바로 위에 붙는 얇은 액세서리 바(2026-09-24, 토스식).
/// Next가 있으면 [Done ──── Next], 없으면 [──── Done]. 여기서 Done은
/// 가입 완료가 아니라 키보드만 내리는 역할 — 키보드가 내려가면 하단의
/// 진짜 완료 버튼이 다시 나타남.
class _KeyboardAccessoryBar extends StatelessWidget {
  final String doneLabel;
  final String nextLabel;
  final VoidCallback onDone;
  final VoidCallback? onNext;

  const _KeyboardAccessoryBar({
    required this.doneLabel,
    required this.nextLabel,
    required this.onDone,
    this.onNext,
  });

  Widget _barButton(String label, VoidCallback onTap, {required bool accent}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: accent ? FontWeight.w700 : FontWeight.w600,
            color: accent ? AppColors.carrot : AppColors.gray500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = _barButton(doneLabel, onDone, accent: onNext == null);
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        children: [
          if (onNext != null) ...[
            done,
            const Spacer(),
            _barButton(nextLabel, onNext!, accent: true),
          ] else ...[
            const Spacer(),
            done,
          ],
        ],
      ),
    );
  }
}

/// 구글/애플/페이스북 아이콘 (이메일 필드의 prefixIcon으로 사용).
Widget _snsProviderIcon(String provider) {
  return switch (provider) {
    'google' => SvgPicture.asset(
      'assets/brand/google_g.svg',
      width: 20,
      height: 20,
    ),
    'apple' => SvgPicture.asset(
      'assets/brand/apple.svg',
      width: 18,
      height: 18,
      colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
    ),
    _ => Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(3),
      child: SvgPicture.asset(
        'assets/brand/facebook_f.svg',
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    ),
  };
}

/// 영문을 실시간 대문자로 변환 (여권·신분증 이름 표기). 한글은 toUpperCase가
/// 항등이라 변화가 없을 때 원본을 그대로 반환해 IME 조합(composing)을 보존함.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(text: upper);
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    String formatted;
    if (limited.length <= 3) {
      formatted = limited;
    } else if (limited.length <= 7) {
      formatted = '${limited.substring(0, 3)}-${limited.substring(3)}';
    } else {
      formatted =
          '${limited.substring(0, 3)}-${limited.substring(3, 7)}-${limited.substring(7)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 주소 선택 행(수정 모드) — 탭하면 리스트 픽커.
class _AddrSelect extends StatelessWidget {
  final String? value;
  final String hint;
  final VoidCallback? onTap;
  const _AddrSelect({required this.value, required this.hint, this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.gray50 : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      value != null ? FontWeight.w700 : FontWeight.w500,
                  color: value != null ? AppColors.black : AppColors.gray400,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.gray500,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final GlobalKey fieldKey;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final bool hasError;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final String? helperText;
  final Color helperColor;
  final double helperLeftPadding;
  final Widget? prefixIcon;

  const _TextField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.hasError,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.textInputAction,
    this.onEditingComplete,
    this.helperText,
    this.helperColor = AppColors.urgent,
    this.helperLeftPadding = 0,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          cursorColor: hasError ? AppColors.urgent : AppColors.navy,
          style: const TextStyle(fontSize: 14.5, color: AppColors.black),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: AppColors.gray300),
            prefixIcon: prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: prefixIcon,
                  ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: AppColors.gray50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? AppColors.urgent : Colors.transparent,
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                // 에러(빨강)와 헷갈린다는 피드백으로 포커스 색을 carrot(주황)에서
                // navy(남색)로 변경(2026-09-20).
                color: hasError ? AppColors.urgent : AppColors.navy,
                width: 1.4,
              ),
            ),
          ),
        ),
        if (helperText != null)
          Padding(
            // 기본은 라벨(_FieldLabel, 좌측 패딩 0)과 시작점을 맞춤. 생년월일의
            // 진행 카운터처럼 입력 텍스트 위치와 이어져야 하는 경우에만
            // helperLeftPadding으로 12(=contentPadding)를 넘겨서 정렬 기준을
            // 바꿀 수 있음(2026-09-20).
            padding: EdgeInsets.fromLTRB(helperLeftPadding, 4, 12, 0),
            child: Text(
              helperText!,
              style: TextStyle(fontSize: 11.5, color: helperColor),
            ),
          ),
      ],
    );
  }
}

class _SelectField extends StatelessWidget {
  final GlobalKey fieldKey;
  final String label;
  final String? value;
  final String placeholder;
  final bool hasError;
  final VoidCallback onTap;
  final String? flagCode;

  const _SelectField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.hasError,
    required this.onTap,
    this.flagCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError ? AppColors.urgent : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                if (flagCode != null && value != null) ...[
                  Text(
                    flagEmoji(flagCode!),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: value != null
                          ? AppColors.black
                          : AppColors.gray300,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.gray300,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderField extends StatelessWidget {
  final GlobalKey fieldKey;
  final String label;
  final String maleLabel;
  final String femaleLabel;
  final String? value;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _GenderField({
    required this.fieldKey,
    required this.label,
    required this.maleLabel,
    required this.femaleLabel,
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? AppColors.urgent : AppColors.gray100,
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: _segment(maleLabel, 'male')),
              Container(width: 1, height: 20, color: AppColors.gray100),
              Expanded(child: _segment(femaleLabel, 'female')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segment(String label, String code) {
    final selected = value == code;
    return GestureDetector(
      onTap: () => onChanged(code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: selected ? AppColors.carrotLight : Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.carrot : AppColors.gray400,
          ),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  final String label;
  final String? required;
  final bool bold;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onView;
  final String? viewLabel;

  const _ConsentRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    this.required,
    this.bold = false,
    this.onView,
    this.viewLabel,
  });

  @override
  Widget build(BuildContext context) {
    // "보기" 링크는 체크박스 토글용 GestureDetector 밖에 형제로 둬야 함 —
    // 같은 영역에 탭 제스처 두 개를 중첩시키면 제스처 아레나 충돌로 안쪽(보기)이
    // 눌리지 않는 버그가 있었음(2026-09-20 실기기 확인).
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!checked),
            child: Row(
              children: [
                Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 20,
                  color: checked ? AppColors.carrot : AppColors.gray300,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: bold ? 13.5 : 12.5,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ),
                if (required != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    required!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.carrot,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (onView != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onView,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                viewLabel ?? '',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
