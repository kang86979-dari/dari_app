import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 사이트별 언어 사전 세팅 (2026-08-14 10개 사이트 전수 실측 기반).
///
/// 정책: 지원하기 WebView/사파리 진입 시점에 "항상 앱 언어"로 미리 세팅한다.
/// 전부 각 사이트가 설계한 정식 메커니즘(자체 쿠키/URL 로케일/localStorage)을
/// 사용하므로 페이지 구조 변경에 강하고, 실패해도 한국어 원문 노출뿐(무해).
///
/// - 쿠키 그룹: K-HIRE·FindJob·KoMate(googtrans /auto/), K-Work(googtrans /ko/),
///   TalentLink(lang=KR/EN/VN) — 로드 전 CookieManager로 심음 (Android WebView 전용)
/// - URL 그룹: WorkVisa·Jobploy·WorkOn·Kowork — 진입 URL의 언어 경로 치환
///   (서버 렌더 즉시 적용, iOS 사파리에도 동일 적용 가능)
/// - JobnShop: localStorage(resume_lang) 로드 후 주입 + 리로드 1회 (자가 가드)
class SiteLang {
  SiteLang._();

  // ── 사이트별 지원 언어 화이트리스트 (앱 언어코드 기준, 미지원은 en 폴백) ──

  /// 구글번역 위젯 계열 공통: 앱 언어코드 → 구글 언어코드
  static const _googleCode = {
    'zh': 'zh-CN',
    'zh-yue': 'zh-TW',
    'fil': 'tl',
    'he': 'iw',
  };

  static String _toGoogle(String appLang) => _googleCode[appLang] ?? appLang;

  /// K-HIRE 위젯 언어 (si 미지원 → en)
  static const _khireLangs = {
    'en', 'vi', 'zh-CN', 'zh-TW', 'th', 'uz', 'km', 'mn', 'ne', 'my', 'bn',
    'ru', 'hi', 'ja', 'id', 'tl', 'ur', 'iw', 'kk', 'ms', 'ar', 'es', 'fr',
    'de', 'it', 'pl', 'pt', 'tr', 'am',
  };

  /// K-Work 위젯 언어 (km·my 미지원 → en)
  static const _kworkLangs = {
    'en', 'hi', 'zh-CN', 'zh-TW', 'id', 'vi', 'nl', 'ru', 'ur', 'es', 'th',
    'bn', 'tr', 'ms', 'mn', 'uz', 'kk', 'fr', 'ga', 'ja', 'ne', 'fa', 'pt',
    'de', 'ar', 'hu', 'si',
  };

  /// FindJob 34개 / KoMate 30개 — 우리 언어셋 전부 커버 (별도 화이트리스트 불필요,
  /// 구글 코드 변환만 적용)

  /// WorkVisa URL 로케일 (미지원 → en). zh는 평문 'zh' 사용.
  static const _workvisaLangs = {'ko', 'en', 'ja', 'zh', 'vi', 'th', 'mn', 'uz'};

  /// Jobploy URL 로케일 — ⚠️ 미지원 경로는 404라 화이트리스트 필수
  static const _jobployLangs = {
    'ko', 'en', 'vi', 'mn', 'uz', 'id', 'th', 'ne', 'ja', 'zh', 'my',
  };

  /// JobnShop resume_lang (hi 미지원 → en)
  static const _jobnshopLangs = {
    'ko', 'en', 'vi', 'zh', 'th', 'ne', 'km', 'uz', 'my', 'mn', 'id', 'ru',
    'bn', 'si', 'ja', 'kk', 'ky', 'lo', 'tg', 'tl', 'ur', 'tet',
  };

  /// iOS에서도 인앱 WebView를 쓸 사이트 (기본은 인앱 사파리).
  /// 쿠키/localStorage 방식은 사파리에 사전 세팅이 불가능한데, 이 사이트들은
  /// 기기 언어도 안 따라가 무조건 한국어로 떠서 WebView+세팅이 필수.
  /// (자체 번역 22~34개 언어 보유라 사파리 네이티브 번역을 잃어도 손해 없음.
  ///  URL 그룹(WorkVisa·Jobploy·WorkOn·Kowork)은 사파리 유지 — URL 세팅이 되고,
  ///  ko·en뿐인 WorkOn·Kowork은 사파리 aA 번역으로 소수언어 보완 가능)
  static bool useWebViewOnIOS(String url) =>
      url.contains('khire.co.kr') ||
      url.contains('findjob.co.kr') ||
      url.contains('komate.saramin.co.kr') ||
      url.contains('k-work.or.kr') ||
      url.contains('talent-link.co.kr') ||
      url.contains('jobnshop.com');

  // ── 진입 URL 변환 (URL 그룹 + FindJob 모바일 호스트) ──
  /// iOS 사파리 경로에서도 사용 — 언어와 무관한 호스트 정리(FindJob) 포함.
  static String entryUrl(String url, String appLang) {
    var u = url;

    // FindJob: 데스크톱 호스트로 열면 global-m으로 JS 리다이렉트하며 히스토리
    // 쌍을 만들어 백키 루프 발생 → 처음부터 모바일 호스트로 (언어 무관)
    u = u.replaceFirst('://global.findjob.co.kr', '://global-m.findjob.co.kr');

    if (appLang == 'ko') return u; // 한국어는 원문 그대로

    if (u.contains('workvisa.co.kr')) {
      final l = _workvisaLangs.contains(appLang) ? appLang : 'en';
      return u.replaceFirst('/ko/', '/$l/');
    }
    if (u.contains('jobploy.kr')) {
      final l = _jobployLangs.contains(appLang) ? appLang : 'en';
      return u.replaceFirst('/ko/', '/$l/');
    }
    if (u.contains('workon.net')) {
      // ko/en 2개뿐 — 비한국어는 전부 en
      return u.replaceFirst('/ko/', '/en/');
    }
    if (u.contains('kowork.kr')) {
      // /post/{id} → /en/post/{id} (미지원 코드도 서버가 en으로 308 폴백하지만 직접 en 지정)
      return u.replaceFirst(RegExp(r'kowork\.kr/(ko/)?'), 'kowork.kr/en/');
    }
    return u;
  }

  /// 같은 이름의 쿠키가 host 전용/도메인 양쪽 스코프에 병존하면 브라우저가 둘 다
  /// 보내고 사이트는 먼저 오는(옛) 값을 집는다 → 반드시 양쪽 삭제 후 세팅.
  static Future<void> _resetCookie(
    CookieManager cm,
    String host,
    String name,
    String value, {
    String? domain,
  }) async {
    final uri = WebUri('https://$host');
    // host 전용 + 도메인 스코프 둘 다 삭제 (없어도 무해)
    await cm.deleteCookie(url: uri, name: name, path: '/');
    if (domain != null) {
      await cm.deleteCookie(url: uri, name: name, domain: domain, path: '/');
    }
    await cm.setCookie(
      url: uri, name: name, value: value, domain: domain, path: '/',
    );
  }

  // ── 로드 전 쿠키 세팅 (Android WebView 전용) ──
  /// InAppWebView 로드 전에 호출. 실패해도 무해(원문 노출)라 예외는 삼킴.
  static Future<void> presetCookies(String url, String appLang) async {
    if (appLang == 'ko') return;
    final cm = CookieManager.instance();
    try {
      if (url.contains('khire.co.kr')) {
        final g = _toGoogle(appLang);
        final l = _khireLangs.contains(g) ? g : 'en';
        // 사이트 초기화 JS가 host-only googtrans를 지우므로 도메인 쿠키로.
        // signlang도 함께 — 이전 값이 남으면 사이트가 그 언어로 되돌림.
        await _resetCookie(cm, 'm.khire.co.kr', 'googtrans', '/auto/$l',
            domain: '.khire.co.kr');
        await _resetCookie(cm, 'm.khire.co.kr', 'signlang', l,
            domain: '.khire.co.kr');
      } else if (url.contains('findjob.co.kr')) {
        final g = _toGoogle(appLang); // 34개 언어 — 우리 셋 전부 지원
        for (final name in ['googtrans', '__googtrans']) {
          await _resetCookie(cm, 'global-m.findjob.co.kr', name, '/auto/$g',
              domain: '.findjob.co.kr');
        }
      } else if (url.contains('komate.saramin.co.kr')) {
        final g = _toGoogle(appLang); // 30개 언어 — 우리 셋 전부 지원
        // host-only 쿠키 (사이트가 domain 없이 기록)
        await _resetCookie(cm, 'komate.saramin.co.kr', 'googtrans', '/auto/$g');
        await _resetCookie(
            cm, 'komate.saramin.co.kr', 'IS_LANGUAGE_SELECTION_SHOWN', 'true');
      } else if (url.contains('k-work.or.kr')) {
        final g = _toGoogle(appLang);
        final l = _kworkLangs.contains(g) ? g : 'en';
        // K-Work는 /ko/{lang} 형식 + 당일 자정(KST) 만료라 매 진입 재주입이 정답
        await _resetCookie(cm, 'k-work.or.kr', 'googtrans', '/ko/$l');
      } else if (url.contains('talent-link.co.kr')) {
        // KR/EN/VN 대문자 — 쿠키 있으면 언어선택 모달도 안 뜸
        final l = appLang == 'vi' ? 'VN' : 'EN';
        await _resetCookie(cm, 'talent-link.co.kr', 'lang', l);
      }
    } catch (_) {
      // 쿠키 실패 = 원문 노출뿐. 사용자는 사이트 자체 언어 UI로 변경 가능.
    }
  }

  // ── JobnShop: 로드 후 localStorage 주입 (값이 다를 때만 리로드 → 루프 없음) ──
  static String? postLoadJs(String url, String appLang) {
    if (appLang == 'ko' || !url.contains('jobnshop.com')) return null;
    final l = _jobnshopLangs.contains(appLang) ? appLang : 'en';
    return '''
      (function(){
        try{
          if(localStorage.getItem('resume_lang')!=='$l'){
            localStorage.setItem('resume_lang','$l');
            location.reload();
          }
        }catch(e){}
      })();
    ''';
  }
}
