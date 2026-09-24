import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation.dart';
import 'data/services/app_open_ad_service.dart';
import 'features/account/additional_info_screen.dart';
import 'features/account/my_page_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/language_select_screen.dart';
import 'features/onboarding/visa_select_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/onboarding/location_select_screen.dart';
import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/filter/filter_screen.dart';
import 'features/job_detail/job_detail_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/dev/apply_webview_debug_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/my-page',
        builder: (context, state) => const MyPageScreen(),
      ),
      GoRoute(
        path: '/account/additional-info',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AdditionalInfoScreen(
            snsProvider: extra?['provider'] as String?,
            initialEmail: extra?['email'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding/language',
        builder: (context, state) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: '/onboarding/visa',
        builder: (context, state) => const VisaSelectScreen(),
      ),
      GoRoute(
        path: '/onboarding/location',
        builder: (context, state) => const LocationSelectScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/filter',
        builder: (context, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return FilterScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/job/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobDetailScreen(jobId: id);
        },
      ),
      // [DEV] 지원하기 WebView 분석 도구
      GoRoute(
        path: '/dev/apply-webview',
        builder: (context, state) => const ApplyWebViewDebugScreen(),
      ),
    ],
  );
});

class DariApp extends ConsumerWidget {
  const DariApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Dari',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // 앱오픈 광고 표시 중엔 앱 화면을 불투명 커버로 가림.
      // 광고 뒤/전환 순간에 홈 등 앱 화면이 비치는 "modified ad behavior" 방지(iOS·Android 공통).
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          ValueListenableBuilder<bool>(
            valueListenable: appOpenAdService.isAdShowing,
            builder: (context, showing, _) => showing
                ? const ColoredBox(
                    color: Colors.white,
                    child: SizedBox.expand(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale('vi'),
        Locale('th'),
        Locale('uz'),
        Locale('km'),
        Locale('ne'),
        Locale('id'),
        Locale('my'),
        Locale('mn'),
        Locale('ja'),
        Locale('si'),
        Locale('bn'),
        Locale('ru'),
        Locale('hi'),
        Locale('ko'),
      ],
    );
  }
}
