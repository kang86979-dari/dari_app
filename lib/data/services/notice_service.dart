import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 버전 (pubspec.yaml과 동기화)
const appVersion = '1.0.0';

class Notice {
  final String id;
  final Map<String, dynamic> titleTranslations;
  final Map<String, dynamic> contentTranslations;
  final String showType; // 'dismiss' or 'once'
  final String noticeType; // 'update', 'notice', 'event'
  final String? actionUrl; // event 타입용 URL
  final String? minVersion; // 이 버전 이상에게만 표시
  final String? maxVersion; // 이 버전 이하에게만 표시

  Notice({
    required this.id,
    required this.titleTranslations,
    required this.contentTranslations,
    required this.showType,
    required this.noticeType,
    this.actionUrl,
    this.minVersion,
    this.maxVersion,
  });

  bool get isOnce => showType == 'once';
  bool get isUpdate => noticeType == 'update';
  bool get isEvent => noticeType == 'event';
  bool get isNotice => noticeType == 'notice';

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'] as String,
        titleTranslations: json['title_translations'] as Map<String, dynamic>? ?? {},
        contentTranslations: json['content_translations'] as Map<String, dynamic>? ?? {},
        showType: json['show_type'] as String? ?? 'dismiss',
        noticeType: json['notice_type'] as String? ?? 'notice',
        actionUrl: json['action_url'] as String?,
        minVersion: json['min_version'] as String?,
        maxVersion: json['max_version'] as String?,
      );

  String getTitle(String langCode) =>
      titleTranslations[langCode] as String? ??
      titleTranslations['en'] as String? ??
      titleTranslations['ko'] as String? ??
      '';

  String getContent(String langCode) =>
      contentTranslations[langCode] as String? ??
      contentTranslations['en'] as String? ??
      contentTranslations['ko'] as String? ??
      '';

  /// 현재 앱 버전이 이 공지의 대상인지 확인
  bool isTargetVersion(String currentVersion) {
    if (minVersion != null && _compareVersion(currentVersion, minVersion!) < 0) return false;
    if (maxVersion != null && _compareVersion(currentVersion, maxVersion!) > 0) return false;
    return true;
  }

  /// 버전 비교: a < b → -1, a == b → 0, a > b → 1
  static int _compareVersion(String a, String b) {
    final aParts = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bParts = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final len = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < len; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av < bv) return -1;
      if (av > bv) return 1;
    }
    return 0;
  }
}

class NoticeService {
  static final NoticeService _instance = NoticeService._();
  factory NoticeService() => _instance;
  NoticeService._();

  static const _dismissedKey = 'dismissed_notice_ids';

  Future<Notice?> getActiveNotice() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final data = await Supabase.instance.client
          .from('notices')
          .select()
          .eq('is_active', true)
          .or('expires_at.is.null,expires_at.gte.$now')
          .order('created_at', ascending: false)
          .limit(5);

      if (data.isEmpty) return null;

      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getStringList(_dismissedKey) ?? [];

      // 버전 + dismiss 필터링 후 첫 번째 반환
      for (final row in data) {
        final notice = Notice.fromJson(row);
        if (dismissed.contains(notice.id)) continue;
        if (!notice.isTargetVersion(appVersion)) continue;
        return notice;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> dismissNotice(String noticeId) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    if (!dismissed.contains(noticeId)) {
      dismissed.add(noticeId);
      await prefs.setStringList(_dismissedKey, dismissed);
    }
  }
}

final noticeService = NoticeService();
