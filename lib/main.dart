import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'app.dart';
import 'data/services/analytics_service.dart';
import 'data/services/app_open_ad_service.dart';
import 'data/services/push_service.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Future.wait([
    Firebase.initializeApp(),
    Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ),
  ]);

  analytics.init();

  // Facebook SDK 초기화
  final facebookAppEvents = FacebookAppEvents();
  facebookAppEvents.setAutoLogAppEventsEnabled(true);
  facebookAppEvents.setAdvertiserTracking(enabled: true);

  // MobileAds 초기화 (UMP 동의 없이 바로 실행)
  final status = await MobileAds.instance.initialize();
  final adapterInfo = status.adapterStatuses.map((k, v) => MapEntry(k, '${v.state}'));
  print('🔵 MobileAds initialized: $adapterInfo');
  analytics.log('ad_sdk_initialized', {'adapters': adapterInfo.toString()});
  appOpenAdService.loadAd();
  runApp(const ProviderScope(child: DariApp()));
  // 앱 렌더링 후 FCM 초기화 (UI 블로킹 방지)
  pushService.init();
}
