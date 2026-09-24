import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';

/// 로그인·회원가입 팝업 (바텀시트).
/// - showSkipOption=true: 지원하기 흐름에서 트리거된 경우 — "로그인 없이 계속하기" 노출.
/// - showSkipOption=false: My Page 아이콘 / 설정 화면에서 트리거된 경우 — 스킵할 대상이 없어 미노출.
/// - X로 닫으면 팝업만 닫힘(스킵과 별개 동작, 아무것도 진행 안 함).
void showLoginSignupSheet(
  BuildContext context, {
  bool showSkipOption = false,
  VoidCallback? onSkip,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) =>
        _LoginSignupSheet(showSkipOption: showSkipOption, onSkip: onSkip),
  );
}

class _LoginSignupSheet extends ConsumerWidget {
  final bool showSkipOption;
  final VoidCallback? onSkip;

  const _LoginSignupSheet({required this.showSkipOption, this.onSkip});

  void _onSocialTap(BuildContext context, String provider) {
    // [TEMP] SNS 연동 전 — 실제 인증 없이 바로 추가정보 입력으로 이동.
    // 이메일은 실제 OAuth 연동 전까지 임시 stub 값(실제 값으로 자동 교체 예정).
    // 이름은 여권·신분증과 다를 수 있어 자동 세팅 안 함, 사용자 직접 입력.
    // 추후: 소셜 인증 → 프로필 완료 여부 확인 → 완료면 그냥 닫기, 미완료면 아래와 동일하게 이동.
    Navigator.of(context).pop();
    final stubEmail = switch (provider) {
      'google' => 'alex.kim@gmail.com',
      'apple' => 'alex.kim@icloud.com',
      _ => 'alex.kim@facebook.com',
    };
    context.push(
      '/account/additional-info',
      extra: {'provider': provider, 'email': stubEmail},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 26,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.gray300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              onTap: () => _onSocialTap(context, 'google'),
            ),
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
              onTap: () => _onSocialTap(context, 'apple'),
            ),
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
              onTap: () => _onSocialTap(context, 'facebook'),
            ),
            if (showSkipOption) ...[
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSkip?.call();
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
