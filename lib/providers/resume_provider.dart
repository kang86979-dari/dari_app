import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/resume.dart';
import 'job_note_provider.dart' show authStateProvider;

/// 내 이력서 (사이트별). 로그인 사용자만, 없으면 null.
/// Dari가 원본 — 마이페이지 "내 이력서 관리"와 온라인 지원이 공유(2026-10-05).
final resumeProvider =
    FutureProvider.family<Resume?, String>((ref, site) async {
  ref.watch(authStateProvider); // 로그인/아웃 시 자동 갱신
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  final rows = await Supabase.instance.client
      .from('resumes')
      .select()
      .eq('user_id', user.id)
      .eq('site', site)
      .limit(1);
  if (rows.isEmpty) return null;
  return Resume.fromRow(rows.first);
});

/// 이력서 보유 사이트 개수 (마이페이지 "내 이력서 관리" 카운트).
final resumeCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authStateProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 0;
  final rows = await Supabase.instance.client
      .from('resumes')
      .select('id')
      .eq('user_id', user.id);
  return rows.length;
});

/// 이력서 저장/수정/삭제. 성공 후 관련 프로바이더 갱신.
class ResumeActions {
  final Ref _ref;
  ResumeActions(this._ref);

  SupabaseClient get _db => Supabase.instance.client;

  /// 신규 생성 또는 수정(upsert, user_id+site unique).
  /// 반환: 저장된 Resume(서버 id 포함).
  Future<Resume> save(Resume resume) async {
    final user = _db.auth.currentUser;
    if (user == null) throw const AuthException('Not logged in');
    final row = await _db
        .from('resumes')
        .upsert({
          'user_id': user.id,
          'site': resume.site,
          'data': resume.toData(),
        }, onConflict: 'user_id,site')
        .select()
        .single();
    _ref.invalidate(resumeProvider(resume.site));
    _ref.invalidate(resumeCountProvider);
    return Resume.fromRow(row);
  }

  /// khireResumeId만 갱신(최초 주입 후 K-HIRE 이력서 식별자 확보).
  Future<void> setKhireResumeId(String site, String khireResumeId) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    final current = await _ref.read(resumeProvider(site).future);
    if (current == null) return;
    await save(current.copyWith(khireResumeId: khireResumeId));
  }

  Future<void> delete(String site) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    await _db
        .from('resumes')
        .delete()
        .eq('user_id', user.id)
        .eq('site', site);
    _ref.invalidate(resumeProvider(site));
    _ref.invalidate(resumeCountProvider);
  }
}

final resumeActionsProvider =
    Provider<ResumeActions>((ref) => ResumeActions(ref));
