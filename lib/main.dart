import 'dart:io';
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

/// Firebase 초기화 성공 여부 (iOS에서 GoogleService-Info.plist 미배치 시 false)
bool firebaseReady = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Firebase는 iOS plist 미배치 등으로 실패할 수 있어 개별 초기화 (앱 실행은 계속)
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    if (kDebugMode) print('🔴 Firebase 초기화 실패 (GA/푸시 비활성): $e');
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  if (firebaseReady) analytics.init();

  // Facebook SDK 초기화
  // iOS: advertiser tracking은 ATT 동의 후에만 활성화 (스플래시에서 처리)
  final facebookAppEvents = FacebookAppEvents();
  facebookAppEvents.setAutoLogAppEventsEnabled(true);
  if (!Platform.isIOS) {
    facebookAppEvents.setAdvertiserTracking(enabled: true);
  }

  // MobileAds 초기화 (UMP 동의 없이 바로 실행 — 광고 '요청'은 iOS ATT 이후)
  final status = await MobileAds.instance.initialize();
  final adapterInfo = status.adapterStatuses.map((k, v) => MapEntry(k, '${v.state}'));
  if (kDebugMode) print('🔵 MobileAds initialized: $adapterInfo');
  analytics.log('ad_sdk_initialized', {'adapters': adapterInfo.toString()});
  // iOS: 광고 '요청'은 ATT 응답 이후에만 (Apple 5.1.2). 앱오픈 광고 로드는 스플래시에서 ATT 후 수행.
  if (!Platform.isIOS) appOpenAdService.loadAd();
  runApp(const ProviderScope(child: DariApp()));
  // 앱 렌더링 후 FCM 초기화 (UI 블로킹 방지)
  if (firebaseReady) pushService.init();
}
