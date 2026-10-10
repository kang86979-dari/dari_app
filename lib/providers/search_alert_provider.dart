import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/filter_state.dart';
import '../data/services/push_service.dart';

/// 검색어 알림 조건(기기당 1개)을 홈·검색·설정이 공유하는 반응형 상태(2026-10-10).
/// pushService(로컬+서버)가 원본이지만, 화면 간 즉시 동기화를 위해 여기로
/// 한 번 더 들고 있는다. 등록/해제 시 이 노티파이어로만 바꾸면 전 화면 갱신.
class SearchAlertNotifier extends StateNotifier<Map<String, dynamic>?> {
  SearchAlertNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await pushService.getSearchCondition();
  }

  /// 외부 변경(앱 시작 등) 반영용 — 로컬에서 다시 읽기.
  Future<void> refresh() async {
    state = await pushService.getSearchCondition();
  }

  String? get keyword => state?['keyword'] as String?;

  bool matchesKeyword(String q) =>
      (state?['keyword'] as String?) == q && q.isNotEmpty;

  Future<void> register({
    required String keyword,
    required String label,
    required FilterState filter,
    required String langCode,
  }) async {
    // 서버 응답을 기다리지 않고 상태 먼저 반영(2026-10-10) — 로컬 저장
    // 형식(getSearchCondition 반환)과 동일한 모양으로 구성.
    state = {
      'keyword': keyword,
      'label': label,
      'filter': PushService.filterToJson(filter),
      'enabled': true,
    };
    await pushService.saveSearchCondition(
      keyword: keyword,
      label: label,
      filter: filter,
      langCode: langCode,
    );
    state = await pushService.getSearchCondition();
  }

  Future<void> clear() async {
    // 화면 반응이 서버 응답을 기다리지 않도록 상태 먼저 비움(2026-10-10).
    // clearSearchCondition은 로컬 삭제 후 서버 동기화(실패 무시)라 역순 안전.
    state = null;
    await pushService.clearSearchCondition();
  }
}

final searchAlertProvider =
    StateNotifierProvider<SearchAlertNotifier, Map<String, dynamic>?>(
        (ref) => SearchAlertNotifier());
