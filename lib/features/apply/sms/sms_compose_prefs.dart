import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_message_builder.dart';

/// 문자 지원 메시지 칩 설정 저장소(문자 관리).
/// "지원 계속하기" 시 저장 → 다음에 메시지 화면/문자 관리에서 그대로 불러와 재사용.
class SmsComposePrefs {
  static const _key = 'sms_compose_prefs_v1';

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

  static Future<void> save(SmsComposePrefs prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(prefs.toJson()));
  }

  static Future<SmsComposePrefs?> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return null;
    try {
      return SmsComposePrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
