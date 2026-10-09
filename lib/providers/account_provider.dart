import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/applicant_profile.dart';

/// 다리 계정 상태. 인증은 Supabase Auth, 프로필은 applicant_profiles 테이블.
/// isLoggedIn = 세션 + 프로필이 모두 있어야 true (세션만 있고 프로필이 없으면
/// 추가정보 입력이 안 끝난 상태라 로그인으로 안 침).
class AccountState {
  final ApplicantProfile? profile;

  const AccountState({this.profile});

  bool get isLoggedIn => profile != null;
}

/// saveSmsFields에서 "미전달"과 "null로 지우기"를 구분하는 sentinel.
const Object _unset = Object();

class AccountNotifier extends StateNotifier<AccountState> {
  AccountNotifier() : super(const AccountState()) {
    _restoreSession();
  }

  SupabaseClient get _db => Supabase.instance.client;

  /// 앱 시작(정확히는 프로바이더 최초 구독) 시 저장된 Supabase 세션이 있으면
  /// 서버 프로필을 읽어 로그인 상태 복원 — 앱을 껐다 켜도 로그인 유지.
  Future<void> _restoreSession() async {
    if (_db.auth.currentUser != null) await refreshFromServer();
  }

  /// 로그인 여부 판정(진입점용) — 복원이 아직 안 끝났을 수 있어 동기
  /// isLoggedIn만 믿으면 안 됨: 세션이 있으면 서버 확인까지 기다렸다가 판정
  /// (2026-09-24 "재시작 후 로그인 풀림" 버그 수정).
  Future<bool> ensureLoaded() async {
    if (state.isLoggedIn) return true;
    if (_db.auth.currentUser == null) return false;
    return refreshFromServer();
  }

  /// 서버에서 프로필을 읽어 상태 갱신. 프로필이 있으면 true(기존 회원).
  /// 로그인 직후 "기존 회원이면 바로 로그인 / 신규면 추가정보 입력" 분기에 사용.
  Future<bool> refreshFromServer() async {
    final user = _db.auth.currentUser;
    if (user == null) return false;
    try {
      final row = await _db
          .from('applicant_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) return false;
      if (mounted) state = AccountState(profile: ApplicantProfile.fromJson(row));
      return true;
    } catch (_) {
      // 네트워크 등 일시 오류 — 신규 취급하면 기존 회원이 추가정보 화면으로
      // 잘못 가지만, 완료 시 upsert라 데이터가 깨지진 않음.
      return false;
    }
  }

  /// 가입 완료/프로필 수정 — 서버 upsert가 성공해야 상태 반영(실패 시 throw,
  /// 호출부에서 안내). 세션이 없으면(이론상 없음) 로컬 상태만 갱신.
  Future<void> completeSignup(ApplicantProfile profile) async {
    final user = _db.auth.currentUser;
    if (user != null) {
      await _db.from('applicant_profiles').upsert({
        'user_id': user.id,
        ...profile.toJson(),
      });
    }
    state = AccountState(profile: profile);
  }

  /// 문자 지원(K-HIRE)에서 수집한 비자기간·주소를 해당 컬럼만 update.
  /// completeSignup의 upsert와 분리 — 가입/개인정보수정이 이 값을 덮지 않게 하고,
  /// 반대로 여기서도 나머지 프로필 필드를 건드리지 않는다.
  /// 인자를 넘긴 것만 반영(null 전달과 "미전달" 구분 위해 sentinel 사용).
  Future<void> saveSmsFields({
    Object? visaIssuedAt = _unset,
    Object? visaExpiresAt = _unset,
    bool? visaNoExpiry,
    Object? addrSido = _unset,
    Object? addrSigungu = _unset,
    Object? addrDong = _unset,
    Object? addrZipcd = _unset,
    Object? addrRoad = _unset,
    Object? addrDetail = _unset,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null || state.profile == null) return;

    final patch = <String, dynamic>{};
    if (visaIssuedAt != _unset) {
      patch['visa_issued_at'] =
          ApplicantProfile.ymdToDate(visaIssuedAt as String?);
    }
    if (visaExpiresAt != _unset) {
      patch['visa_expires_at'] =
          ApplicantProfile.ymdToDate(visaExpiresAt as String?);
    }
    if (visaNoExpiry != null) patch['visa_no_expiry'] = visaNoExpiry;
    if (addrSido != _unset) patch['addr_sido'] = addrSido as String?;
    if (addrSigungu != _unset) patch['addr_sigungu'] = addrSigungu as String?;
    if (addrDong != _unset) patch['addr_dong'] = addrDong as String?;
    if (addrZipcd != _unset) patch['addr_zipcd'] = addrZipcd as String?;
    if (addrRoad != _unset) patch['addr_road'] = addrRoad as String?;
    if (addrDetail != _unset) patch['addr_detail'] = addrDetail as String?;
    if (patch.isEmpty) return;

    await _db.from('applicant_profiles').update(patch).eq('user_id', user.id);
    // copyWith는 null로 "지우기"(만료일 없음)를 표현 못 하므로 서버 재조회로 반영.
    await refreshFromServer();
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

  /// 회원탈퇴: delete-account Edge Function이 auth 계정을 실제 삭제
  /// (applicant_profiles는 FK cascade로 함께 삭제). 실패 시 throw —
  /// 세션·프로필을 남겨둬야 사용자가 재시도할 수 있으므로 로컬 정리 안 함.
  Future<void> withdraw() async {
    if (_db.auth.currentUser != null) {
      try {
        await _db.functions.invoke('delete-account');
      } on FunctionException catch (e) {
        // 401 = 토큰의 계정이 서버에 없음 — 이전 시도에서 삭제는 성공했는데
        // 응답이 유실된 경우. 실패 처리하면 영원히 재시도 루프에 갇히므로
        // 성공으로 간주하고 세션 정리 진행(2026-09-26 검토 발견).
        if (e.status != 401) rethrow;
      }
    }
    await _signOutAuth();
    if (mounted) state = const AccountState();
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((
  ref,
) {
  return AccountNotifier();
});
