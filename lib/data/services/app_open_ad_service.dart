import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/ad_helper.dart';

class AppOpenAdService {
  static final AppOpenAdService _instance = AppOpenAdService._();
  factory AppOpenAdService() => _instance;
  AppOpenAdService._();

  static String get _adUnitId => AdHelper.appOpenId;
  static const _prefsKey = 'last_app_open_ad_date'; // 하루 1회(날짜 영속)

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _shownThisSession = false; // 세션당 1회 (앱 재시작 시 리셋)

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

  /// 앱 재실행/백그라운드 복귀 시 호출 — 세션당 1회 + 하루 1회(최소 보장)
  /// [maxWait] > 0 이면, 노출 대상인데 광고가 아직 로드 안 됐을 때 그 시간만큼만 로드를 기다림.
  /// (스플래시에서만 사용 — 스킵 대상이면 절대 기다리지 않아 모든 스플래시가 느려지지 않음)
  Future<void> showIfAvailable({Duration maxWait = Duration.zero}) async {
    if (_isShowingAd) return;

    // 스킵 판정 먼저 — 스킵이면 대기 없이 즉시 종료(모든 스플래시 지연 방지)
    // 세션당 1회 + 하루 1회 결합: 둘 다 이미 봤을 때만 스킵
    // (새 세션이면 뜸 / 날짜 바뀌면 웜 세션이어도 뜸)
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final shownToday = prefs.getString(_prefsKey) == today;
    if (_shownThisSession && shownToday) return;

    // 노출 대상인데 광고 미준비면, maxWait 동안만 로드 대기
    if (_appOpenAd == null) {
      loadAd();
      var waited = Duration.zero;
      const step = Duration(milliseconds: 200);
      while (_appOpenAd == null && waited < maxWait) {
        await Future.delayed(step);
        waited += step;
      }
      if (_appOpenAd == null) return; // 그래도 없으면 포기(다음 트리거에 노출)
    }

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

    _shownThisSession = true;
    await prefs.setString(_prefsKey, today);
    _appOpenAd!.show();
  }
}

final appOpenAdService = AppOpenAdService();
