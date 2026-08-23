import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_config.dart';
import '../constants/colors.dart';
import 'ad_helper.dart';
import '../../data/services/analytics_service.dart';

/// 리스트 화면마다 1개 생성. 슬롯 인덱스별 NativeAd를 캐싱하고 동시 생존 수를 제한한다.
/// 리스트 리사이클로 인한 재요청 폭증(요청 대비 노출률 저하의 핵심 원인)을 막는 것이 목적.
class NativeAdController {
  NativeAdController({this.maxLive = AdConfig.maxLiveNativeAds});

  final int maxLive;

  final Map<int, NativeAd> _ads = {};
  final Set<int> _loaded = {};
  final Map<int, VoidCallback> _cbs = {}; // 슬롯별 최신 rebuild 콜백
  final List<int> _lru = []; // 최근 요청 순서(뒤가 최신)

  bool isLoaded(int slot) => _loaded.contains(slot);
  NativeAd? adFor(int slot) => _ads[slot];

  /// 슬롯 광고 확보: 이미 있으면 재사용, 없으면 생성/로드.
  /// [onChanged]는 로드 완료/실패 시 위젯 rebuild용 (remount마다 최신 콜백으로 갱신).
  void ensure(int slot, VoidCallback onChanged) {
    _cbs[slot] = onChanged;
    _touch(slot);
    if (_ads.containsKey(slot)) return;

    final adUnitId = AdHelper.nativeId;
    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: _style(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _loaded.add(slot);
          analytics.log('ad_native_loaded', {'ad_unit_id': adUnitId});
          _cbs[slot]?.call();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('❌ NativeAd failed: code=${error.code}, msg=${error.message}');
          }
          ad.dispose();
          _ads.remove(slot);
          _loaded.remove(slot);
          _lru.remove(slot);
          analytics.log('ad_native_failed', {
            'ad_unit_id': adUnitId,
            'error_code': error.code,
            'error_message': error.message,
          });
          analytics.log('ad_fail_code_${error.code}');
          _cbs[slot]?.call();
        },
        onAdImpression: (_) =>
            analytics.log('ad_native_impression', {'ad_unit_id': adUnitId}),
        onAdClicked: (_) => AdHelper.markAdClicked(),
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

  /// 상한 초과 시 가장 오래 전에 요청된 것부터 해제(현재 슬롯은 보호).
  /// 리스트 빌더는 화면 근처 항목만 build하므로, 오래된 슬롯 = 화면 밖 = 안전하게 해제 가능.
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

  /// 공고 카드 느낌에 맞춘 medium 템플릿 스타일 (당근색 CTA + 흰 배경 + 라운드).
  static NativeTemplateStyle _style() => NativeTemplateStyle(
        // small = 아이콘+제목+본문+CTA 컴팩트(큰 미디어 이미지 없음) → 공고 카드에 가까움
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        // 라운드/테두리는 감싸는 Container가 단독 담당(이중 테두리 방지) → 여기선 0
        cornerRadius: 0.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.carrot,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.black,
          style: NativeTemplateFontStyle.bold,
          size: 15.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.gray600,
          size: 13.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.gray400,
          size: 12.0,
        ),
      );
}
