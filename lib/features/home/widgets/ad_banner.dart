import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/utils/ad_helper.dart';
import '../../../data/services/analytics_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final adUnitId = AdHelper.bannerId;
    print('🔵 BannerAd loading... adUnitId=$adUnitId');
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ BannerAd loaded: adUnitId=$adUnitId, responseInfo=${(ad as BannerAd).responseInfo}');
          analytics.log('ad_banner_loaded', {'ad_unit_id': adUnitId});
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ BannerAd failed: code=${error.code}, message=${error.message}, domain=${error.domain}');
          print('❌ BannerAd responseInfo: ${ad.responseInfo}');
          analytics.log('ad_banner_failed', {
            'ad_unit_id': adUnitId,
            'error_code': error.code,
            'error_message': error.message,
            'error_domain': error.domain,
          });
          // 에러 코드별 이벤트 (Firebase에서 바로 확인용)
          analytics.log('ad_fail_code_${error.code}');
          ad.dispose();
          if (mounted) setState(() => _failed = true); // 실패 시 예약 공간 회수
        },
        onAdClicked: (_) => AdHelper.markAdClicked(),
        onAdOpened: (_) => AdHelper.markAdClicked(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로드 실패 시에만 공간 회수. 로드 전(로딩 중)에도 높이를 예약해
    // 배너가 뒤늦게 뜰 때 리스트가 밀리는 점프(멀미)를 방지.
    if (_failed) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: AdSize.banner.height.toDouble(),
      child: (_isLoaded && _bannerAd != null)
          ? Center(child: AdWidget(ad: _bannerAd!))
          : null,
    );
  }
}
