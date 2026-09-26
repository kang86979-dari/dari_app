import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 인증 이벤트 스트림 — 사용자별 데이터 프로바이더들이 watch해서
/// 로그인/로그아웃 즉시 재로드(로그아웃 후 이전 사용자 데이터 잔존 방지).
final authStateProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

/// 내 공고 메모 전체 (job_id → note). 로그인 사용자만, 비로그인은 빈 맵.
/// 카드(홈·검색·즐겨찾기) 노랑 미리보기와 상세 메모 섹션이 공유(2026-09-26).
final jobNotesProvider = FutureProvider<Map<String, String>>((ref) async {
  ref.watch(authStateProvider); // 로그인/아웃 시 자동 갱신
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const {};
  final rows = await Supabase.instance.client
      .from('job_notes')
      .select('job_id, note')
      .eq('user_id', user.id); // RLS와 이중 방어
  return {
    for (final r in rows) r['job_id'] as String: r['note'] as String,
  };
});

/// 메모 저장/삭제 + 저장 시 즐겨찾기 자동 추가(사용자 확정 규칙).
/// 성공 후 jobNotesProvider 갱신. 실패 시 throw — 호출부에서 안내.
class JobNoteActions {
  final Ref _ref;
  JobNoteActions(this._ref);

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> save(String jobId, String note) async {
    final user = _db.auth.currentUser;
    if (user == null) throw const AuthException('Not logged in');
    if (note.isEmpty) {
      await _db
          .from('job_notes')
          .delete()
          .eq('user_id', user.id)
          .eq('job_id', jobId);
    } else {
      await _db.from('job_notes').upsert({
        'user_id': user.id,
        'job_id': jobId,
        'note': note,
      });
      // 즐겨찾기 자동 추가는 하지 않음 — 헷갈린다는 피드백으로 분리(2026-09-26).
      // 메모 단 공고는 마이페이지 "내 메모"에서 모아봄.
    }
    _ref.invalidate(jobNotesProvider);
  }

  /// 여러 공고의 메모 일괄 삭제 — 내 메모 편집 모드(2026-09-26).
  Future<void> deleteMany(List<String> jobIds) async {
    final user = _db.auth.currentUser;
    if (user == null || jobIds.isEmpty) return;
    await _db
        .from('job_notes')
        .delete()
        .eq('user_id', user.id)
        .inFilter('job_id', jobIds);
    _ref.invalidate(jobNotesProvider);
  }
}

final jobNoteActionsProvider = Provider<JobNoteActions>(
  (ref) => JobNoteActions(ref),
);
