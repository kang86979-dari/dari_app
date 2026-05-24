import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/ad_helper.dart';

class AppOpenAdService {
  static final AppOpenAdService _instance = AppOpenAdService._();
  factory AppOpenAdService() => _instance;
  AppOpenAdService._();

  static String get _adUnitId => AdHelper.appOpenId;
  static const _prefsKey = 'last_app_open_ad_date';

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  /// 광고 로드
  void loadAd() {
    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (_) {
          _appOpenAd = null;
        },
      ),
    );
  }

  /// 앱 재실행 시 호출 — 하루 1회만 표시
  Future<void> showIfAvailable() async {
    if (_isShowingAd || _appOpenAd == null) return;

    // 하루 1회 체크
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefsKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastShown == today) return;

    _isShowingAd = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // 다음을 위해 다시 로드
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    await prefs.setString(_prefsKey, today);
    _appOpenAd!.show();
  }
}

final appOpenAdService = AppOpenAdService();
