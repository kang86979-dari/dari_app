import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 디버그 모드에서는 테스트 광고 ID, 릴리즈에서는 운영 ID 반환 (플랫폼별 분기)
class AdHelper {
  AdHelper._();

  // 광고 클릭 → 외부 이탈 → 복귀 시 홈 리스트 갱신/앱오픈광고 스킵용 플래그
  static bool _adClicked = false;

  static void markAdClicked() => _adClicked = true;

  /// resume 시 1회 소비 — true면 광고 클릭으로 인한 복귀
  static bool consumeAdClicked() {
    final v = _adClicked;
    _adClicked = false;
    return v;
  }

  // Google 공식 iOS 테스트 광고 단위 ID
  static const _iosTestBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _iosTestInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _iosTestAppOpen = 'ca-app-pub-3940256099942544/5575463023';

  static String get bannerId {
    if (Platform.isIOS) {
      // TODO(iOS): AdMob iOS 앱 생성 후 .env에 AD_BANNER_ID_IOS 추가
      return kDebugMode
          ? _iosTestBanner
          : dotenv.env['AD_BANNER_ID_IOS'] ?? _iosTestBanner;
    }
    return kDebugMode
        ? dotenv.env['AD_BANNER_ID_TEST']!
        : dotenv.env['AD_BANNER_ID']!;
  }

  static String get interstitialId {
    if (Platform.isIOS) {
      // TODO(iOS): AdMob iOS 앱 생성 후 .env에 AD_INTERSTITIAL_ID_IOS 추가
      return kDebugMode
          ? _iosTestInterstitial
          : dotenv.env['AD_INTERSTITIAL_ID_IOS'] ?? _iosTestInterstitial;
    }
    return kDebugMode
        ? dotenv.env['AD_INTERSTITIAL_ID_TEST']!
        : dotenv.env['AD_INTERSTITIAL_ID']!;
  }

  static String get appOpenId {
    if (Platform.isIOS) {
      // TODO(iOS): AdMob iOS 앱 생성 후 .env에 AD_APP_OPEN_ID_IOS 추가
      return kDebugMode
          ? _iosTestAppOpen
          : dotenv.env['AD_APP_OPEN_ID_IOS'] ?? _iosTestAppOpen;
    }
    return kDebugMode
        ? dotenv.env['AD_APP_OPEN_ID_TEST']!
        : dotenv.env['AD_APP_OPEN_ID']!;
  }
}
