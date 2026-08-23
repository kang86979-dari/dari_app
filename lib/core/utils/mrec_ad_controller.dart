import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_config.dart';
import 'ad_helper.dart';
import '../../data/services/analytics_service.dart';

/// 리스트에 삽입되는 MREC(300x250) 배너를 화면 단위로 캐싱한다.
/// 리스트 리사이클로 인한 재요청 폭증(요청 대비 노출률 저하)을 막는 것이 목적.
class MrecAdController {
  MrecAdController({this.maxLive = AdConfig.maxLiveNativeAds});

  final int maxLive;

  final Map<int, BannerAd> _ads = {};
  final Set<int> _loaded = {};
  final Map<int, VoidCallback> _cbs = {};
  final List<int> _lru = [];

  bool isLoaded(int slot) => _loaded.contains(slot);
  BannerAd? adFor(int slot) => _ads[slot];

  /// 슬롯 광고 확보: 이미 있으면 재사용, 없으면 생성/로드.
  void ensure(int slot, VoidCallback onChanged) {
    _cbs[slot] = onChanged;
    _touch(slot);
    if (_ads.containsKey(slot)) return;

    final adUnitId = AdHelper.mrecId;
    final ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle, // 300x250 고정
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _loaded.add(slot);
          analytics.log('ad_native_loaded', {'ad_unit_id': adUnitId, 'format': 'mrec'});
          _cbs[slot]?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('❌ MREC failed: code=${error.code}, msg=${error.message}');
          }
          ad.dispose();
          _ads.remove(slot);
          _loaded.remove(slot);
          _lru.remove(slot);
          analytics.log('ad_native_failed', {
            'ad_unit_id': adUnitId,
            'format': 'mrec',
            'error_code': error.code,
            'error_message': error.message,
          });
          analytics.log('ad_fail_code_${error.code}');
          _cbs[slot]?.call();
        },
        onAdImpression: (_) =>
            analytics.log('ad_native_impression', {'ad_unit_id': adUnitId, 'format': 'mrec'}),
        onAdClicked: (_) => AdHelper.markAdClicked(),
        onAdOpened: (_) => AdHelper.markAdClicked(),
      ),
    );
    _ads[slot] = ad;
    ad.load();
    _enforceCap(protect: slot);
  }

  void _touch(int slot) {
    _lru.remove(slot);
    _lru.add(slot);
  }

  void _enforceCap({required int protect}) {
    while (_ads.length > maxLive) {
      final victim = _lru.firstWhere((s) => s != protect, orElse: () => -1);
      if (victim == -1) break;
      _lru.remove(victim);
      _ads.remove(victim)?.dispose();
      _loaded.remove(victim);
      _cbs.remove(victim);
    }
  }

  void disposeAll() {
    for (final ad in _ads.values) {
      ad.dispose();
    }
    _ads.clear();
    _loaded.clear();
    _cbs.clear();
    _lru.clear();
  }
}
