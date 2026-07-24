import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 디버그 모드에서는 테스트 광고 ID, 릴리즈에서는 운영 ID 반환
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

  static String get bannerId => kDebugMode
      ? dotenv.env['AD_BANNER_ID_TEST']!
      : dotenv.env['AD_BANNER_ID']!;

  static String get interstitialId => kDebugMode
      ? dotenv.env['AD_INTERSTITIAL_ID_TEST']!
      : dotenv.env['AD_INTERSTITIAL_ID']!;

  static String get appOpenId => kDebugMode
      ? dotenv.env['AD_APP_OPEN_ID_TEST']!
      : dotenv.env['AD_APP_OPEN_ID']!;
}
