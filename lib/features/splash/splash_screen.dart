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

  Future<void> _navigate() async {
    analytics.screenView('splash');
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    if (!mounted) return;

    if (isFirstLaunch) {
      context.go('/onboarding/language');
    } else {
      await appOpenAdService.showIfAvailable();
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
