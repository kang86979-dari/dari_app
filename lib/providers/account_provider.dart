import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void logout() {
    state = const AccountState();
  }

  void withdraw() {
    state = const AccountState();
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier();
});
