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
import '../../../data/constants/world_countries.dart';
import '../../../data/models/job.dart';
import '../../../data/models/resume.dart';
import '../../../data/services/khire_resume_codes.dart';
import '../../../data/services/site_login_prefs.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/applied_job_provider.dart';
import '../../../providers/job_provider.dart';
import '../../../providers/resume_provider.dart';
import '../apply_complete_screen.dart';
import '../online/khire_resume_injector.dart';
import 'khire_jit_sheet.dart';
import 'sms_message_builder.dart';

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

  /// 지원 유형 — 'talk'(문자지원/TalkApply) 또는 'simple'(간편지원/SimpleApply).
  /// 간편지원은 이력서 기반이라 메시지·주소 주입을 하지 않는다(2026-10-05).
  final String applyType;

  /// 칩 조립본 입력값(직접 입력 수정본이면 null). null이 아니면 지원 시점에
  /// K-HIRE 계정의 국적·비자로 메시지를 재생성한다(2026-10-05). 간편지원은 null.
  final SmsMessageInput? messageInput;

  /// 온라인(이력서) 지원 시 Dari 이력서(canonical). Regist.asp 도달 시
  /// localStorage로 주입(2026-10-05, 설계서 §6). online 외에는 null.
  final Resume? resume;

  const KhireApplyWebViewScreen({
    super.key,
    required this.job,
    required this.message,
    required this.wantsImmediateStart,
    required this.langCode,
    this.applyType = 'talk',
    this.messageInput,
    this.resume,
  });

  bool get isSimple => applyType == 'simple';
  bool get isHomepage => applyType == 'homepage';
  bool get isOnline => applyType == 'online';

  @override
  ConsumerState<KhireApplyWebViewScreen> createState() =>
      _KhireApplyWebViewScreenState();
}

class _KhireApplyWebViewScreenState
    extends ConsumerState<KhireApplyWebViewScreen> {
  bool _injectedThisLoad = false;
  bool _jitHandled = false; // JIT 시트 중복 방지
  // 지원 시점 K-HIRE 국적·비자로 재생성한 메시지(없으면 widget.message 그대로).
  String? _effectiveMessage;
  bool _recorded = false;
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
    // 홈페이지 지원 — 외부 URL 미수집이라 K-HIRE 공고 상세로 보내고, 거기서
    // 사용자가 "홈페이지 지원" 버튼을 직접 탭 → 업체 사이트로(2026-10-05).
    if (widget.isHomepage) {
      return jobUrl.isNotEmpty ? jobUrl : 'https://m.khire.co.kr/';
    }
    // 온라인(이력서) 지원 — 라우터 직행 URL은 비로그인 시 NotFound로 떨어져
    // (2026-10-05 curl 확인) 경로 확정 불가 → 공고 상세에서 K-HIRE 자체
    // 온라인지원 동작을 자동 클릭(문자지원과 동일한 검증된 패턴).
    if (widget.isOnline) {
      return jobUrl.isNotEmpty ? jobUrl : 'https://m.khire.co.kr/';
    }
    final adid =
        RegExp(r'[?&]adid=(\d+)').firstMatch(jobUrl)?.group(1);
    if (adid != null) {
      if (widget.isSimple) {
        // 간편지원 — SimpleApply 직행(사용자 제공 URL 패턴, 2026-10-05).
        return 'https://m.khire.co.kr/person/SimpleApply.asp?adid=$adid&recomyn=&listmenucd=';
      }
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
          centerTitle: true,
          title: Text(
              widget.isSimple
                  ? (s.applyMethodLabel('simple') ?? s.smsApplyTitle)
                  : widget.isHomepage
                      ? (s.applyMethodLabel('homepage') ?? s.smsApplyTitle)
                      : widget.isOnline
                          ? (s.applyMethodLabel('online') ?? s.smsApplyTitle)
                          : s.smsApplyTitle,
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
                  behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2),
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
            // 제출 기록은 ApplyComplete.asp 완료 페이지 도달로 감지(onLoadStop).
            // 회원가입 '가입하기' 시점의 최종 입력값 → 우리 프로필 역동기화
            // (고객이 가입폼에서 우리가 넣은 값을 고쳐도 DB 반영, 2026-10-05).
            controller.addJavaScriptHandler(
              handlerName: 'dariSignupValues',
              callback: (args) {
                if (args.isNotEmpty && args.first is Map) {
                  _onSignupValues(Map<String, dynamic>.from(args.first as Map));
                }
              },
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
                              widget.isHomepage
                                  ? s.smsLoadingHomepage
                                  : s.smsLoadingSite,
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

    // 지원 완료 — ApplyComplete.asp 도달 = 실제 제출 성공(문자=TALK/간편=SIMPLE).
    // 클릭 시점이 아니라 이 완료 페이지에서만 기록 → 오기록 방지(2026-10-05).
    // K-HIRE 완료 페이지에 머물지 않고 우리 자체 완료 화면으로 교체.
    if (lower.contains('applycomplete')) {
      _injectedThisLoad = true;
      await _record();
      // 동기화 A안: 온라인 지원 완료 = Dari 이력서가 K-HIRE에 반영된 상태.
      // 최초 등록 플래그를 세우고 '반영 대기'를 해제(2026-10-09).
      if (widget.isOnline && widget.resume != null) {
        try {
          await ref.read(resumeActionsProvider).save(widget.resume!
              .copyWith(khireRegistered: true, khireDirty: false));
        } catch (_) {
          // 플래그 저장 실패는 치명적이지 않음 — 다음 저장 때 재시도됨.
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ApplyCompleteScreen(
          langCode: widget.langCode,
          company: widget.job.getDisplayCompany(widget.langCode),
          title: widget.job.getTitle(widget.langCode),
        ),
      ));
      return;
    }

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
    // TalkApply(문자) / SimpleApply(간편) 폼 도착 — 공통 처리.
    if (lower.contains('talkapply') || lower.contains('simpleapply')) {
      _injectedThisLoad = true;
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
    // 온라인(이력서) 지원 ①: 이력서 작성 폼(Regist.asp) 도달 — Dari 이력서를
    // localStorage RESUME_*_JSON으로 주입(hashdata는 라이브 값 보존, §6 레시피).
    // 주입 후 리로드 1회 → 폼이 채워진 상태로 사용자가 확인·저장/지원.
    if (widget.isOnline &&
        lower.contains('/person/resume/regist.asp') &&
        widget.resume != null) {
      _injectedThisLoad = true;
      if (_overlayVisible) setState(() => _overlayVisible = false);
      if (_sawLoginPage) {
        final type = _detectedOauth ?? 'K-HIRE';
        SiteLoginPrefs.save('khire', type);
        _lastLoginType = type;
        _sawLoginPage = false;
      }
      final already = await controller.evaluateJavascript(
          source: KhireResumeInjector.checkInjectedJs);
      if (already == true) {
        debugPrint('🟣 [ONLINE] 이미 주입됨 — 사용자 확인 대기');
        return;
      }
      // 근무조건 이름(workperiodnm 등) 조회에 코드표 필요 — 로드 보장.
      await KhireResumeCodes.instance.ensureLoaded();
      final birth = ref.read(accountProvider).profile?.birthDate ?? '';
      final r = await controller.evaluateJavascript(
          source: KhireResumeInjector.buildInjectionJs(
        widget.resume!,
        birthYm: birth.length >= 6 ? birth.substring(0, 6) : '',
      ));
      debugPrint('🟣 [ONLINE] 이력서 주입: $r');
      return;
    }
    // 온라인(이력서) 지원 ②: 공고 상세 — K-HIRE 자체 온라인지원 동작을 자동
    // 클릭(문자지원과 동일 패턴). 미로그인이면 K-HIRE가 로그인 유도.
    // CLS 함수명 미확정이라 selector·텍스트 스캔 폴백 포함(2026-10-05).
    if (lower.contains('jobdetail') &&
        widget.isOnline &&
        _autoClickCount < 3) {
      _injectedThisLoad = true;
      _autoClickCount++;
      final r = await controller.evaluateJavascript(source: '''
(function(){
  try {
    if (window.JobDetailCLS && typeof JobDetailCLS.ApplicationOnlineResume === 'function') {
      JobDetailCLS.ApplicationOnlineResume(); return 'cls';
    }
    var el = document.querySelector('.applyLayer__link--online');
    if (el){ el.click(); return 'selector'; }
    var links = document.querySelectorAll('a[href], button');
    for (var i=0;i<links.length;i++){
      var t=(links[i].innerText||links[i].textContent||'').trim();
      if (t.indexOf('온라인')>=0 && t.indexOf('지원')>=0){ links[i].click(); return 'scan'; }
    }
  } catch(e){ console.log('dari online auto-click error', e); }
  return 'none';
})();
''');
      debugPrint('🟣 [ONLINE] auto-click: $r');
      // 진입 실패 시 상세 노출(사용자가 직접 탭 가능하도록 오버레이 해제).
      if (r == 'none' && _overlayVisible) {
        setState(() => _overlayVisible = false);
      }
      return;
    }
    // 홈페이지 지원: 공고 상세의 "홈페이지 지원" 앵커(외부 업체 채용 URL)를
    // 자동 클릭해 업체 사이트로 바로 이동시킨다(2026-10-05 사용자 지시).
    // selector(.applyLayer__link--homepage) 우선, 실패 시 "홈페이지" 텍스트 +
    // 외부(khire 아님) http href 앵커를 스캔(번역 위젯 대비 homepage도 매칭).
    if (lower.contains('jobdetail') && widget.isHomepage) {
      _injectedThisLoad = true;
      final r = await controller.evaluateJavascript(source: '''
(function(){
  try {
    var el = document.querySelector('.applyLayer__link--homepage');
    if (el){ var h=el.href||el.getAttribute('href')||''; if(h){ location.href=h; return 'cls'; } }
    var links = document.querySelectorAll('a[href]');
    for (var i=0;i<links.length;i++){
      var a=links[i];
      var t=(a.innerText||a.textContent||'').trim();
      var href=a.href||a.getAttribute('href')||'';
      if ((t.indexOf('홈페이지')>=0 || /homepage/i.test(t)) && /^https?:/i.test(href) && href.indexOf('khire.co.kr')<0){
        location.href=href; return 'scan';
      }
    }
  } catch(e){ console.log('dari homepage auto error', e); }
  return 'none';
})();
''');
      debugPrint('🟣 [HOMEPAGE] auto-nav: $r');
      // 외부로 이동 중이면 오버레이 유지(깜빡임 가림), 못 찾았으면 상세 노출(폴백).
      if (r == 'none' && _overlayVisible) {
        setState(() => _overlayVisible = false);
      }
      return;
    }
    // 공고 상세: K-HIRE 자체 문자지원 동작을 호출해 TalkApply로 진입 —
    // 사용자가 버튼을 직접 찾지 않아도 됨. 미로그인이면 K-HIRE가 로그인 유도.
    // (TalkApply 직접 URL은 로그인 세션에서만 렌더링돼 알 수 없음, 2026-10-04)
    // 간편지원은 자동클릭 대상 함수가 달라 제외 — 로그인 상태면 직행 URL로 동작.
    if (lower.contains('jobdetail') && _autoClickCount < 3 && !widget.isSimple) {
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
      return;
    }
    // 온라인 지원: K-HIRE에 이력서가 이미 있으면(resumecount>0) Regist를
    // 건너뛰고 지원확인 등 미지의 화면으로 감 — 어떤 분기도 안 잡히면
    // 오버레이를 풀어 사용자가 화면을 볼 수 있게 한다(15초 블라인드 방지).
    if (widget.isOnline && _overlayVisible) {
      setState(() => _overlayVisible = false);
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
    // [TEMP] selector 검증용 자동 덤프 — 확인 후 제거. 간편지원은 'simpleapply'로.
    await _dumpPage(controller, widget.isSimple ? 'simpleapply' : 'talkapply');

    // 폼 상태 읽기
    final raw = await controller.evaluateJavascript(source: '''
(function(){
  function filled(sel){var el=document.querySelector(sel);return !!(el && (el.value||'').trim().length>0);}
  var si=document.querySelector('#selSi');
  return JSON.stringify({
    comment: filled('#comment'),
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
    final siSelected = form['si'] == true;

    // K-HIRE 값을 source of truth로 우리 DB 동기화(로드 시점 값만 — 사용자가
    // 폼에서 수정한 건 반영 안 함). TalkApply=히든/표시 기반,
    // SimpleApply=편집 입력필드 기반이라 selector가 다름(2026-10-05).
    if (widget.isSimple) {
      await _syncFromSimpleApply(controller);
    } else {
      await _syncFromKhireAccount(controller);
    }
    if (!mounted) return;

    // 메시지(#comment) 주입 — 문자·간편 공통(둘 다 메시지 기반, 2026-10-05
    // 덤프 확인). 간편지원은 '각오 한마디'(#comment, 2000자)로 동일 selector.
    await controller.evaluateJavascript(
        source: _buildInjectJs(injectComment: !commentFilled));

    // 주소 — **문자지원(TalkApply)에만** 있음. 간편지원(SimpleApply)엔 주소란이
    // 없어 건너뜀(덤프 확인: selSi 없음, 2026-10-05).
    if (!widget.isSimple) {
    final profile = ref.read(accountProvider).profile;
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
        _addRegionToFilterIfMissing(regions, saved.sido, saved.sigungu);
      }
    }
    } // !widget.isSimple — 메시지·주소 주입 블록 끝
    // 제출 감지는 클릭 훅이 아니라 **ApplyComplete.asp 완료 페이지 도달**로 처리
    // — "지원하기" 클릭(확인 팝업 전)에 오기록되던 문제 제거(2026-10-05).
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

  /// 추가정보로 받은 주소가 필터에 없으면 자동 추가(2026-10-05 사용자 확정).
  /// 같은 시/도가 이미 선택돼 있으면(시 레벨이든 다른 구든) 건드리지 않음.
  void _addRegionToFilterIfMissing(
      List<Map<String, dynamic>> regions, String sido, String? sigungu) {
    final selected = ref.read(filterStateProvider).regionIds;
    // 선택된 지역 중 같은 시/도가 하나라도 있으면 이미 커버된 것으로 봄.
    for (final r in regions) {
      if (selected.contains(r['id']) && r['si_name'] == sido) return;
    }
    // 구 단위 우선, 없으면 시/도 레벨 행.
    int? rid;
    for (final r in regions) {
      if (r['si_name'] == sido && r['gu_name'] == sigungu) {
        rid = r['id'] as int?;
        break;
      }
    }
    if (rid == null) {
      for (final r in regions) {
        if (r['si_name'] == sido && r['gu_name'] == null) {
          rid = r['id'] as int?;
          break;
        }
      }
    }
    if (rid != null) {
      ref.read(filterStateProvider.notifier).toggleRegionId(rid);
      debugPrint('🟣 [SMS] 필터에 지역 자동 추가: $sido ${sigungu ?? ''} ($rid)');
    }
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
  /// 메시지 주입 스크립트 — **폼이 비어 있을 때만**(덮어쓰기 금지).
  /// 비자기간은 수집·주입 안 함(사용자가 K-HIRE에서 직접, 2026-10-05).
  /// K-HIRE 계정 값(TalkApply 폼 표시·히든)을 읽어 우리 DB 동기화 + 메시지
  /// 재생성. K-HIRE가 source of truth(인증 거침·담당자가 봄). 값이 비거나 파싱
  /// 실패한 필드는 건드리지 않음(잘못된 덮어쓰기 방지). 비자기간은 덤으로 저장.
  Future<void> _syncFromKhireAccount(InAppWebViewController controller) async {
    final raw = await controller.evaluateJavascript(source: '''
(function(){
  function txt(sel){var el=document.querySelector(sel);return el?(el.textContent||'').trim():'';}
  function val(sel){var el=document.querySelector(sel);return el?(el.value||'').trim():'';}
  return JSON.stringify({
    name: txt('li.name .value'),
    genderText: txt('li.gender .value'),
    birthText: txt('li.birth .value'),
    phone: txt('li.mobile .value'),
    nationcd: val('#hidnationcd'),
    nationKo: val('#hidnation'),
    visacd: val('#hidvisacd'),
    visaText: txt('li.visa .value'),
    visasdt: val('#visasdt'),
    visaedt: val('#visaedt')
  });
})();
''');
    Map<String, dynamic> kh;
    try {
      kh = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final profile = ref.read(accountProvider).profile;
    if (profile == null) return;
    String g(String k) => (kh[k] as String? ?? '').trim();

    // --- 개인정보 역동기화 ---
    var updated = profile;
    var changed = false;
    final name = g('name');
    if (name.isNotEmpty && name != profile.name) {
      updated = updated.copyWith(name: name);
      changed = true;
    }
    final gender = _genderFromKo(g('genderText'));
    if (gender != null && gender != profile.gender) {
      updated = updated.copyWith(gender: gender);
      changed = true;
    }
    final birth = _digitsOnly(g('birthText'));
    if (birth.length == 8 && birth != profile.birthDate) {
      updated = updated.copyWith(birthDate: birth);
      changed = true;
    }
    final phone = g('phone');
    if (phone.isNotEmpty && phone != profile.phone) {
      updated = updated.copyWith(phone: phone);
      changed = true;
    }
    final nationcd = g('nationcd').toUpperCase();
    if (nationcd.isNotEmpty && nationcd != profile.nationalityCode) {
      updated = updated.copyWith(
        nationalityCode: nationcd,
        nationalityLabel: _nationalityLabel(nationcd) ?? g('nationKo'),
      );
      changed = true;
    }
    final visacd = g('visacd');
    if (visacd.isNotEmpty && visacd != profile.visaCode) {
      updated = updated.copyWith(visaCode: visacd, visaLabel: visacd);
      changed = true;
    }
    if (changed) {
      try {
        await ref.read(accountProvider.notifier).completeSignup(updated);
      } catch (_) {}
    }

    // --- 비자기간(덤) 저장 ---
    final period = _parseVisaPeriod(g('visaText'), g('visasdt'), g('visaedt'));
    if (period != null) {
      final issued = period.$1;
      final expires = period.$2;
      if (issued != profile.visaIssuedAt ||
          (expires != null && expires != profile.visaExpiresAt)) {
        try {
          final notifier = ref.read(accountProvider.notifier);
          if (expires != null) {
            await notifier.saveSmsFields(
                visaIssuedAt: issued, visaExpiresAt: expires);
          } else {
            await notifier.saveSmsFields(visaIssuedAt: issued);
          }
        } catch (_) {}
      }
    }

    // --- 메시지 재생성(칩 조립본일 때만) — K-HIRE 국적(한글)·비자로 ---
    final input = widget.messageInput;
    if (input != null) {
      final natKo = g('nationKo');
      final visa = g('visacd');
      if (natKo.isNotEmpty && visa.isNotEmpty) {
        _effectiveMessage = SmsMessageBuilder.build(
          input.withNationalityVisa(nationalityLabel: natKo, visaCode: visa),
        );
      }
    }
  }

  /// 간편지원(SimpleApply) 편집 입력필드에서 K-HIRE가 채워둔 개인정보를 읽어
  /// 우리 DB 동기화(로드 시점 1회). 필드: #username, gender 라디오, #htel1~3,
  /// #birthyear/month/day, #email1/#email2. 국적·비자 필드는 폼에 없음.
  /// _onSignupValues(맵)로 위임 — 이름·성별·생년·휴대폰·이메일만 갱신.
  Future<void> _syncFromSimpleApply(InAppWebViewController controller) async {
    final raw = await controller.evaluateJavascript(source: '''
(function(){
  function v(sel){var el=document.querySelector(sel);return el?((el.value||'')+'').trim():'';}
  function pad(x){x=(x||'').replace(/\\D/g,'');return x.length===1?('0'+x):x;}
  var g=document.querySelector('input[name=gender]:checked');
  var y=v('#birthyear'), m=v('#birthmonth'), d=v('#birthday');
  var e1=v('#email1'), e2=v('#email2');
  return JSON.stringify({
    name: v('#username'),
    gender: g?(g.value||''):'',
    birth: (y&&m&&d)?(y+pad(m)+pad(d)):'',
    phone: v('#htel1')+v('#htel2')+v('#htel3'),
    email: (e1&&e2)?(e1+'@'+e2):'',
    nationcd:'', visacd:'', nationKo:'', visaText:'', visasdt:'', visaedt:''
  });
})();
''');
    if (!mounted) return;
    try {
      final m = jsonDecode(raw as String) as Map<String, dynamic>;
      await _onSignupValues(Map<String, dynamic>.from(m));
    } catch (_) {}
  }

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  // Google Translate 위젯이 표시 텍스트를 번역하므로 한/영 모두 인식.
  // (female/woman은 male/man을 포함하니 여성 판정을 먼저.)
  static String? _genderFromKo(String t) {
    final s = t.toLowerCase();
    if (t.contains('여') || s.contains('female') || s.contains('woman')) {
      return 'female';
    }
    if (t.contains('남') || s.contains('male') || s.contains('man')) {
      return 'male';
    }
    return null;
  }

  /// 비자기간 파싱 — 발급일 입력(#visasdt) 우선, 없으면 비자 표시텍스트의
  /// "(2026.02.01~2027.02.01)" 범위에서 추출. 반환: (발급YYYYMMDD, 만료YYYYMMDD?).
  (String, String?)? _parseVisaPeriod(String visaText, String sdt, String edt) {
    final a = _digitsOnly(sdt);
    final b = _digitsOnly(edt);
    if (a.length == 8) return (a, b.length == 8 ? b : null);
    final m = RegExp(r'(\d{4})\.(\d{2})\.(\d{2})\s*~\s*(\d{4})\.(\d{2})\.(\d{2})')
        .firstMatch(visaText);
    if (m != null) {
      return ('${m[1]}${m[2]}${m[3]}', '${m[4]}${m[5]}${m[6]}');
    }
    return null;
  }

  String _buildInjectJs({required bool injectComment}) {
    final msg = jsonEncode(_effectiveMessage ?? widget.message);
    final doComment = injectComment ? 'true' : 'false';
    final immediate = widget.wantsImmediateStart ? 'true' : 'false';

    return '''
(function(){
  try {
    var MSG = $msg;
    var DO_COMMENT = $doComment, IMMEDIATE = $immediate;

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

    // 2. 바로출근 체크
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
    // 비자 발급/만료일은 프리필 안 함 — 사용자가 직접 입력(2026-10-05 확정).
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
    setVal('#email', $email);
    // 생년월일: 실제 폼은 단일 필드 #birthdate(8자리). 구 분리필드는 폴백.
    var b = $birth;
    if (b && b.length===8){
      if (document.querySelector('#birthdate')) { setVal('#birthdate', b); }
      else {
        setVal('#birthyear', b.substring(0,4));
        setVal('#birthmonth', b.substring(4,6));
        setVal('#birthday', b.substring(6,8));
      }
    }
    // 휴대폰: 실제 폼은 단일 필드 #htel. 구 분리필드는 폴백.
    var ph = $phone;
    if (ph && ph.length>=10){
      if (document.querySelector('#htel')) { setVal('#htel', ph); }
      else {
        setVal('#htel1', ph.substring(0,3));
        setVal('#htel2', ph.substring(3, ph.length-4));
        setVal('#htel3', ph.substring(ph.length-4));
      }
    }
    // 성별: 실제 폼은 input[name=gender]. 여러 value 인코딩(male/female, M/F) 대응.
    var gv = '${gender == 'female' ? 'female' : 'male'}';
    var gshort = gv === 'female' ? 'F' : 'M';
    var gcands = ['#'+gv,
      'input[name=gender][value="'+gv+'"]',
      'input[name=gender][value="'+gshort+'"]'];
    for (var gi=0; gi<gcands.length; gi++){
      var gel = document.querySelector(gcands[gi]);
      if (gel){ if(!gel.checked) gel.click(); break; }
    }
  } catch(e){ console.log('dari signup prefill error', e); }
})();
''');
    // 프리필 안내 스낵바 제거(2026-10-05 사용자 확정) — 조용히 채우기만.

    // '가입하기' 제출 직전 최종 입력값을 읽어 Flutter로 전달(역동기화).
    // JoinRegFormPCLS.doSubmit 래핑 + 가입 버튼 클릭 폴백.
    await controller.evaluateJavascript(source: '''
(function(){
  try {
    function gv(sel){var el=document.querySelector(sel);return el?(el.value||''):'';}
    function gender(){
      var el=document.querySelector('input[name=gender]:checked');
      return el?(el.value||''):'';
    }
    function collect(){
      try {
        window.flutter_inappwebview.callHandler('dariSignupValues', {
          name: gv('#usernm'),
          birth: gv('#birthdate'),
          phone: gv('#htel'),
          email: gv('#email'),
          gender: gender(),
          nationcd: gv('#nationcd'),
          visacd: gv('#visacd')
        });
      } catch(e){}
    }
    if (window.JoinRegFormPCLS && typeof JoinRegFormPCLS.doSubmit === 'function' && !JoinRegFormPCLS._dariWrapped) {
      var orig = JoinRegFormPCLS.doSubmit.bind(JoinRegFormPCLS);
      JoinRegFormPCLS.doSubmit = function(){ collect(); return orig.apply(this, arguments); };
      JoinRegFormPCLS._dariWrapped = true;
    }
    // 폴백 — '가입하기' 버튼 클릭
    var sbtns = document.querySelectorAll('button, a, input[type=button], input[type=submit]');
    for (var i=0;i<sbtns.length;i++){
      var t=(sbtns[i].innerText||sbtns[i].value||'');
      if (t.indexOf('가입하기')>=0 && !sbtns[i]._dariHooked){
        sbtns[i].addEventListener('click', collect);
        sbtns[i]._dariHooked = true;
      }
    }
  } catch(e){ console.log('dari signup capture hook error', e); }
})();
''');
  }

  /// 회원가입 폼의 최종 입력값을 우리 프로필에 역동기화(A안 — 우리가 세팅하는
  /// 필드 전부). 고객이 가입폼에서 값을 고쳐도 DB가 K-HIRE와 일치하게 유지.
  /// 국적: nationcd(alpha-2)→라벨(worldCountries, ko/그외=en). 비자: code==label.
  Future<void> _onSignupValues(Map<String, dynamic> v) async {
    final p = ref.read(accountProvider).profile;
    if (p == null) return;
    String g(String k) => (v[k] as String? ?? '').trim();

    var updated = p;
    var changed = false;

    final name = g('name');
    if (name.isNotEmpty && name != p.name) {
      updated = updated.copyWith(name: name);
      changed = true;
    }
    final birth = g('birth').replaceAll(RegExp(r'\D'), '');
    if (birth.length == 8 && birth != p.birthDate) {
      updated = updated.copyWith(birthDate: birth);
      changed = true;
    }
    final phoneDigits = g('phone').replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length >= 10) {
      final formatted = _formatPhone(phoneDigits);
      if (formatted != p.phone) {
        updated = updated.copyWith(phone: formatted);
        changed = true;
      }
    }
    final email = g('email');
    if (email.isNotEmpty && email != p.email) {
      updated = updated.copyWith(email: email);
      changed = true;
    }
    final gender = _normalizeGender(g('gender'));
    if (gender != null && gender != p.gender) {
      updated = updated.copyWith(gender: gender);
      changed = true;
    }
    final nationcd = g('nationcd').toUpperCase();
    if (nationcd.isNotEmpty && nationcd != p.nationalityCode) {
      updated = updated.copyWith(
        nationalityCode: nationcd,
        nationalityLabel: _nationalityLabel(nationcd) ?? p.nationalityLabel,
      );
      changed = true;
    }
    final visacd = g('visacd');
    if (visacd.isNotEmpty && visacd != p.visaCode) {
      // 비자는 code==label 구조(visa_type_select)라 동일 문자열 저장.
      updated = updated.copyWith(visaCode: visacd, visaLabel: visacd);
      changed = true;
    }

    if (!changed) return;
    try {
      await ref.read(accountProvider.notifier).completeSignup(updated);
    } catch (_) {
      // 역동기화 실패는 조용히 무시 — 가입 흐름에 영향 주지 않음.
    }
  }

  /// 숫자 11자리(010...)는 3-4-4, 10자리는 3-3-4로 하이픈 포맷. 그 외 원본.
  static String _formatPhone(String d) {
    if (d.length == 11) return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
    if (d.length == 10) return '${d.substring(0, 3)}-${d.substring(3, 6)}-${d.substring(6)}';
    return d;
  }

  /// K-HIRE 성별 라디오 value를 'male'/'female'로 정규화. 판별 불가 시 null.
  static String? _normalizeGender(String raw) {
    final r = raw.toLowerCase();
    if (r == 'female' || r == 'f' || r == 'w' || r == '2') return 'female';
    if (r == 'male' || r == 'm' || r == '1') return 'male';
    return null;
  }

  /// alpha-2 국가코드 → 현재 언어 라벨(worldCountries는 en/ko만 보유).
  String? _nationalityLabel(String code) {
    for (final c in worldCountries) {
      if (c.$1 == code) return widget.langCode == 'ko' ? c.$3 : c.$2;
    }
    return null;
  }

  /// 닫기. 문자/간편은 제출 자동감지로 기록하므로 바로 닫음. **홈페이지는
  /// 외부 사이트라 자동감지 불가** → 닫을 때 "홈페이지로 지원하셨나요?" 확인 후
  /// '네'면 기록(2026-10-05 사용자 확정).
  Future<void> _onClose(AppStrings s) async {
    if (!widget.isHomepage || _recorded) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final applied = await showApplyConfirmDialog(
      context,
      company: widget.job.getDisplayCompany(widget.langCode),
      title: widget.job.getTitle(widget.langCode),
      question: s.applyHomepageConfirmQuestion,
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
          duration: const Duration(seconds: 2),
        ));
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// applied_jobs 기록용 방법 코드.
  String get _applyMethodCode => widget.isSimple
      ? 'simple'
      : widget.isHomepage
          ? 'homepage'
          : widget.isOnline
              ? 'online'
              : 'sms';

  Future<void> _record() async {
    if (_recorded) return;
    _recorded = true;
    await ref.read(appliedJobActionsProvider).record(
          jobId: widget.job.id,
          method: _applyMethodCode,
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
