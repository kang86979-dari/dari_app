import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 디버그 모드에서는 테스트 광고 ID, 릴리즈에서는 운영 ID 반환
class AdHelper {
  AdHelper._();

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
