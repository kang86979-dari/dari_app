import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/language_select_screen.dart';
import 'features/onboarding/visa_select_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/onboarding/location_select_screen.dart';
import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/filter/filter_screen.dart';
import 'features/job_detail/job_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/filter',
        builder: (context, state) => const FilterScreen(),
      ),
      GoRoute(
        path: '/job/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobDetailScreen(jobId: id);
        },
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
