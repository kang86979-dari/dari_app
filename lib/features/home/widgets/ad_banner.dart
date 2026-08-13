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
  AdSize? _adSize;
  bool _isLoaded = false;
  bool _failed = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면 폭이 필요해 initState 대신 여기서 1회만 로드.
    if (_requested) return;
    _requested = true;
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adUnitId = AdHelper.bannerId;
    // 화면 폭에 맞춘 적응형 배너 — 양옆 검은 여백(iOS 레터박스) 없이 꽉 참.
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width,
    );
    if (size == null) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    _adSize = size;
    print('🔵 BannerAd loading... adUnitId=$adUnitId, size=${size.width}x${size.height}');
    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
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
    );
    _bannerAd = ad;
    ad.load();
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
    final reservedHeight = _adSize?.height.toDouble() ?? AdSize.banner.height.toDouble();
    return SizedBox(
      width: double.infinity,
      height: reservedHeight,
      // 적응형 배너는 화면 폭에 맞춰지므로 Center 불필요 — 그대로 꽉 채움.
      child: (_isLoaded && _bannerAd != null)
          ? AdWidget(ad: _bannerAd!)
          : null,
    );
  }
}
