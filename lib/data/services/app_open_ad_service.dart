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

  /// 앱 재실행/백그라운드 복귀 시 호출 — 하루 1회만 표시
  Future<void> showIfAvailable() async {
    if (_isShowingAd) return;

    // 광고가 없으면 다음을 위해 로드만 하고 종료
    if (_appOpenAd == null) {
      loadAd();
      return;
    }

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
        // 광고 닫힘 → resumed 발생 → 홈이 불필요하게 리로드하는 것 방지
        AdHelper.markAdClicked();
        loadAd(); // 다음을 위해 다시 로드
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        AdHelper.markAdClicked();
        loadAd();
      },
    );

    await prefs.setString(_prefsKey, today);
    _appOpenAd!.show();
  }
}

final appOpenAdService = AppOpenAdService();
