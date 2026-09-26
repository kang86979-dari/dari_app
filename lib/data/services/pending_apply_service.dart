import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 전화 지원 "확인 대기" 저장소 (2026-09-26).
/// 전화 발신 시점에는 기록하지 않고 여기 저장만 해뒀다가, 사용자가 앱에
/// 돌아오는 시점(직후 복귀든 며칠 뒤 재실행이든)에 "전화로 지원하셨나요?"
/// 팝업으로 확인받아 '네'일 때만 applied_jobs에 기록 — 다이얼러만 열고
/// 통화 안 한 경우의 오기록과, 앱 미복귀로 인한 기록 누락을 동시에 해결.
class PendingPhoneApply {
  final String jobId;
  final String title;
  final String company;
  final String siteName;
  final String location;
  final DateTime dialedAt;

  const PendingPhoneApply({
    required this.jobId,
    required this.title,
    required this.company,
    required this.siteName,
    required this.location,
    required this.dialedAt,
  });

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'title': title,
        'company': company,
        'siteName': siteName,
        'location': location,
        'dialedAt': dialedAt.toIso8601String(),
      };

  factory PendingPhoneApply.fromJson(Map<String, dynamic> json) =>
      PendingPhoneApply(
        jobId: json['jobId'] as String,
        title: json['title'] as String? ?? '',
        company: json['company'] as String? ?? '',
        siteName: json['siteName'] as String? ?? '',
        location: json['location'] as String? ?? '',
        dialedAt: DateTime.parse(json['dialedAt'] as String),
      );
}

class PendingApplyService {
  PendingApplyService._();

  static const _key = 'pending_phone_apply';

  /// 대기 건은 1건만 유지 — 새 발신이 이전 미확인 건을 덮어씀.
  static Future<void> save(PendingPhoneApply pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(pending.toJson()));
  }

  /// 유효한 대기 건 반환 (7일 지난 건 자동 폐기).
  static Future<PendingPhoneApply?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final pending =
          PendingPhoneApply.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().difference(pending.dialedAt).inDays >= 7) {
        await clear();
        return null;
      }
      return pending;
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
