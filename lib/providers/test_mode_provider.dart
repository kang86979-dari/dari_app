import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테스트 모드 (숨김 스위치). ON이면 RPC에 include_testing 파라미터를 붙여
/// testing 사이트(JobnShop 등)를 실서비스처럼 섞어서 표시. 기본 OFF, 로컬 저장.
class TestModeNotifier extends StateNotifier<bool> {
  static const _key = 'test_mode';
  TestModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  Future<void> toggle() => set(!state);
}

final testModeProvider =
    StateNotifierProvider<TestModeNotifier, bool>((ref) => TestModeNotifier());
