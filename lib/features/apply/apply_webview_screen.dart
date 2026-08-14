import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/app_strings.dart';
import 'site_lang.dart';

/// 지원하기 인앱 WebView (프로덕션).
///
/// - 번역은 각 사이트의 자체 다국어 기능 사용 (2026-08-14 전 사이트 조사:
///   10개 사이트 전부 자체 언어 전환 UI 보유 — 구글번역 주입은 SPA(FindJob 등)와
///   충돌해 제거, iOS(인앱 사파리)와 동일 정책)
/// - 하드웨어 백키: WebView 내부 뒤로, history 없으면 화면 종료(다리 복귀)
///   (FindJob은 도메인 리다이렉트 히스토리 쌍 스킵 처리)
/// - 상단 X: 언제든 즉시 다리 복귀
/// - intent:// 등 비-http 이동 차단(앱스토어 이탈 방지)
/// - 로드 실패 시 외부 브라우저 폴백
class ApplyWebViewScreen extends StatefulWidget {
  final String url;
  final String langCode; // 앱 언어코드 (ko/en/zh/vi/...)
  final String? title;
  const ApplyWebViewScreen({
    super.key,
    required this.url,
    required this.langCode,
    this.title,
  });

  @override
  State<ApplyWebViewScreen> createState() => _ApplyWebViewScreenState();
}

class _ApplyWebViewScreenState extends State<ApplyWebViewScreen> {
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _failed = false;
  // 언어 사전 세팅(쿠키) 완료 전에 WebView가 로드되지 않도록 게이트
  bool _langReady = false;

  @override
  void initState() {
    super.initState();
    _prepareLang();
  }

  Future<void> _prepareLang() async {
    await SiteLang.presetCookies(widget.url, widget.langCode);
    if (mounted) setState(() => _langReady = true);
  }

  /// 벼룩시장(FindJob) 여부 — global→global-m 도메인 리다이렉트로 백키 루프가 생기는 사이트
  bool get _isFindJob => widget.url.contains('findjob.co.kr');

  /// URL의 경로+쿼리 (호스트 무시) — global↔global-m처럼 도메인만 다른 같은 페이지 판별용
  String _pathQuery(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return url;
    return '${u.path}?${u.query}';
  }

  /// FindJob 전용 백키: 리다이렉트 쌍(같은 경로+쿼리)은 한 페이지로 취급.
  /// 실제 다른 페이지가 있으면 그리로, 없으면(진입 페이지뿐) 다리 복귀.
  Future<void> _handleBackFindJob(NavigatorState navigator) async {
    final c = _controller!;
    final history = await c.getCopyBackForwardList();
    final items = history?.list ?? [];
    final cur = history?.currentIndex ?? -1;
    if (cur < 0 || items.isEmpty) {
      navigator.pop();
      return;
    }
    final curPq = _pathQuery(items[cur].url.toString());
    int? target;
    for (int i = cur - 1; i >= 0; i--) {
      if (_pathQuery(items[i].url.toString()) != curPq) {
        target = i;
        break;
      }
    }
    if (target == null) {
      navigator.pop(); // 뒤로 갈 실제 페이지 없음 (리다이렉트 쌍뿐)
    } else {
      await c.goBackOrForward(steps: target - cur);
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(widget.langCode);
    return PopScope(
      // 하드웨어 백키: WebView 내부 history 우선, 없으면 화면 종료(다리 복귀)
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final c = _controller;
        final navigator = Navigator.of(context);
        if (c != null && await c.canGoBack()) {
          if (_isFindJob) {
            // FindJob: global↔global-m 리다이렉트가 히스토리를 쌓아 goBack 루프 발생 → 전용 처리
            await _handleBackFindJob(navigator);
          } else {
            c.goBack();
          }
        } else {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.black,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: s.close,
            onPressed: () => Navigator.of(context).pop(), // 즉시 다리 복귀
          ),
          centerTitle: true,
          // Dari 워드마크 — 탭하면 Dari로 복귀 ("Dari로 이동" 개념)
          title: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Image.asset('assets/wordmark.png', height: 20),
          ),
          bottom: (_progress > 0 && _progress < 1)
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress, minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: AppColors.carrot,
                  ),
                )
              : null,
        ),
        // 하단 SafeArea: OS 내비게이션 바가 사이트 하단을 가려 안 눌리는 문제 방지
        body: SafeArea(
          top: false,
          bottom: true,
          child: _failed ? _errorView() : _webView(),
        ),
      ),
    );
  }

  /// 진입 URL: 언어 경로 치환(WorkVisa·Jobploy·WorkOn·Kowork) + FindJob 모바일 호스트
  String get _entryUrl => SiteLang.entryUrl(widget.url, widget.langCode);

  Widget _webView() {
    // 쿠키 사전 세팅이 끝나기 전엔 로드하지 않음 (언어 적용 보장)
    if (!_langReady) {
      return const Center(
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.carrot),
        ),
      );
    }
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_entryUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: true,
        // iOS: 새창(target=_blank/window.open) 링크가 죽지 않도록 onCreateWindow로 받음
        supportMultipleWindows: true,
        // iOS/WKWebView: 이 플래그가 true여야 shouldOverrideUrlLoading 호출됨 (Android는 자동)
        useShouldOverrideUrlLoading: true,
      ),
      onWebViewCreated: (c) => _controller = c,
      // 새창 요청은 같은 웹뷰에서 열어 지원 흐름 유지
      onCreateWindow: (c, createWindowAction) async {
        final u = createWindowAction.request.url;
        if (u != null) {
          await c.loadUrl(urlRequest: URLRequest(url: u));
        }
        return false;
      },
      onProgressChanged: (c, p) {
        if (mounted) setState(() => _progress = p / 100);
      },
      onLoadStop: (c, url) async {
        // JobnShop: localStorage 언어 주입 (값 다를 때만 리로드 → 루프 없음)
        final js = SiteLang.postLoadJs(url?.toString() ?? widget.url, widget.langCode);
        if (js != null) await c.evaluateJavascript(source: js);
      },
      onReceivedError: (c, req, err) {
        // 메인 프레임 로드 실패만 폴백 처리
        if (req.isForMainFrame == true && mounted) {
          setState(() => _failed = true);
        }
      },
      // intent://, market://, 앱스킴 등 비-http 이동 차단 (스토어 이탈 방지)
      shouldOverrideUrlLoading: (c, action) async {
        final u = action.request.url?.toString() ?? '';
        if (!u.startsWith('http')) {
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.gray300),
            const SizedBox(height: 16),
            const Text('페이지를 열 수 없어요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _openExternal,
              style: FilledButton.styleFrom(backgroundColor: AppColors.carrot),
              child: const Text('외부 브라우저로 열기'),
            ),
          ],
        ),
      ),
    );
  }
}
