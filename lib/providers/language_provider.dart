import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LanguageInfo {
  final String code;
  final String name;

  const LanguageInfo({
    required this.code,
    required this.name,
  });
}

/// 하드코딩 폴백 (API 실패 시 사용)
const _fallbackLanguages = [
  LanguageInfo(code: 'en', name: 'English'),
  LanguageInfo(code: 'ko', name: '한국어'),
];

/// 네이티브 언어 이름 맵 (DB name_en 대신 네이티브 표시)
/// 언어 코드 → 네이티브 언어 이름
String nativeLanguageName(String code) => nativeNames[code] ?? code.toUpperCase();

const nativeNames = {
  'en': 'English',
  'zh': '中文',
  'vi': 'Tiếng Việt',
  'th': 'ภาษาไทย',
  'uz': "O'zbekcha",
  'km': 'ភាសាខ្មែរ',
  'ne': 'नेपाली',
  'id': 'Bahasa Indonesia',
  'my': 'မြန်မာဘာသာ',
  'mn': 'Монгол',
  'ja': '日本語',
  'si': 'සිංහල',
  'bn': 'বাংলা',
  'ru': 'Русский',
  'hi': 'हिन्दी',
  'ko': '한국어',
};

/// 캐시된 코드 리스트를 LanguageInfo 리스트로 변환
/// 한국 거주 외국인 인구순 (출입국통계 기준)
const _populationOrder = [
  'zh',  // 중국
  'vi',  // 베트남
  'th',  // 태국
  'uz',  // 우즈베키스탄
  'km',  // 캄보디아
  'ne',  // 네팔
  'id',  // 인도네시아
  'my',  // 미얀마
  'mn',  // 몽골
  'ja',  // 일본
  'si',  // 스리랑카
  'bn',  // 방글라데시
  'ru',  // 러시아
  'hi',  // 인도
  'en',  // 영어
  'ko',  // 한국어
];

List<LanguageInfo> _codesToLanguageInfoList(List<String> codes) {
  final all = codes.map((code) {
    final name = nativeNames[code] ?? code;
    return LanguageInfo(code: code, name: name);
  }).toList();

  // 디바이스 시스템 언어 감지
  final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;

  // 인구순 정렬
  all.sort((a, b) {
    final ai = _populationOrder.indexOf(a.code);
    final bi = _populationOrder.indexOf(b.code);
    return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
  });

  // 디바이스 언어를 맨 앞으로
  final device = all.where((l) => l.code == deviceLang).firstOrNull;
  if (device != null) {
    all.remove(device);
    all.insert(0, device);
  }

  return all;
}

/// 언어 목록: 캐시 우선, DB는 앱 시작 시 동시 요청 방지를 위해 지연
final supportedLanguagesProvider =
    FutureProvider<List<LanguageInfo>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getStringList('known_supported_languages');

  // 캐시가 있으면 즉시 반환, 백그라운드에서 DB 갱신
  if (cached != null && cached.isNotEmpty) {
    // 백그라운드 갱신 (fire-and-forget)
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        final response = await Supabase.instance.client
            .from('languages')
            .select('code, name_ko, name_en')
            .eq('is_supported', true)
            .order('id');
        final codes = (response as List).map((r) => r['code'] as String).toList();
        await prefs.setStringList('known_supported_languages', codes);
      } catch (_) {}
    });
    return _codesToLanguageInfoList(cached);
  }

  // 캐시 없음 (최초 설치) → DB 조회
  try {
    final response = await Supabase.instance.client
        .from('languages')
        .select('code, name_ko, name_en')
        .eq('is_supported', true)
        .order('id');

    final codes = (response as List).map((r) => r['code'] as String).toList();
    await prefs.setStringList('known_supported_languages', codes);
    return _codesToLanguageInfoList(codes);
  } catch (_) {
    return _fallbackLanguages;
  }
});

/// 신규 언어 감지 프로바이더
/// OS 언어와 일치하는 새 언어가 추가된 경우에만 반환
final newLanguagesProvider = FutureProvider<List<LanguageInfo>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final previousCodes =
      prefs.getStringList('known_supported_languages') ?? [];

  // 이전에 저장된 게 없으면 (최초 설치) 신규 알림 불필요
  if (previousCodes.isEmpty) return [];

  final currentLanguages = await ref.watch(supportedLanguagesProvider.future);
  final currentCodes = currentLanguages.map((l) => l.code).toSet();
  final previousSet = previousCodes.toSet();

  final newCodes = currentCodes.difference(previousSet);
  if (newCodes.isEmpty) return [];

  // OS 설정 언어 확인
  final deviceLocale = ui.PlatformDispatcher.instance.locale.languageCode;

  // OS 언어가 새로 추가된 언어에 포함될 때만 알림
  if (!newCodes.contains(deviceLocale)) return [];

  return currentLanguages
      .where((l) => l.code == deviceLocale)
      .toList();
});

final languageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(_defaultLanguage()) {
    _loadSaved();
  }

  static String _defaultLanguage() {
    final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
    if (nativeNames.containsKey(deviceLang)) return deviceLang;
    return 'en';
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language');
    if (saved != null) state = saved;
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
  }
}
