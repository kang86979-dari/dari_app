import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

/// [DEV 전용] 지원하기 WebView 분석 하버스트.
///
/// 목적: K-HIRE 등 로그인/SNS 벽 뒤 화면의 HTML을 세션(쿠키) 안에서 그대로 덤프해
/// 셀렉터를 분석하기 위한 임시 도구. 최종 지원하기 기능의 토대(WebView + JS 주입).
///
/// - 쿠키 유지 → 한 번 로그인하면 이후 화면 계속 열람 가능
/// - "덤프" → 현재 화면 URL + outerHTML을 앱 외부저장소 파일로 저장 (adb pull 로 회수)
/// - JS 팝업(alert/confirm)·비-http 이동(intent://, market:// 등)을 로그 → 팝업 정체 파악
class ApplyWebViewDebugScreen extends StatefulWidget {
  const ApplyWebViewDebugScreen({super.key});

  @override
  State<ApplyWebViewDebugScreen> createState() => _ApplyWebViewDebugScreenState();
}

class _ApplyWebViewDebugScreenState extends State<ApplyWebViewDebugScreen> {
  static const _startUrl = 'https://m.khire.co.kr';

  InAppWebViewController? _controller;
  final _urlCtrl = TextEditingController(text: _startUrl);
  String _currentUrl = _startUrl;
  String _status = '';
  int _dumpSeq = 0;
  double _progress = 0;
  bool _autoConfirm = false; // true면 다음 JS confirm(로그인 필요)을 자동 "예"
  final _methodCtrl = TextEditingController(text: 'applyLayer__link--simple');
  final _langCtrl = TextEditingController(text: 'en');

  void _log(String msg) {
    debugPrint('🕸️ [ApplyWV] $msg');
    if (mounted) setState(() => _status = msg);
  }

  Future<void> _go() {
    final u = _urlCtrl.text.trim();
    if (u.isEmpty) return Future.value();
    return _controller?.loadUrl(
          urlRequest: URLRequest(url: WebUri(u.startsWith('http') ? u : 'https://$u')),
        ) ??
        Future.value();
  }

  /// 현재 화면 URL + outerHTML을 파일로 저장
  Future<void> _dumpHtml() async {
    final c = _controller;
    if (c == null) return;
    try {
      final url = (await c.getUrl())?.toString() ?? _currentUrl;
      final title = (await c.getTitle()) ?? '';
      final html = await c.evaluateJavascript(source: 'document.documentElement.outerHTML');
      final dir = await getExternalStorageDirectory(); // /sdcard/Android/data/<pkg>/files
      _dumpSeq++;
      // 파일명에 타임스탬프 포함 → 화면 재진입/카운터 리셋에도 덮어쓰기 없음 (가입은 1회성)
      final t = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final stamp = '${two(t.hour)}${two(t.minute)}${two(t.second)}_${t.millisecond.toString().padLeft(3, '0')}';
      final name = 'dump_${_dumpSeq.toString().padLeft(2, '0')}_$stamp.html';
      final file = File('${dir!.path}/$name');
      await file.writeAsString(
        '<!-- URL: $url -->\n<!-- TITLE: $title -->\n${html ?? ''}',
      );
      _log('덤프 저장: ${file.path} (${(html?.length ?? 0)} chars)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장됨: $name  ($title)')),
        );
      }
    } catch (e) {
      _log('덤프 실패: $e');
    }
  }

  /// 지원하기(.btnApply) 자동 클릭 → 선택 방법 링크 클릭 → 로그인 확인 팝업 자동 수락
  Future<void> _autoApply() async {
    final c = _controller;
    if (c == null) return;
    final sel = _methodCtrl.text.trim();
    // ① 지원하기(.btnApply) → ② 방법 링크 → ③ 로그인 팝업(.dialog-pop) "예"(.yes_confirm) 자동 클릭
    // 로그인 팝업은 native confirm이 아니라 K-HIRE HTML 오버레이(.dialog-pop)라 DOM 클릭으로 처리
    final js = '''
      (function(){
        var b = document.querySelector('.btnApply');
        if(!b){ return 'NO_BTN_APPLY'; }
        b.click();
        setTimeout(function(){
          var m = document.querySelector('.$sel');
          if(m){ m.click(); }
          setTimeout(function(){
            var yes = document.querySelector('.dialog-pop__button.yes_confirm');
            if(yes){ yes.click(); }
          }, 900);
        }, 700);
        return 'CLICKED_APPLY';
      })();
    ''';
    final r = await c.evaluateJavascript(source: js);
    _log('자동지원: btnApply=$r → 방법 .$sel → 로그인팝업 예(.yes_confirm) 자동클릭');
  }

  /// 로그인 화면 위에 분필(손그림) 스타일 가이드 오버레이 주입.
  /// 각 요소(아이디/비번/로그인/아이디찾기/비번찾기/가입하기)에 흔들리는 박스 + 설명.
  Future<void> _showGuide() async {
    final c = _controller;
    if (c == null) return;
    const js = r'''
    (function(){
      var ID='dari-guide', RID='dari-guide-reopen';
      function rm(id){ var e=document.getElementById(id); if(e) e.remove(); }
      var T=[
        {s:'#userid',    t:'① 아이디 입력'},
        {s:'#passwd',    t:'② 비밀번호 입력'},
        {s:'#btnLogin',  t:'③ 로그인 누르기'},
        {s:'.idSearch',  t:'아이디 찾기'},
        {s:'.pwdSearch', t:'비밀번호 찾기'},
        {s:'.join',      t:'계정 없으면 가입하기'}
      ];
      var PAL=['#ffffff','#fff3a0','#ffcfe6','#bdefff','#ffffff','#c9ffd0'];
      var CHALK='<defs><filter id="chalk" x="-30%" y="-30%" width="160%" height="160%">'
        +'<feTurbulence type="fractalNoise" baseFrequency="0.018" numOctaves="2" seed="7" result="w"/>'
        +'<feDisplacementMap in="SourceGraphic" in2="w" scale="6" result="d"/>'
        +'<feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="4" result="g"/>'
        +'<feColorMatrix in="g" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 -1.7 1.2" result="ga"/>'
        +'<feComposite in="d" in2="ga" operator="in"/></filter></defs>';
      window.__dariGuideShow=function(){
        rm(ID); rm(RID);
        var W=window.innerWidth, H=Math.max(document.documentElement.scrollHeight, window.innerHeight);
        var ns='http://www.w3.org/2000/svg';
        var ov=document.createElement('div'); ov.id=ID;
        ov.style.cssText='position:absolute;left:0;top:0;width:100%;height:'+H+'px;z-index:2147483646;pointer-events:none;';
        var bg=document.createElement('div');
        bg.style.cssText='position:absolute;inset:0;background:rgba(10,14,26,0.55);';
        ov.appendChild(bg);
        var svg=document.createElementNS(ns,'svg');
        svg.setAttribute('width',W); svg.setAttribute('height',H);
        svg.style.cssText='position:absolute;left:0;top:0;overflow:visible;';
        svg.innerHTML=CHALK;
        ov.appendChild(svg);
        var found=0;
        T.forEach(function(o,i){
          var el=document.querySelector(o.s); if(!el) return; found++;
          var r=el.getBoundingClientRect();
          var x=r.left+window.scrollX, y=r.top+window.scrollY, w=r.width, h=r.height, p=7;
          var col=PAL[i%PAL.length];
          var rc=document.createElementNS(ns,'rect');
          rc.setAttribute('x',x-p); rc.setAttribute('y',y-p);
          rc.setAttribute('width',w+p*2); rc.setAttribute('height',h+p*2);
          rc.setAttribute('rx',13); rc.setAttribute('fill','none');
          rc.setAttribute('stroke',col); rc.setAttribute('stroke-width','6');
          rc.setAttribute('stroke-linecap','round'); rc.setAttribute('filter','url(#chalk)');
          svg.appendChild(rc);
          var tx=x+2, ty=y-p-12; if(ty<52){ ty=y+h+p+28; }
          var t=document.createElementNS(ns,'text');
          t.setAttribute('x',tx); t.setAttribute('y',ty);
          t.setAttribute('fill',col); t.setAttribute('filter','url(#chalk)');
          t.setAttribute('font-size','21'); t.setAttribute('font-weight','700');
          t.setAttribute('font-family',"'Comic Sans MS','Chalkboard SE',cursive");
          t.textContent=o.t;
          svg.appendChild(t);
        });
        var cb=document.createElement('div'); cb.textContent='✕ 닫기';
        cb.style.cssText='position:fixed;right:12px;top:72px;z-index:2147483647;pointer-events:auto;background:#e35d2a;color:#fff;padding:8px 16px;border-radius:20px;font-family:cursive;font-size:15px;box-shadow:0 2px 8px rgba(0,0,0,0.5);';
        cb.setAttribute('onclick','window.__dariGuideHide()');
        ov.appendChild(cb);
        document.body.appendChild(ov);
        return found;
      };
      window.__dariGuideHide=function(){
        rm(ID);
        var rb=document.createElement('div'); rb.id=RID;
        rb.textContent='💡 가이드 다시 보기';
        rb.style.cssText='position:fixed;right:12px;bottom:18px;z-index:2147483647;pointer-events:auto;background:#e35d2a;color:#fff;padding:11px 18px;border-radius:24px;font-family:cursive;font-size:15px;box-shadow:0 3px 10px rgba(0,0,0,0.5);';
        rb.setAttribute('onclick','window.__dariGuideShow()');
        document.body.appendChild(rb);
      };
      return 'GUIDE_ON:'+window.__dariGuideShow();
    })();
    ''';
    final r = await c.evaluateJavascript(source: js);
    _log('가이드: $r');
  }

  /// K-HIRE 구글 번역 위젯을 사용자 언어로 세팅.
  /// googtrans 쿠키(/auto/{lang}) + .goog-te-combo 구동. 쿠키는 이후 페이지에도 유지.
  Future<void> _setLang() async {
    final c = _controller;
    if (c == null) return;
    final lang = _langCtrl.text.trim();
    // 구글번역 위젯이 있으면 구동, 없으면 우리가 직접 주입 → 어떤 사이트든 번역
    final js = '''
      (function(){
        var lang='$lang';
        document.cookie='googtrans=/auto/'+lang+';path=/';
        var hasGte = !!document.querySelector('.goog-te-combo');
        if(!hasGte){
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
        return 'LANG_SET:'+lang+' (inject='+(!hasGte)+')';
      })();
    ''';
    final r = await c.evaluateJavascript(source: js);
    _log('언어세팅: $r (위젯 로드까지 최대 ~15초)');
  }

  /// 실제 앱 진입 방식: 로드 "전에" googtrans 쿠키를 세팅한 뒤 URL 로드
  /// → 첫 화면부터 사용자 언어로 번역된 상태로 진입.
  Future<void> _enterWithLang() async {
    final c = _controller;
    if (c == null) return;
    final lang = _langCtrl.text.trim();
    final u = _urlCtrl.text.trim();
    if (lang.isEmpty || u.isEmpty) return;
    final cm = CookieManager.instance();
    // 로드 전에 쿠키 심기 (khire.co.kr 도메인 전체)
    await cm.setCookie(
      url: WebUri('https://m.khire.co.kr'),
      name: 'googtrans',
      value: '/auto/$lang',
      domain: '.khire.co.kr',
      path: '/',
    );
    _log('번역진입: 쿠키 googtrans=/auto/$lang 세팅 → 로드 시작');
    await c.loadUrl(
      urlRequest: URLRequest(url: WebUri(u.startsWith('http') ? u : 'https://$u')),
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _methodCtrl.dispose();
    _langCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 하드웨어 백키: WebView 내부 history가 있으면 뒤로, 없을 때만 화면(다리) 종료
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
        title: const Text('[DEV] Apply WebView'),
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back), tooltip: '뒤로',
              onPressed: () => _controller?.goBack()),
          IconButton(icon: const Icon(Icons.arrow_forward), tooltip: '앞으로',
              onPressed: () => _controller?.goForward()),
          IconButton(icon: const Icon(Icons.refresh), tooltip: '새로고침',
              onPressed: () => _controller?.reload()),
          IconButton(icon: const Icon(Icons.gesture), tooltip: '분필 가이드',
              onPressed: _showGuide),
          IconButton(icon: const Icon(Icons.download), tooltip: 'HTML 덤프',
              onPressed: _dumpHtml),
        ],
      ),
      body: Column(
        children: [
          // URL 바
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlCtrl,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onSubmitted: (_) => _go(),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(onPressed: _go, child: const Text('이동')),
              ],
            ),
          ),
          // 자동지원: 지원하기+방법 자동클릭 + 로그인팝업 자동수락
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _methodCtrl,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '방법 클래스',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.tonal(onPressed: _autoApply, child: const Text('자동지원')),
              ],
            ),
          ),
          // 언어 세팅: googtrans 쿠키 + 구글번역 위젯 구동
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _langCtrl,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '언어(en/vi..)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.tonal(onPressed: _setLang, child: const Text('언어적용')),
                const SizedBox(width: 6),
                FilledButton(onPressed: _enterWithLang, child: const Text('번역진입')),
                const Spacer(),
              ],
            ),
          ),
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(value: _progress, minHeight: 2),
          // 상태 로그
          if (_status.isNotEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(_status, style: const TextStyle(fontSize: 11), maxLines: 2),
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_startUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
                supportMultipleWindows: false,
                useOnLoadResource: false,
                // 모바일 UA (고객 화면과 동일)
                userAgent:
                    'Mozilla/5.0 (Linux; Android 14; SM-S911N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
              ),
              onWebViewCreated: (c) => _controller = c,
              onLoadStart: (c, url) {
                _currentUrl = url?.toString() ?? '';
                _urlCtrl.text = _currentUrl;
              },
              onLoadStop: (c, url) {
                _currentUrl = url?.toString() ?? '';
                _log('로드 완료: $_currentUrl');
              },
              onProgressChanged: (c, p) {
                if (mounted) setState(() => _progress = p / 100);
              },
              // JS 팝업 정체 파악 (alert/confirm 이면 로그 + 기본 다이얼로그 표시)
              onJsAlert: (c, req) async {
                _log('JS alert: ${req.message}');
                return null;
              },
              onJsConfirm: (c, req) async {
                _log('JS confirm: ${req.message}');
                if (_autoConfirm) {
                  _autoConfirm = false;
                  _log('→ 자동 수락(예)');
                  return JsConfirmResponse(
                    handledByClient: true,
                    action: JsConfirmResponseAction.CONFIRM,
                  );
                }
                return null; // 기본 다이얼로그 → 사용자가 선택
              },
              // 화면 이동 로그. 비-http(intent://, market://, 앱스킴)는 차단해 웹 유지
              shouldOverrideUrlLoading: (c, action) async {
                final u = action.request.url?.toString() ?? '';
                if (!u.startsWith('http')) {
                  _log('🚫 비-http 이동 차단: $u');
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}
