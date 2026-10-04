import 'package:shared_preferences/shared_preferences.dart';

/// 사이트별 로그인 타입 기억 — 지원 웹뷰에서 OAuth 도메인 경유를 감지해 저장,
/// 다음 로그인 화면에서 "지난번엔 ○○로 로그인" 안내에 사용(2026-10-04).
class SiteLoginPrefs {
  static String _key(String site) => 'site_login_type_$site';

  static Future<void> save(String site, String type) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key(site), type);
  }

  static Future<String?> load(String site) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_key(site));
  }
}
