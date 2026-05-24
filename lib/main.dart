import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'data/services/analytics_service.dart';
import 'data/services/app_open_ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Future.wait([
    Firebase.initializeApp(),
    Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ),
    MobileAds.instance.initialize(),
  ]);

  analytics.init();
  appOpenAdService.loadAd();
  runApp(const ProviderScope(child: DariApp()));
}
