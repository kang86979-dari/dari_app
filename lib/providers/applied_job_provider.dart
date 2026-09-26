import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'job_note_provider.dart';

/// applied_jobs 한 행 (방법별 1행, 재지원도 별도 행).
/// 스냅샷(title 등)은 지원 당시 언어 기준 — 공고 실삭제 후에도 목록 유지용.
class AppliedJob {
  final int id;
  final String? jobId; // 공고 실삭제 시 null
  final String method;
  final DateTime appliedAt;
  final DateTime? seenAt; // null = 미확인(N)
  final String title;
  final String company;
  final String siteName;
  final String location;
  final DateTime? jobExpiresAt; // join(jobs.expires_at), 행 삭제됐으면 null

  const AppliedJob({
    required this.id,
    required this.jobId,
    required this.method,
    required this.appliedAt,
    required this.seenAt,
    required this.title,
    required this.company,
    required this.siteName,
    required this.location,
    required this.jobExpiresAt,
  });

  bool get isNew => seenAt == null;

  /// 마감 여부 — 공고가 실삭제됐거나(=jobs 행 없음) 마감일이 지났으면 true.
  /// 날짜 단위 비교 — 홈 RPC(>= CURRENT_DATE)·JobCard·상세와 기준 통일
  /// (시각 비교 시 마감일 당일 공고가 이 화면만 마감 처리되는 버그, 2026-09-26).
  bool get expired {
    if (jobId == null) return true;
    final e = jobExpiresAt;
    if (e == null) return false; // 상시
    final now = DateTime.now();
    return e.isBefore(DateTime(now.year, now.month, now.day));
  }

  factory AppliedJob.fromJson(Map<String, dynamic> json) {
    final jobs = json['jobs'] as Map<String, dynamic>?;
    return AppliedJob(
      id: json['id'] as int,
      jobId: json['job_id'] as String?,
      method: json['method'] as String? ?? 'other',
      appliedAt: DateTime.parse(json['applied_at'] as String).toLocal(),
      seenAt: json['seen_at'] == null
          ? null
          : DateTime.parse(json['seen_at'] as String).toLocal(),
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      siteName: json['site_name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      jobExpiresAt: jobs?['expires_at'] == null
          ? null
          : DateTime.tryParse(jobs!['expires_at'] as String),
    );
  }
}

/// 내 지원 기록 전체 (최신순). 비로그인은 빈 목록.
/// authStateProvider watch — 로그인/로그아웃 시 자동 재로드.
final appliedJobsProvider = FutureProvider<List<AppliedJob>>((ref) async {
  ref.watch(authStateProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const [];
  final rows = await Supabase.instance.client
      .from('applied_jobs')
      .select('*, jobs(expires_at)')
      .eq('user_id', user.id) // RLS와 이중 방어
      .order('applied_at', ascending: false);
  return (rows as List)
      .map((r) => AppliedJob.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// 미확인(N) 건수 — 홈 마이페이지 아이콘·마이페이지 메뉴 뱃지용.
final unseenAppliedCountProvider = Provider<int>((ref) {
  final list = ref.watch(appliedJobsProvider).valueOrNull;
  if (list == null) return 0;
  return list.where((e) => e.isNew).length;
});

/// 지원한 공고 job_id 집합 — 카드 "✓ 지원함" 칩용.
final appliedJobIdsProvider = Provider<Set<String>>((ref) {
  final list = ref.watch(appliedJobsProvider).valueOrNull;
  if (list == null) return const {};
  return {for (final e in list) e.jobId ?? ''}..remove('');
});

class AppliedJobActions {
  final Ref _ref;
  AppliedJobActions(this._ref);

  SupabaseClient get _db => Supabase.instance.client;

  /// 지원 기록 저장 — 로그인 사용자만(비로그인은 조용히 무시, 정책상 미기록).
  /// 스냅샷은 지원 당시 표시 언어 기준.
  Future<void> record({
    required String jobId,
    required String method,
    required String title,
    required String company,
    required String siteName,
    required String location,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      await _db.from('applied_jobs').insert({
        'user_id': user.id,
        'job_id': jobId,
        'method': method,
        'title': title,
        'company': company,
        'site_name': siteName,
        'location': location,
      });
      _ref.invalidate(appliedJobsProvider);
    } catch (_) {
      // 기록 실패가 지원 흐름(전화 발신 등)을 막으면 안 됨 — 무시.
    }
  }

  /// 지원내역 화면 이탈 시 전부 읽음 처리 (N 해소, 사용자 확정 규칙).
  Future<void> markAllSeen() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      await _db
          .from('applied_jobs')
          .update({'seen_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', user.id) // RLS와 이중 방어
          .filter('seen_at', 'is', null);
      _ref.invalidate(appliedJobsProvider);
    } catch (_) {}
  }

  /// 특정 행들 읽음 처리 — 지원내역에서 카드 탭(상세 진입) 시 해당 공고만 해소.
  Future<void> markSeenRows(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      await _db
          .from('applied_jobs')
          .update({'seen_at': DateTime.now().toUtc().toIso8601String()})
          .inFilter('id', ids);
      _ref.invalidate(appliedJobsProvider);
    } catch (_) {}
  }

  /// 마감 공고 내역 삭제 (해당 공고의 모든 방법 행).
  Future<void> deleteRows(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      await _db.from('applied_jobs').delete().inFilter('id', ids);
      _ref.invalidate(appliedJobsProvider);
    } catch (_) {}
  }
}

final appliedJobActionsProvider = Provider<AppliedJobActions>(
  (ref) => AppliedJobActions(ref),
);
