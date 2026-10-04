import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/apply_confirm_dialog.dart';
import '../../../data/models/applicant_profile.dart';
import '../../../data/models/job.dart';
import '../../../data/services/site_login_prefs.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/applied_job_provider.dart';
import '../../../providers/job_provider.dart';
import 'khire_jit_sheet.dart';

/// K-HIRE 전용 지원 웹뷰. 메시지 화면에서 조립한 문구를 TalkApply 폼에 주입하고,
/// 부족한 비자기간·주소는 폼 도착 시 just-in-time으로 받아 주입+프로필 저장한다.
///
/// 일반 지원 웹뷰(apply_webview_screen)와 분리 — K-HIRE 흐름 변경이
/// 다른 사이트에 영향 주지 않도록.
///
/// 상태머신(onLoadStop URL 기준):
///  - Login.asp     : 무동작 (사용자 로그인)
///  - 홈(/)         : TalkApply 미확보 시 공고 상세로 재이동 (로그인 후 홈 낙하 대응)
///  - JoinRegForm   : Dari 프로필 프리필 + 안내
///  - TalkApply.asp : 메시지·비자기간·주소 주입, gotoworkyn 체크
class KhireApplyWebViewScreen extends ConsumerStatefulWidget {
  final Job job;
  final String message;
  final bool wantsImmediateStart;
  final String langCode;

  const KhireApplyWebViewScreen({
    super.key,
    required this.job,
    required this.message,
    required this.wantsImmediateStart,
    required this.langCode,
  });

  @override
  ConsumerState<KhireApplyWebViewScreen> createState() =>
      _KhireApplyWebViewScreenState();
}

class _KhireApplyWebViewScreenState
    extends ConsumerState<KhireApplyWebViewScreen> {
  bool _injectedThisLoad = false;
  bool _jitHandled = false; // JIT 시트 중복 방지
  bool _recorded = false;
  bool _reachedTalkApply = false; // TalkApply 폼 도달 여부 — 닫기 팝업 조건
  int _autoClickCount = 0; // 상세에서 문자지원 자동 클릭 횟수(루프 방지)

  // 로그인 타입 감지 — OAuth 도메인 경유로 판별, 사이트별 저장(2026-10-04).
  String? _lastLoginType; // 저장돼 있던 지난 로그인 타입(배너용)
  String? _detectedOauth; // 이번 세션에서 감지된 OAuth 제공자
  bool _sawLoginPage = false;

  // [TEMP] 완료 URL 확보용 — 제출 후 이동 URL을 상단에 표시. 패턴 확정 후 제거.
  String _currentUrl = '';

  /// TalkApply 직행 URL — 상세 화면을 거치지 않아 깜빡임 제거(2026-10-04,
  /// 실기기 확보 패턴). adid는 공고 상세 URL에서 추출, 실패 시 상세로 폴백
  /// (상세 도착하면 자동클릭이 처리).
  String get _startUrl {
    final jobUrl = widget.job.url ?? '';
    final adid =
        RegExp(r'[?&]adid=(\d+)').firstMatch(jobUrl)?.group(1);
    if (adid != null) {
      return 'https://m.khire.co.kr/person/TalkApply.asp?adid=$adid&inflowtype=TALK';
    }
    return jobUrl.isNotEmpty ? jobUrl : 'https://m.khire.co.kr/';
  }

  // 폼(또는 로그인) 도착 전까지 로딩 오버레이 — 중간 화면 깜빡임 가림.
  bool _overlayVisible = true;

  @override
  void initState() {
    super.initState();
    SiteLoginPrefs.load('khire').then((v) {
      if (mounted && v != null) setState(() => _lastLoginType = v);
    });
    // 오버레이 안전장치 — 어떤 이유로든 15초 내 목적 화면 미도달 시 해제.
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _overlayVisible) setState(() => _overlayVisible = false);
    });
  }

  /// URL 호스트로 OAuth 제공자 판별. 해당 없으면 null.
  static String? _oauthProviderOf(String url) {
    final h = Uri.tryParse(url)?.host ?? '';
    if (h.contains('accounts.google')) return 'Google';
    if (h.contains('kakao')) return 'Kakao';
    if (h.contains('naver')) return 'Naver';
    if (h.contains('appleid.apple')) return 'Apple';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(widget.langCode);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onClose(s);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.black,
          title: Text(s.smsApplyTitle,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _onClose(s),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(28),
            child: _UrlStrip(
              url: _currentUrl,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: _currentUrl));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('URL 복사됨'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ),
        ),
        body: Column(
          children: [
            // 로그인 화면에서 지난 로그인 타입 안내(감지돼 저장된 경우만).
            if (_lastLoginType != null &&
                _currentUrl.toLowerCase().contains('login.asp'))
              Container(
                width: double.infinity,
                color: AppColors.carrotLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  s.smsLastLoginHint(_lastLoginType!),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.carrotDark),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_startUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: false,
            // K-HIRE가 로그인 등을 새 창으로 열어서(goInOutLink NEW_WINDOW)
            // 새 창 요청을 가로채 같은 웹뷰에서 연다.
            supportMultipleWindows: true,
            javaScriptCanOpenWindowsAutomatically: true,
          ),
          onWebViewCreated: (controller) {
            // 제출 버튼 클릭 감지 → 자동 지원 기록(2026-10-04).
            controller.addJavaScriptHandler(
              handlerName: 'dariSubmitted',
              callback: (_) => _onSubmitted(),
            );
          },
          onCreateWindow: (controller, action) async {
            final url = action.request.url;
            if (url != null) {
              controller.loadUrl(urlRequest: URLRequest(url: url));
            }
            return false; // 새 창 생성 안 함 — 같은 웹뷰에서 처리
          },
          onLoadStart: (_, url) {
            _injectedThisLoad = false;
            final u = url?.toString() ?? '';
            // 로그인 타입 감지: 로그인·가입 화면 경유 + OAuth 도메인 관찰.
            // 성공 이벤트를 따로 잡지 않음 — 이 화면들을 "통과해 TalkApply에
            // 도달"하면 성공으로 판정(실패하면 못 벗어나므로).
            final lu = u.toLowerCase();
            if (lu.contains('login.asp') || lu.contains('joinregform')) {
              _sawLoginPage = true;
            }
            final oauth = _oauthProviderOf(u);
            if (oauth != null) _detectedOauth = oauth;
            if (mounted) setState(() => _currentUrl = u);
          },
          onLoadStop: (controller, url) async {
            if (mounted) setState(() => _currentUrl = url?.toString() ?? '');
            await _onPageSettled(controller, url?.toString() ?? '');
          },
                  ),
                  // 폼/로그인 도착 전 중간 화면(상세·홈·NotFound) 가림 —
                  // 흰 화면만 있으면 버그처럼 보여 스피너+안내 문구 포함.
                  if (_overlayVisible)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.background,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: AppColors.carrot),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.smsLoadingSite,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray500),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPageSettled(
      InAppWebViewController controller, String url) async {
    if (_injectedThisLoad) return;
    final lower = url.toLowerCase();

    if (lower.contains('login.asp')) {
      if (_overlayVisible) setState(() => _overlayVisible = false);
      return; // 사용자 로그인 대기
    }
    // 직행 URL이 비로그인 상태면 NotFound로 떨어짐(2026-10-04 curl 확인)
    // → 공고 상세로 폴백(자동클릭 경로가 K-HIRE 로그인 confirm을 띄움).
    if (lower.contains('/error/notfound') && _autoClickCount == 0) {
      _injectedThisLoad = true;
      final jobUrl = widget.job.url;
      if (jobUrl != null && jobUrl.isNotEmpty) {
        await controller.loadUrl(urlRequest: URLRequest(url: WebUri(jobUrl)));
      }
      return;
    }
    if (lower.contains('joinregform')) {
      _injectedThisLoad = true;
      if (_overlayVisible) setState(() => _overlayVisible = false);
      await _prefillSignup(controller);
      return;
    }
    if (lower.contains('talkapply')) {
      _injectedThisLoad = true;
      _reachedTalkApply = true;
      // 폼 도착 — 오버레이 해제(유의사항 레이어는 사용자가 봐야 함).
      if (_overlayVisible) setState(() => _overlayVisible = false);
      // 로그인을 거쳐 도달 = 로그인 성공 — 타입 저장(OAuth 미경유면 자체 계정)
      if (_sawLoginPage) {
        final type = _detectedOauth ?? 'K-HIRE';
        SiteLoginPrefs.save('khire', type);
        _lastLoginType = type;
        _sawLoginPage = false;
      }
      await _injectTalkApply(controller);
      return;
    }
    // 공고 상세: K-HIRE 자체 문자지원 동작을 호출해 TalkApply로 진입 —
    // 사용자가 버튼을 직접 찾지 않아도 됨. 미로그인이면 K-HIRE가 로그인 유도.
    // (TalkApply 직접 URL은 로그인 세션에서만 렌더링돼 알 수 없음, 2026-10-04)
    if (lower.contains('jobdetail') && _autoClickCount < 3) {
      _injectedThisLoad = true;
      _autoClickCount++;
      await controller.evaluateJavascript(source: '''
(function(){
  try {
    if (window.JobDetailCLS && typeof JobDetailCLS.ApplicationTalkResume === 'function') {
      JobDetailCLS.ApplicationTalkResume();
    } else {
      var el = document.querySelector('.applyLayer__link--sms');
      if (el) el.click();
    }
  } catch(e){ console.log('dari talk auto-click error', e); }
})();
''');
      return;
    }
    // 홈/기타: 로그인 후 홈으로 떨어진 경우 공고 상세로 재이동
    if (_isHome(lower)) {
      _injectedThisLoad = true;
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(_startUrl)));
    }
  }

  bool _isHome(String lower) {
    final uri = Uri.tryParse(lower);
    if (uri == null) return false;
    if (!uri.host.contains('khire')) return false;
    final path = uri.path;
    return path.isEmpty || path == '/' || path.endsWith('/index.asp');
  }

  /// 유의사항 레이어(.guide-apply)가 떠 있으면 사용자가 확인을 누를 때까지 대기.
  /// 레이어 위로 추가정보 시트가 겹치지 않게(2026-10-04 사용자 지적).
  Future<void> _waitGuideDismissed(InAppWebViewController controller) async {
    for (var i = 0; i < 240; i++) {
      // 최대 2분
      if (!mounted) return;
      final visible = await controller.evaluateJavascript(source: '''
(function(){
  var g = document.querySelector('.guide-apply');
  if (!g) return false;
  var st = window.getComputedStyle(g);
  return st.display !== 'none' && st.visibility !== 'hidden' && g.offsetParent !== null;
})();
''');
      if (visible != true) return;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// TalkApply 처리 — **실제 폼 상태가 기준**(2026-10-04 확정):
  /// 폼에 이미 값이 있으면 절대 건드리지 않는다(K-HIRE 저장분과 비동기 가능).
  /// 1) 유의사항 닫힐 때까지 대기 → 2) 폼 상태 읽기 →
  /// 3) 메시지: 비었을 때만 주입 → 4) 비자일자: 비었고 프로필 값 있을 때만 주입
  /// (시트에선 안 물음 — K-HIRE 가입 시 입력 정보) →
  /// 5) 주소: 폼이 비었을 때만 시트(리스트 선택, 필터 지역 디폴트) → 주입 →
  /// 6) 제출 버튼 클릭 리스너(자동 기록).
  Future<void> _injectTalkApply(InAppWebViewController controller) async {
    debugPrint('🟣 [SMS] TalkApply 도착 — 유의사항 대기');
    await _waitGuideDismissed(controller);
    if (!mounted) return;
    debugPrint('🟣 [SMS] 유의사항 통과 — 폼 상태 읽기');
    // [TEMP] 주소 selector 검증용 자동 덤프 — 확인 후 제거(2026-10-04).
    await _dumpPage(controller, 'talkapply');

    // 폼 상태 읽기
    final raw = await controller.evaluateJavascript(source: '''
(function(){
  function filled(sel){var el=document.querySelector(sel);return !!(el && (el.value||'').trim().length>0);}
  var si=document.querySelector('#selSi');
  return JSON.stringify({
    comment: filled('#comment'),
    visa: filled('#visasdt'),
    visaEnd: filled('#visaedt'),
    si: !!(si && si.selectedIndex>0)
  });
})();
''');
    Map<String, dynamic> form = {};
    try {
      form = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {}
    debugPrint('🟣 [SMS] 폼 상태: $raw');
    final commentFilled = form['comment'] == true;
    final visaFilled = form['visa'] == true;
    final siSelected = form['si'] == true;

    final profile = ref.read(accountProvider).profile;

    // 메시지·비자일자 주입 (폼이 비어 있을 때만)
    await controller.evaluateJavascript(
        source: _buildInjectJs(profile,
            injectComment: !commentFilled, injectVisa: !visaFilled));

    // 주소 — 폼에 이미 있으면 안 건드림. 프로필에 **시/구/동 전부** 있으면
    // 바로 주입(시트 없음). 하나라도 없으면 시트로 받아 완성(동 필수).
    final hasProfileAddr = (profile?.addrSido ?? '').isNotEmpty &&
        (profile?.addrSigungu ?? '').isNotEmpty &&
        (profile?.addrDong ?? '').isNotEmpty;
    debugPrint('🟣 [SMS] 주소: siSelected=$siSelected '
        'profileAddrFull=$hasProfileAddr jitHandled=$_jitHandled');

    if (!siSelected && hasProfileAddr && profile != null) {
      // 프로필 주소(시/구/동 완비)로 바로 주입(팝업 없음) — 시/도 로드 대기 후
      await _waitSelSiLoaded(controller);
      if (!mounted) return;
      final r = await controller.evaluateJavascript(
          source: _buildAddressJs(profile.addrSido!, profile.addrSigungu));
      debugPrint('🟣 [SMS] 프로필 주소 주입: $r');
      await _readDongOptions(controller); // 동 목록 생성 대기
      await _selectDong(controller, profile.addrDong!);
    } else if (!siSelected && !_jitHandled && mounted) {
      _jitHandled = true;
      await _waitSelSiLoaded(controller); // 시/도 옵션 로드 대기
      final regions =
          await ref.read(jobRepositoryProvider).getAllRegionsPublic();
      if (!mounted) return;
      final defaults = _filterRegionDefault(regions);
      final saved = await showKhireJitSheet(
        context,
        langCode: widget.langCode,
        regions: regions,
        // 시트에서 시군구 고르는 순간 페이지에 주입 → 동 목록을 읽어 시트에 공급.
        loadDongs: (sido, sigungu) async {
          final r = await controller.evaluateJavascript(
              source: _buildAddressJs(sido, sigungu));
          debugPrint('🟣 [SMS] 주소 주입: $r');
          return _readDongOptions(controller);
        },
        // 프로필에 시/구가 있으면 그걸 기본값(동만 고르면 됨), 없으면 필터 지역.
        defaultSido: profile?.addrSido ?? defaults?.$1,
        defaultSigungu: profile?.addrSigungu ?? defaults?.$2,
      );
      if (saved != null) {
        await ref.read(accountProvider.notifier).saveSmsFields(
              addrSido: saved.sido,
              addrSigungu: saved.sigungu,
              addrDong: saved.dong,
            );
        if (saved.dong != null) await _selectDong(controller, saved.dong!);
      }
    }

    // 제출 감지 리스너 — ResumeCLS.SubmitTalkApplication 래핑.
    await controller.evaluateJavascript(source: '''
(function(){
  try {
    if (window.ResumeCLS && typeof ResumeCLS.SubmitTalkApplication === 'function' && !ResumeCLS._dariWrapped) {
      var orig = ResumeCLS.SubmitTalkApplication.bind(ResumeCLS);
      ResumeCLS.SubmitTalkApplication = function(){
        try { window.flutter_inappwebview.callHandler('dariSubmitted'); } catch(e){}
        return orig.apply(this, arguments);
      };
      ResumeCLS._dariWrapped = true;
    }
    // 폴백 — 실물 제출 버튼(.apply-action-button, 2026-10-04 덤프 확인)
    var btn = document.querySelector('.apply-action-button');
    if (btn && !btn._dariHooked) {
      btn.addEventListener('click', function(){
        try { window.flutter_inappwebview.callHandler('dariSubmitted'); } catch(e){}
      });
      btn._dariHooked = true;
    }
  } catch(e){ console.log('dari submit hook error', e); }
})();
''');
  }

  /// [TEMP] 현재 페이지 HTML을 Documents에 저장 — selector 실물 검증용.
  Future<void> _dumpPage(
      InAppWebViewController controller, String tag) async {
    try {
      final url = (await controller.getUrl())?.toString() ?? '';
      final html = await controller.evaluateJavascript(
          source: 'document.documentElement.outerHTML');
      final dir = await getApplicationDocumentsDirectory();
      final t = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final name =
          'khire_${tag}_${two(t.hour)}${two(t.minute)}${two(t.second)}.html';
      await File('${dir.path}/$name')
          .writeAsString('<!-- URL: $url -->\n${html ?? ''}');
      debugPrint('🟣 [SMS] 덤프 저장: $name (${(html as String?)?.length ?? 0})');
    } catch (e) {
      debugPrint('🟣 [SMS] 덤프 실패: $e');
    }
  }

  /// #selSi 옵션이 채워질 때까지 대기(TalkApply 도착 직후엔 "시/도"뿐일 수 있음).
  Future<void> _waitSelSiLoaded(InAppWebViewController controller) async {
    for (var i = 0; i < 16; i++) {
      if (!mounted) return;
      final n = await controller.evaluateJavascript(source: '''
(function(){var el=document.querySelector('#selSi');return el?el.options.length:0;})();
''');
      if (n is num && n > 1) return;
      await Future.delayed(const Duration(milliseconds: 300));
    }
    debugPrint('🟣 [SMS] selSi 옵션 로드 대기 타임아웃');
  }

  /// #selDong에서 텍스트로 동 선택.
  Future<void> _selectDong(
      InAppWebViewController controller, String dong) async {
    await controller.evaluateJavascript(source: '''
(function(){
  var el = document.querySelector('#selDong');
  if (!el) return 'no_el';
  var t = ${jsonEncode(dong)};
  for (var i = 0; i < el.options.length; i++) {
    // value=DOCD(한글 원본) — 번역돼도 불변
    if (el.options[i].value === t || el.options[i].text === t) {
      el.selectedIndex = i;
      el.dispatchEvent(new Event('change', {bubbles: true}));
      try {
        var lang = (window.KHire && KHire.Translate && KHire.Translate.readLang)
            ? KHire.Translate.readLang() : null;
        if (lang && window.GoogleTranslate && GoogleTranslate.Dispatch) {
          GoogleTranslate.Dispatch(lang);
        }
      } catch(e2){}
      return 'ok ' + i;
    }
  }
  return 'dong_no_match';
})();
''');
  }

  /// 사이트가 채운 #selDong 옵션 목록 읽기 — setWorkGugun이 동기 생성이라
  /// 보통 즉시, 안전하게 최대 3초 폴링.
  Future<List<String>> _readDongOptions(
      InAppWebViewController controller) async {
    for (var i = 0; i < 10; i++) {
      if (!mounted) return [];
      final raw = await controller.evaluateJavascript(source: '''
(function(){
  var el = document.querySelector('#selDong');
  if (!el || el.options.length <= 1) return null;
  var a = [];
  // text는 구글 번역으로 영어가 될 수 있어 value(DOCD, 한글 원본) 사용
  for (var i = 1; i < el.options.length; i++) a.push(el.options[i].value);
  return JSON.stringify(a);
})();
''');
      if (raw is String && raw.isNotEmpty) {
        try {
          final dongs = (jsonDecode(raw) as List).cast<String>();
          if (dongs.isNotEmpty) return dongs;
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    debugPrint('🟣 [SMS] 동 목록 읽기 실패(비어 있음)');
    return [];
  }

  /// 필터에 설정된 지역 → (시/도, 시군구) 기본값. 없으면 null.
  (String, String?)? _filterRegionDefault(
      List<Map<String, dynamic>> regions) {
    final ids = ref.read(filterStateProvider).regionIds;
    if (ids.isEmpty) return null;
    for (final r in regions) {
      if (ids.contains(r['id'] as int?)) {
        final si = r['si_name'] as String?;
        if (si == null) continue;
        final gu = r['gu_name'] as String?;
        return (si, (gu != null && gu.isNotEmpty) ? gu : null);
      }
    }
    return null;
  }

  /// 사용자가 제출 버튼을 눌렀을 때 — 자동 기록 + 토스트(1회).
  Future<void> _onSubmitted() async {
    if (_recorded) return;
    await _record();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.of(widget.langCode).appliedSavedToast),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// 메시지·비자일자 주입 스크립트 — **폼이 비어 있을 때만**([injectComment]/
  /// [injectVisa] 플래그는 호출 전 폼 상태 읽기로 결정, 덮어쓰기 금지).
  String _buildInjectJs(ApplicantProfile? p,
      {required bool injectComment, required bool injectVisa}) {
    final msg = jsonEncode(widget.message);
    final issued = jsonEncode(p?.visaIssuedAt ?? '');
    final expires = jsonEncode(
        (p?.visaNoExpiry == true) ? '' : (p?.visaExpiresAt ?? ''));
    final doComment = injectComment ? 'true' : 'false';
    final doVisa = injectVisa ? 'true' : 'false';
    final immediate = widget.wantsImmediateStart ? 'true' : 'false';

    return '''
(function(){
  try {
    var MSG = $msg, ISSUED = $issued, EXPIRES = $expires;
    var DO_COMMENT = $doComment, DO_VISA = $doVisa, IMMEDIATE = $immediate;

    function setIfEmpty(sel, val){
      var el = document.querySelector(sel);
      if (el && val && !(el.value||'').trim()){
        var max = parseInt(el.getAttribute('maxlength')||'0',10);
        if (max>0 && val.length>max) val = val.substring(0,max);
        el.value = val;
        el.dispatchEvent(new Event('input',{bubbles:true}));
        el.dispatchEvent(new Event('change',{bubbles:true}));
      }
    }

    // 1. 지원 메시지 — 비어 있을 때만
    if (DO_COMMENT){
      setIfEmpty('#comment', MSG);
      if (typeof limitTextNum === 'function'){
        try { limitTextNum('comment', parseInt((document.querySelector('#comment')||{}).getAttribute&&document.querySelector('#comment').getAttribute('maxlength')||'400',10), 'txtCommentSpan'); } catch(e){}
      }
    }

    // 2. 비자 발급/만료일 — 폼이 비어 있고 프로필 값 있을 때만
    if (DO_VISA){
      setIfEmpty('#visasdt', ISSUED);
      setIfEmpty('#visaedt', EXPIRES);
    }

    // 3. 바로출근 체크
    if (IMMEDIATE){
      var go = document.querySelector('#gotoworkyn');
      if (go && !go.checked) go.click();
    }
  } catch(e){ console.log('dari inject error', e); }
})();
''';
  }

  /// 주소 주입 — K-HIRE 실물 구조(2026-10-04 덤프 talkapply.html) 기반:
  /// 구·동 목록은 Ajax가 아니라 페이지 JS 배열(arrAreaCodeJson)로
  /// `setWorkGugun(선택할구, 동)`이 **동기로** 채움 → 사이트 함수를 직접 호출.
  /// 시/도명은 사이트("전남광주통합특별시")·DB("광주광역시") 표기가 달라
  /// 접미사 제거 핵심 토큰(광주)으로도 매칭. 결과 문자열 반환(디버깅용).
  String _buildAddressJs(String sido, String? sigungu) {
    final si = jsonEncode(sido);
    final gu = jsonEncode(sigungu ?? '');
    return '''
(function(){
  try {
    var SIDO = $si, SIGUNGU = $gu;
    var core = SIDO.replace(/(특별자치시|특별자치도|광역시|특별시|통합)/g,'')
                   .replace(/[시도]\$/,'');
    var el = document.querySelector('#selSi');
    if (!el) return 'no_selSi';
    var matched = false;
    for (var i = 0; i < el.options.length; i++) {
      // 구글 번역이 텍스트를 영어로 바꿔도 data-info엔 한글 원본 유지
      // (2026-10-04 덤프 talkapply2.html 확인) — data-info 우선 매칭.
      var info = (el.options[i].getAttribute('data-info') || '')
          .replace(/\\s/g,'');
      var t = el.options[i].text.replace(/\\s/g,'');
      var cand = info || t;
      if (cand === SIDO || cand.indexOf(SIDO) > -1 ||
          SIDO.indexOf(cand) > -1 || (core && cand.indexOf(core) > -1)) {
        el.selectedIndex = i;
        matched = true;
        break;
      }
    }
    if (!matched) return 'si_no_match';
    // 사이트 함수 직접 호출 — 구 목록 생성 + SIGUNGU 자동 선택
    if (typeof setWorkGugun === 'function') {
      setWorkGugun(SIGUNGU || '', '');
    }
    // 구 selected 보강(html 직후 jQuery selected 인식 타이밍 대비)
    var g = document.querySelector('#selGu');
    if (g && SIGUNGU) {
      for (var j = 0; j < g.options.length; j++) {
        if (g.options[j].text === SIGUNGU || g.options[j].value === SIGUNGU) {
          g.selectedIndex = j;
          break;
        }
      }
    }
    // 동 목록 명시 재생성
    if (typeof setWorkDong === 'function') {
      setWorkDong('');
    } else if (g) {
      g.dispatchEvent(new Event('change', {bubbles: true}));
    }
    // 새로 생성된 구·동 옵션도 페이지 언어로 번역 — 시/도와 표기 통일
    // (K-HIRE 번역위젯 재실행, setWorkDong과 동일 방식).
    try {
      var lang = (window.KHire && KHire.Translate && KHire.Translate.readLang)
          ? KHire.Translate.readLang() : null;
      if (lang && window.GoogleTranslate && GoogleTranslate.Dispatch) {
        GoogleTranslate.Dispatch(lang);
      }
    } catch(e2){}
    var d = document.querySelector('#selDong');
    return 'ok si=' + el.selectedIndex + ' gu=' + (g ? g.value : 'none') +
           ' dong=' + (d ? d.options.length : 'noEl');
  } catch(e){ return 'err:' + e.message; }
})();
''';
  }

  /// 회원가입 화면 프리필 (덤프 khire_signup.html selector 기반).
  /// 인증(휴대폰·이메일)·약관은 사용자가 직접.
  Future<void> _prefillSignup(InAppWebViewController controller) async {
    final p = ref.read(accountProvider).profile;
    if (p == null) return;
    final name = jsonEncode(p.name);
    final nation = jsonEncode(p.nationalityCode);
    final visa = jsonEncode(p.visaCode);
    final issued = jsonEncode(p.visaIssuedAt ?? '');
    final expires =
        jsonEncode(p.visaNoExpiry ? '' : (p.visaExpiresAt ?? ''));
    final birth = jsonEncode(p.birthDate); // YYYYMMDD
    final phone = jsonEncode(p.phone.replaceAll('-', ''));
    final email = jsonEncode(p.email);
    final gender = p.gender; // 'male'|'female'

    await controller.evaluateJavascript(source: '''
(function(){
  try {
    function setVal(sel,val){var el=document.querySelector(sel);if(el&&val){el.value=val;el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));}}
    setVal('#usernm', $name);
    setVal('#nationcd', $nation);
    setVal('#visacd', $visa);
    setVal('#visasdt', $issued);
    setVal('#visaedt', $expires);
    setVal('#email', $email);
    var b = $birth;
    if (b && b.length===8){
      setVal('#birthyear', b.substring(0,4));
      setVal('#birthmonth', b.substring(4,6));
      setVal('#birthday', b.substring(6,8));
    }
    var ph = $phone;
    if (ph && ph.length>=10){
      setVal('#htel1', ph.substring(0,3));
      setVal('#htel2', ph.substring(3, ph.length-4));
      setVal('#htel3', ph.substring(ph.length-4));
    }
    var g = document.querySelector('#${gender == 'female' ? 'female' : 'male'}');
    if (g && !g.checked) g.click();
  } catch(e){ console.log('dari signup prefill error', e); }
})();
''');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.of(widget.langCode).smsSignupPrefilled),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// 닫기 — 제출 감지(지원하기 클릭 훅)가 있으므로 원칙상 팝업 불필요하나,
  /// **감지 신뢰도 검증 전까지 백업 팝업 유지**(2026-10-04 사용자 지시).
  /// 검증 완료 후 팝업 제거 예정(감지 없이 닫음 = 지원 안 함).
  Future<void> _onClose(AppStrings s) async {
    if (_recorded || !_reachedTalkApply) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final applied = await showApplyConfirmDialog(
      context,
      company: widget.job.getDisplayCompany(widget.langCode),
      title: widget.job.getTitle(widget.langCode),
      question: s.smsConfirmApplied,
      desc: s.applyPhoneConfirmDesc,
      yesLabel: s.yes,
      noLabel: s.no,
    );
    if (applied == true) {
      await _record();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.appliedSavedToast),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _record() async {
    if (_recorded) return;
    _recorded = true;
    await ref.read(appliedJobActionsProvider).record(
          jobId: widget.job.id,
          method: 'sms',
          title: widget.job.getTitle(widget.langCode),
          company: widget.job.getDisplayCompany(widget.langCode),
          siteName: widget.job.siteName ?? '',
          location: widget.job.getShortLocation(widget.langCode),
        );
  }
}

/// [TEMP] 완료 URL 확보용 디버그 스트립. 제출 후 이동 URL을 탭해 복사.
class _UrlStrip extends StatelessWidget {
  final String url;
  final VoidCallback onCopy;
  const _UrlStrip({required this.url, required this.onCopy});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: Container(
        width: double.infinity,
        height: 28,
        color: AppColors.gray50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Text(
          url.isEmpty ? '—' : url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.gray500),
        ),
      ),
    );
  }
}
