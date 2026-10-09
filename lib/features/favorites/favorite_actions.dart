import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_provider.dart';
import '../../data/services/analytics_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/favorite_provider.dart';
import '../account/login_signup_sheet.dart';

/// 즐겨찾기 토글(로그인 게이트 + 애널리틱스 + 토스트 포함).
///
/// **추가(하트 켜기)는 로그인 필수** — 비로그인 시 로그인/가입 시트를 띄우고
/// 로그인 성공 후 추가·토스트. **제거는 로그인 불필요**. 추가가 비동기(로그인)라
/// 토스트·애널리틱스를 실제 토글 성공 시점에만 내보낸다. 홈·검색·상세 공유(2026-10-05).
Future<void> toggleFavoriteWithAuth(
  BuildContext context,
  WidgetRef ref,
  String jobId, {
  required String source, // 'home' | 'search' | 'detail' (애널리틱스용)
}) async {
  final isFav = ref.read(favoriteProvider).any((f) => f.jobId == jobId);
  final notifier = ref.read(favoriteProvider.notifier);

  void toast(bool added) {
    if (!context.mounted) return;
    final s = ref.read(stringsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added ? s.favoriteAddedMsg : s.favoriteRemovedMsg),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // 제거 — 로그인 불필요.
  if (isFav) {
    analytics.favoriteRemoved(jobId);
    notifier.toggle(jobId);
    toast(false);
    return;
  }

  // 추가 — 로그인 필수.
  void doAdd() {
    analytics.favoriteAdded(jobId, source);
    notifier.toggle(jobId);
    // 미확인 점은 개수 기반(favoritesUnseenProvider) — 추가하면 개수가 늘어
    // 자동으로 점이 뜨고, 즐겨찾기 화면을 열면 사라진다. 별도 호출 불필요.
    toast(true);
  }

  final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
  if (loggedIn) {
    doAdd();
    return;
  }
  if (!context.mounted) return;
  showLoginSignupSheet(context, onLoggedIn: doAdd);
}
