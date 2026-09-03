import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../onboarding/widgets/bridge_illustration.dart';
import '../../data/services/app_open_ad_service.dart';
import '../../data/services/analytics_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  /// iOS ATT(앱 추적 투명성) 동의 요청 — 광고 요청 전에 1회 (Apple 심사 필수)
  Future<void> _requestTrackingIfNeeded() async {
    if (!Platform.isIOS) return;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // 스플래시 렌더 후 요청해야 다이얼로그가 표시됨
        await Future.delayed(const Duration(milliseconds: 300));
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        analytics.log('att_result', {'status': result.name});
        if (result == TrackingStatus.authorized) {
          FacebookAppEvents().setAdvertiserTracking(enabled: true);
        }
      } else if (status == TrackingStatus.authorized) {
        FacebookAppEvents().setAdvertiserTracking(enabled: true);
      }
    } catch (_) {}
  }

  Future<void> _navigate() async {
    analytics.screenView('splash');
    await _requestTrackingIfNeeded();
    // iOS: ATT 응답 이후에 앱오픈 광고 로드 (요청이 ATT 전에 나가지 않도록)
    if (Platform.isIOS) appOpenAdService.loadAd();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    if (!mounted) return;

    if (isFirstLaunch) {
      context.go('/onboarding/language');
    } else {
      // 재실행 경로에서만: 노출 대상이고 광고 미준비면 최대 3초 로드 대기 후 노출
      // (스킵 대상이면 대기 없이 즉시 홈으로 — showIfAvailable 내부에서 판정)
      await appOpenAdService.showIfAvailable(maxWait: const Duration(seconds: 3));
      if (!mounted) return;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 다리 일러스트
            Semantics(
              label: 'Dari bridges foreigners to jobs in Korea',
              child: const BridgeIllustration(
                animated: true,
                size: Size(300, 160),
              ),
            ),
            const SizedBox(height: 32),
            Image.asset(
              'assets/wordmark.png',
              height: 48,
            ),
            const SizedBox(height: 4),
            Text(
              s.splashSubtitle,
              style: const TextStyle(
                color: AppColors.gray400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            // 로딩 바
            SizedBox(
              width: 48,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.carrot.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.carrot),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
