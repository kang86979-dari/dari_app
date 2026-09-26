import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/sheet_handle.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../providers/account_provider.dart';

/// 로그인·회원가입 팝업 (바텀시트).
/// - showSkipOption=true: 지원하기 흐름에서 트리거된 경우 — "로그인 없이 계속하기" 노출.
/// - showSkipOption=false: My Page 아이콘 / 설정 화면에서 트리거된 경우 — 스킵할 대상이 없어 미노출.
/// - X로 닫으면 팝업만 닫힘(스킵과 별개 동작, 아무것도 진행 안 함).
/// - onLoggedIn: 기존 회원 로그인 성공 시(시트 닫힌 뒤) 호출 — 마이프로필
///   진입이면 마이페이지로 자동 이동하는 용도(2026-09-24).
void showLoginSignupSheet(
  BuildContext context, {
  bool showSkipOption = false,
  VoidCallback? onSkip,
  VoidCallback? onLoggedIn,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _LoginSignupSheet(
      showSkipOption: showSkipOption,
      onSkip: onSkip,
      onLoggedIn: onLoggedIn,
    ),
  );
}

class _LoginSignupSheet extends ConsumerStatefulWidget {
  final bool showSkipOption;
  final VoidCallback? onSkip;
  final VoidCallback? onLoggedIn;

  const _LoginSignupSheet({
    required this.showSkipOption,
    this.onSkip,
    this.onLoggedIn,
  });

  @override
  ConsumerState<_LoginSignupSheet> createState() => _LoginSignupSheetState();
}

class _LoginSignupSheetState extends ConsumerState<_LoginSignupSheet> {
  // 페이스북 웹 OAuth는 브라우저를 갔다가 dari:// 딥링크로 복귀하고, 그때
  // supabase_flutter가 세션을 만들면서 signedIn 이벤트가 옴 — 시트는 그 이벤트를
  // 받아 다음 화면으로 이어감. 구글(네이티브)도 signedIn을 발생시키므로
  // 페이스북 탭으로 시작한 경우에만 반응하도록 플래그로 구분.
  StreamSubscription<AuthState>? _authSub;
  bool _awaitingOAuthReturn = false;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// 인증 성공 후 공통 처리: 서버에 프로필이 있으면 기존 회원 → 시트만 닫고
  /// 로그인 토스트, 없으면 신규 → 추가정보 입력으로 이동(2026-09-24 서버 저장).
  Future<void> _finishLogin(String provider, String email) async {
    final s = ref.read(stringsProvider);
    // 시트가 pop된 뒤(then 콜백)에도 계정 상태를 읽을 수 있게 컨테이너 캡처.
    final container = ProviderScope.containerOf(context, listen: false);
    final onLoggedIn = widget.onLoggedIn;
    final hasProfile = await ref
        .read(accountProvider.notifier)
        .refreshFromServer();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (hasProfile) {
      HapticFeedback.mediumImpact(); // 로그인 성공(2026-09-26)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.accountLoginDoneToast),
          behavior: SnackBarBehavior.floating,
        ),
      );
      onLoggedIn?.call();
    } else {
      // 신규 → 추가정보 입력. 가입을 끝내고 돌아오면 원래 하려던 동작(메모
      // 작성·지원 진행·마이페이지 이동)을 기존회원 로그인과 동일하게 이어줌
      // (2026-09-26 사용자 확정). 가입 미완(뒤로가기 이탈)이면 재개 안 함.
      context
          .push(
            '/account/additional-info',
            extra: {'provider': provider, 'email': email},
          )
          .then((_) {
            if (container.read(accountProvider).isLoggedIn) {
              onLoggedIn?.call();
            }
          });
    }
  }

  /// 구글: 실제 네이티브 인증 (google_sign_in → Supabase signInWithIdToken).
  Future<void> _onGoogleTap(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];
    // 콘솔 설정 전(클라이언트 ID 미발급)에는 실패 안내만.
    if (webClientId == null || webClientId.isEmpty) {
      _showLoginFailed(context, s.accountLoginFailed);
      return;
    }
    try {
      final googleSignIn = GoogleSignIn(
        // iOS는 iOS용 클라이언트 ID 필요, Android는 SHA-1 등록만으로 동작.
        clientId: Platform.isIOS ? iosClientId : null,
        // Supabase가 검증할 idToken의 audience = Web 클라이언트 ID.
        serverClientId: webClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) return; // 사용자가 계정 선택을 취소함 — 시트 유지.
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthException('Google sign-in returned no idToken');
      }
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      // 이름은 여권·신분증과 다를 수 있어 자동 세팅 안 함, 사용자 직접 입력.
      await _finishLogin('google', account.email);
    } catch (_) {
      if (context.mounted) _showLoginFailed(context, s.accountLoginFailed);
    }
  }

  /// 페이스북: Supabase 웹 OAuth. Supabase가 페이스북 네이티브 토큰
  /// (signInWithIdToken)을 지원하지 않아 브라우저 왕복 방식이 유일한 경로.
  /// 승인 후 dari:// 딥링크로 복귀하면 supabase_flutter가 세션을 만들고,
  /// 위의 onAuthStateChange 리스너(_onAuthEvent)가 다음 화면으로 이어감.
  Future<void> _onFacebookTap(BuildContext context) async {
    final s = ref.read(stringsProvider);
    try {
      _awaitingOAuthReturn = true;
      _authSub ??= Supabase.instance.client.auth.onAuthStateChange.listen(
        _onAuthEvent,
      );
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'dari://auth-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched) throw const AuthException('OAuth launch failed');
    } catch (_) {
      _awaitingOAuthReturn = false;
      if (context.mounted) _showLoginFailed(context, s.accountLoginFailed);
    }
  }

  void _onAuthEvent(AuthState data) {
    if (!_awaitingOAuthReturn || data.event != AuthChangeEvent.signedIn) return;
    _awaitingOAuthReturn = false;
    if (!mounted) return;
    _finishLogin('facebook', data.session?.user.email ?? '');
  }

  /// 애플: 네이티브 인증 (sign_in_with_apple → Supabase signInWithIdToken).
  /// nonce는 앱이 직접 생성 — 원문을 Supabase에, sha256 해시를 애플에 전달해
  /// 토큰 위조를 방지함. iOS 전용(안드로이드에서는 버튼 자체를 숨김).
  Future<void> _onAppleTap(BuildContext context) async {
    final s = ref.read(stringsProvider);
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple sign-in returned no identityToken');
      }
      final res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      // 애플은 최초 1회만 credential.email을 주고 이후엔 토큰(세션)에만 있음.
      // "이메일 가리기"로 받은 릴레이 주소(@privaterelay.appleid.com)는 애플에
      // 등록된 도메인의 발신만 전달돼 구인처 연락용으로 못 씀 — 칸을 비워서
      // 사용자가 실제 이메일을 직접 입력하게 함(2026-09-24 사용자 결정).
      final email = res.user?.email ?? credential.email ?? '';
      final usableEmail = email.endsWith('@privaterelay.appleid.com')
          ? ''
          : email;
      await _finishLogin('apple', usableEmail);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return; // 사용자 취소.
      if (context.mounted) _showLoginFailed(context, s.accountLoginFailed);
    } catch (_) {
      if (context.mounted) _showLoginFailed(context, s.accountLoginFailed);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  void _showLoginFailed(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            Text(
              s.accountLoginTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.accountLoginSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.gray500,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            _SocialButton(
              label: s.accountContinueGoogle,
              background: Colors.white,
              foreground: AppColors.gray900,
              border: AppColors.gray200,
              icon: SvgPicture.asset(
                'assets/brand/google_g.svg',
                width: 20,
                height: 20,
              ),
              onTap: () => _onGoogleTap(context, ref),
            ),
            // 애플 로그인은 iOS 전용 — 안드로이드에서는 버튼 숨김(웹 방식은
            // Service ID 별도 세팅이 필요해 미지원, App Store 요건은 iOS만 해당).
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              _SocialButton(
                label: s.accountContinueApple,
                background: AppColors.black,
                foreground: Colors.white,
                border: AppColors.black,
                icon: SvgPicture.asset(
                  'assets/brand/apple.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () => _onAppleTap(context),
              ),
            ],
            const SizedBox(height: 12),
            _SocialButton(
              label: s.accountContinueFacebook,
              background: const Color(0xFF1877F2),
              foreground: Colors.white,
              border: const Color(0xFF1877F2),
              icon: SvgPicture.asset(
                'assets/brand/facebook_f.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => _onFacebookTap(context),
            ),
            if (widget.showSkipOption) ...[
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSkip?.call();
                  },
                  child: Text(
                    s.accountSkipLogin,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.gray300,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color border;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
