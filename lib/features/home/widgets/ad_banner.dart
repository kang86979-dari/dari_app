import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/colors.dart';
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

  void _loadAd() {
    final adUnitId = AdHelper.bannerId;
    // 표준 배너(320x50) 양 플랫폼 공통. 가운데 정렬 + 여백은 앱 배경색으로 채워
    // iOS 양옆 검은 여백 없이 깔끔하게.
    const size = AdSize.banner;
    _adSize = size;
    if (kDebugMode) {
      print('🔵 BannerAd loading... adUnitId=$adUnitId, size=${size.width}x${size.height}');
    }
    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('✅ BannerAd loaded: adUnitId=$adUnitId, responseInfo=${(ad as BannerAd).responseInfo}');
          }
          analytics.log('ad_banner_loaded', {'ad_unit_id': adUnitId});
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('❌ BannerAd failed: code=${error.code}, message=${error.message}, domain=${error.domain}');
            print('❌ BannerAd responseInfo: ${ad.responseInfo}');
          }
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
    return Container(
      width: double.infinity,
      height: reservedHeight,
      color: AppColors.background, // 배너 양옆 여백을 앱 배경색으로 채움(검은 여백 방지)
      alignment: Alignment.center,
      child: (_isLoaded && _bannerAd != null)
          ? AdWidget(ad: _bannerAd!)
          : null,
    );
  }
}
