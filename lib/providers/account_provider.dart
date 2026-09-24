import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/applicant_profile.dart';

/// [DEV/TEMP] 다리 계정 상태 — 현재는 메모리에만 존재(앱 재시작 시 초기화).
/// SNS 로그인·Supabase Auth·서버 저장은 다음 단계에서 연동 예정.
class AccountState {
  final ApplicantProfile? profile;

  const AccountState({this.profile});

  bool get isLoggedIn => profile != null;
}

class AccountNotifier extends StateNotifier<AccountState> {
  AccountNotifier() : super(const AccountState());

  void completeSignup(ApplicantProfile profile) {
    state = AccountState(profile: profile);
  }

  /// 인증 세션 정리(구글+Supabase) — 실패해도 앱 상태는 로그아웃 처리.
  /// 콘솔 미설정·오프라인 등으로 signOut이 던져도 사용자를 붙잡지 않기 위함.
  Future<void> _signOutAuth() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }

  void logout() {
    _signOutAuth();
    state = const AccountState();
  }

  void withdraw() {
    // TODO: 서버 프로필 저장 단계에서 실제 계정 삭제(Edge Function) 연동.
    _signOutAuth();
    state = const AccountState();
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier();
});
