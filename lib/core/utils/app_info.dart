import 'package:package_info_plus/package_info_plus.dart';

/// 앱 자신의 버전/빌드번호 (pubspec version에서 빌드 시 주입된 값).
/// - version: 푸시 구독 app_version 기록용 (예: "2.0.0")
/// - buildNumber: 서버 버전 게이트 p_app_build용 (예: 20)
class AppInfo {
  AppInfo._();

  static PackageInfo? _info;

  static Future<PackageInfo> _load() async =>
      _info ??= await PackageInfo.fromPlatform();

  static Future<String> version() async => (await _load()).version;

  static Future<int?> buildNumber() async =>
      int.tryParse((await _load()).buildNumber);
}
