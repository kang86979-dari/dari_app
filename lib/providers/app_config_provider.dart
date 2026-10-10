import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 전역 설정(app_config, 크롤러 관리·앱 읽기 전용). 2026-10-09.
/// 현재는 푸시 발송 시각 — 설정 화면에 "매일 오전 9시·오후 3시" 식으로
/// 동적 표시(시간 변경 시 앱 배포 없이 반영).
class PushTimes {
  final List<String> newTimes; // 신규 공고 알림 ['09:00','15:00']
  final String? recommendTime; // 추천 공고 알림 '19:00'
  const PushTimes({this.newTimes = const [], this.recommendTime});
}

final pushTimesProvider = FutureProvider<PushTimes>((ref) async {
  try {
    final rows = await Supabase.instance.client
        .from('app_config')
        .select('key, value')
        .inFilter('key', ['push_new_times', 'push_recommend_time']);
    // app_config.value는 TEXT(JSON 문자열) — 디코드해서 사용.
    dynamic decode(dynamic v) {
      if (v is String) {
        try {
          return jsonDecode(v);
        } catch (_) {
          return v;
        }
      }
      return v;
    }

    final map = {for (final r in rows as List) r['key']: decode(r['value'])};
    final rawNew = map['push_new_times'];
    final newTimes = rawNew is List
        ? rawNew.map((e) => e.toString()).toList()
        : <String>[];
    final rec = map['push_recommend_time'];
    return PushTimes(
      newTimes: newTimes,
      recommendTime: rec is String ? rec : null,
    );
  } catch (_) {
    // 실패 시 빈 값 — 설정 화면은 시간 문구를 생략(안내는 그대로 노출).
    return const PushTimes();
  }
});
