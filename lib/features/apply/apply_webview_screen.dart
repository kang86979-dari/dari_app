import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/app_strings.dart';

/// 지원하기 인앱 WebView (프로덕션).
///
/// - 진입 시 사용자 언어로 자동 번역 (googtrans 쿠키 + Google 번역 위젯,
///   위젯 없는 사이트엔 element.js 직접 주입 → 전 사이트/16개 언어 커버)
/// - 하드웨어 백키: WebView 내부 뒤로, history 없으면 화면 종료(다리 복귀)
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

  /// 앱 언어코드 → Google 번역 코드 매핑 (대부분 동일)
  static String gtLang(String appLang) {
    const map = {'zh': 'zh-CN', 'zh-yue': 'zh-TW'};
    return map[appLang] ?? appLang;
  }

  @override
  State<ApplyWebViewScreen> createState() => _ApplyWebViewScreenState();
}

class _ApplyWebViewScreenState extends State<ApplyWebViewScreen> {
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _failed = false;

  String get _lang => ApplyWebViewScreen.gtLang(widget.langCode);

  /// 현재 페이지를 사용자 언어로 번역 (Android 전용 — Google 번역 위젯 주입 후 구동).
  /// iOS는 이 화면을 쓰지 않고 인앱 사파리(SFSafariViewController)로 열어 네이티브 번역 사용.
  Future<void> _translate() async {
    final c = _controller;
    if (c == null || _lang == 'ko') return; // 한국어면 번역 불필요
    final js = '''
      (function(){
        var lang='$_lang';
        document.cookie='googtrans=/auto/'+lang+';path=/';
        // Google 번역 상단 바 숨김 (번역은 유지, 바만 제거)
        if(!document.getElementById('dari-gte-css')){
          var st=document.createElement('style'); st.id='dari-gte-css';
          st.textContent='.goog-te-banner-frame,.goog-te-banner-frame.skiptranslate,#goog-gt-tt,.goog-tooltip,.goog-te-balloon-frame{display:none!important;visibility:hidden!important;}'
            +'body{top:0!important;position:static!important;}.skiptranslate{display:none!important;}';
          (document.head||document.documentElement).appendChild(st);
        }
        if(!document.querySelector('.goog-te-combo')){
          window.googleTranslateElementInit=function(){
            new google.translate.TranslateElement({pageLanguage:'auto', autoDisplay:false}, 'dari-gte');
          };
          if(!document.getElementById('dari-gte')){
            var d=document.createElement('div'); d.id='dari-gte'; d.style.display='none'; document.body.appendChild(d);
          }
          if(!document.getElementById('dari-gte-js')){
            var s=document.createElement('script'); s.id='dari-gte-js';
            s.src='https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit';
            document.body.appendChild(s);
          }
        }
        var n=0;
        var iv=setInterval(function(){
          n++;
          var combo=document.querySelector('.goog-te-combo');
          if(combo){ combo.value=lang; combo.dispatchEvent(new Event('change')); clearInterval(iv); }
          if(n>30) clearInterval(iv);
        }, 500);
      })();
    ''';
    await c.evaluateJavascript(source: js);
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
          c.goBack();
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

  Widget _webView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
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
        await _translate();
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
