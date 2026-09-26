import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteItem {
  final String jobId;
  final DateTime addedAt;

  const FavoriteItem({required this.jobId, required this.addedAt});

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        jobId: json['jobId'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

final favoriteProvider =
    StateNotifierProvider<FavoriteNotifier, List<FavoriteItem>>((ref) {
  return FavoriteNotifier();
});

/// 특정 jobId가 즐겨찾기인지 확인하는 편의 프로바이더
final isFavoriteProvider = Provider.family<bool, String>((ref, jobId) {
  final favorites = ref.watch(favoriteProvider);
  return favorites.any((f) => f.jobId == jobId);
});

/// 즐겨찾기 — 비로그인은 로컬(SharedPreferences)만, 로그인 시 서버(favorites
/// 테이블)와 동기화(2026-09-26 서버화):
/// - 로그인/세션복원 순간: 로컬 하트를 서버에 병합 업로드 → 서버 전체를 내려받아
///   상태 교체 (기기 변경·재설치에도 유지, 비로그인 때 찜한 것도 계정에 흡수)
/// - 로그인 상태의 토글/삭제: 로컬 즉시 반영 + 서버 fire-and-forget
/// - 로그아웃/탈퇴: 로컬 비움 — 다른 계정과 섞임 방지(2026-09-26 검토 발견)
class FavoriteNotifier extends StateNotifier<List<FavoriteItem>> {
  static const _prefsKey = 'favorites';

  StreamSubscription<AuthState>? _authSub;

  FavoriteNotifier() : super([]) {
    _init();
  }

  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<void> _init() async {
    await _load();
    // 앱 시작 시 이미 로그인 상태면 즉시 동기화.
    if (_uid != null) _syncWithServer();
    _authSub = _db.auth.onAuthStateChange.listen((event) {
      switch (event.event) {
        case AuthChangeEvent.signedIn:
          _syncWithServer();
        case AuthChangeEvent.signedOut:
          _clearLocal();
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        state = list.map((e) => FavoriteItem.fromJson(e)).toList();
      } catch (_) {}
    }
  }

  /// 로그인 시 동기화: 로컬 → 서버 병합 업로드 후, 서버 전체를 진실로 채택.
  Future<void> _syncWithServer() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final local = state;
      if (local.isNotEmpty) {
        await _db.from('favorites').upsert(
          [
            for (final f in local)
              {
                'user_id': uid,
                'job_id': f.jobId,
                'created_at': f.addedAt.toUtc().toIso8601String(),
              },
          ],
          onConflict: 'user_id,job_id',
          ignoreDuplicates: true,
        );
      }
      final rows = await _db
          .from('favorites')
          .select('job_id, created_at')
          .eq('user_id', uid);
      if (!mounted) return;
      state = [
        for (final r in rows)
          FavoriteItem(
            jobId: r['job_id'] as String,
            addedAt: DateTime.parse(r['created_at'] as String).toLocal(),
          ),
      ];
      _save();
    } catch (_) {
      // 동기화 실패 시 로컬 상태 그대로 사용 — 다음 로그인/재시작 때 재시도.
    }
  }

  /// 로그아웃/탈퇴: 로컬 비움(서버 데이터는 계정에 남고, 탈퇴면 cascade 삭제).
  void _clearLocal() {
    if (mounted) state = [];
    _save();
  }

  Timer? _saveTimer;

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKey, jsonEncode(state.map((e) => e.toJson()).toList()));
    });
  }

  // 서버 반영 — 낙관적 UI: 로컬 먼저 바꾸고 서버는 뒤에서. 실패하면 하트를
  // 조용히 원상복구(롤백)해서 화면과 서버가 어긋나지 않게 함(2026-09-26 확정).
  void _serverAdd(FavoriteItem item) {
    final uid = _uid;
    if (uid == null) return;
    _db.from('favorites').upsert({
      'user_id': uid,
      'job_id': item.jobId,
      'created_at': item.addedAt.toUtc().toIso8601String(),
    }, onConflict: 'user_id,job_id', ignoreDuplicates: true).then(
      (_) {},
      onError: (_) {
        // 추가 실패 → 하트 해제 롤백 (그 사이 사용자가 이미 껐으면 그대로).
        if (!mounted) return;
        state = state.where((f) => f.jobId != item.jobId).toList();
        _save();
      },
    );
  }

  void _serverRemove(Iterable<String> jobIds) {
    final uid = _uid;
    if (uid == null || jobIds.isEmpty) return;
    _db
        .from('favorites')
        .delete()
        .eq('user_id', uid)
        .inFilter('job_id', jobIds.toList())
        .then((_) {}, onError: (_) {
      // 삭제 실패 → 하트 복구 롤백 (그 사이 다시 켠 항목은 중복 방지).
      if (!mounted) return;
      final existing = {for (final f in state) f.jobId};
      state = [
        ...state,
        for (final id in jobIds)
          if (!existing.contains(id))
            FavoriteItem(jobId: id, addedAt: DateTime.now()),
      ];
      _save();
    });
  }

  void toggle(String jobId) {
    HapticFeedback.lightImpact(); // 하트 토글 손맛(2026-09-26, 전 화면 공통)
    final exists = state.any((f) => f.jobId == jobId);
    if (exists) {
      state = state.where((f) => f.jobId != jobId).toList();
      _serverRemove([jobId]);
    } else {
      final item = FavoriteItem(jobId: jobId, addedAt: DateTime.now());
      state = [...state, item];
      _serverAdd(item);
    }
    _save();
  }

  void remove(String jobId) {
    state = state.where((f) => f.jobId != jobId).toList();
    _serverRemove([jobId]);
    _save();
  }

  void removeMultiple(Set<String> jobIds) {
    state = state.where((f) => !jobIds.contains(f.jobId)).toList();
    _serverRemove(jobIds);
    _save();
  }

  bool isFavorite(String jobId) => state.any((f) => f.jobId == jobId);
}
