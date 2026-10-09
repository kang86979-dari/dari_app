import 'package:supabase_flutter/supabase_flutter.dart';
import 'sms_message_builder.dart';

/// 문자 지원 메시지 칩 설정 저장소(문자 관리) — 서버(applicant_profiles.sms_compose).
/// "저장" 시 서버 저장 → 다음에 메시지 화면/문자 관리에서 불러와 재사용(기기 간 유지).
class SmsComposePrefs {

  final KoreanLevel? koreanLevel;
  final ExperienceLevel? experience;
  final KoreaStay? koreaStay;
  final bool isStudent;
  final StudentStatus? studentStatus;
  final Set<Weekday> workDays;
  final bool daysNegotiable;
  final bool daysMatchPosting;
  final Set<DayPart> workTimes;
  final bool timesNegotiable;
  final bool timesMatchPosting;
  final StartDate? startDate;
  final bool showSummaryOnApply; // 지원 시 요약본 보기 여부(기본 true)

  const SmsComposePrefs({
    this.koreanLevel,
    this.experience,
    this.koreaStay,
    this.isStudent = false,
    this.studentStatus,
    this.workDays = const {},
    this.daysNegotiable = false,
    this.daysMatchPosting = false,
    this.workTimes = const {},
    this.timesNegotiable = false,
    this.timesMatchPosting = false,
    this.startDate,
    this.showSummaryOnApply = true,
  });

  Map<String, dynamic> toJson() => {
        'korean': koreanLevel?.name,
        'exp': experience?.name,
        'stay': koreaStay?.name,
        'isStudent': isStudent,
        'student': studentStatus?.name,
        'days': workDays.map((e) => e.name).toList(),
        'daysNego': daysNegotiable,
        'daysMatch': daysMatchPosting,
        'times': workTimes.map((e) => e.name).toList(),
        'timesNego': timesNegotiable,
        'timesMatch': timesMatchPosting,
        'start': startDate?.name,
        'showSummary': showSummaryOnApply,
      };

  factory SmsComposePrefs.fromJson(Map<String, dynamic> j) {
    T? byName<T extends Enum>(List<T> values, Object? name) {
      if (name is! String) return null;
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    Set<E> setOf<E extends Enum>(List<E> values, Object? list) {
      if (list is! List) return {};
      return list
          .map((e) => byName(values, e))
          .whereType<E>()
          .toSet();
    }

    return SmsComposePrefs(
      koreanLevel: byName(KoreanLevel.values, j['korean']),
      experience: byName(ExperienceLevel.values, j['exp']),
      koreaStay: byName(KoreaStay.values, j['stay']),
      isStudent: j['isStudent'] as bool? ?? false,
      studentStatus: byName(StudentStatus.values, j['student']),
      workDays: setOf(Weekday.values, j['days']),
      daysNegotiable: j['daysNego'] as bool? ?? false,
      daysMatchPosting: j['daysMatch'] as bool? ?? false,
      workTimes: setOf(DayPart.values, j['times']),
      timesNegotiable: j['timesNego'] as bool? ?? false,
      timesMatchPosting: j['timesMatch'] as bool? ?? false,
      startDate: byName(StartDate.values, j['start']),
      showSummaryOnApply: j['showSummary'] as bool? ?? true,
    );
  }

  /// 서버 저장 — applicant_profiles.sms_compose(jsonb) 본인 행 update.
  /// 문자 지원은 로그인 필수라 세션 전제. 비로그인/실패 시 조용히 무시.
  static Future<void> save(SmsComposePrefs prefs) async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;
    if (user == null) return;
    try {
      await db
          .from('applicant_profiles')
          .update({'sms_compose': prefs.toJson()}).eq('user_id', user.id);
    } catch (_) {
      // 저장 실패가 흐름을 막지 않도록 무시(기존 기록 실패 정책과 동일).
    }
  }

  /// 서버 로드 — 없거나 실패 시 null(= "저장본 없음" 기존 동작 유지).
  static Future<SmsComposePrefs?> load() async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;
    if (user == null) return null;
    try {
      final row = await db
          .from('applicant_profiles')
          .select('sms_compose')
          .eq('user_id', user.id)
          .maybeSingle();
      final json = row?['sms_compose'];
      if (json is Map) {
        return SmsComposePrefs.fromJson(Map<String, dynamic>.from(json));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
