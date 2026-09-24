import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/job.dart';
import '../../data/services/analytics_service.dart';
import '../../providers/account_provider.dart';
import '../account/login_signup_sheet.dart';

/// 지원방법 선택 바텀시트 (2026-09-14 UI A안 + 2026-09-20 다리 로그인 연결).
/// - 전화: 로그인 불필요, 광고 없이 즉시 발신.
/// - 그 외 방법: 다리 계정 로그인 상태면 바로 진행, 아니면 로그인/가입 팝업(스킵 가능) 노출 후 진행.
/// - 진행 = 기존 지원 이동 로직(광고+URL, [onProceedToSite]) 그대로 재사용 — 사이트 내 해당 방법 자동클릭까지는
///   아직 구현 범위 밖(각 사이트 JS 주입 자동화는 별도 작업, docs/apply_signup_scenario_2026-09-19.md 참고).
/// - 하단 "공고 원문 보기": 기존 동작 그대로, 로그인 게이트 없음.
void showApplyMethodSheet(
  BuildContext context, {
  required Job job,
  required AppStrings strings,
  required VoidCallback onProceedToSite,
}) {
  if (job.applyMethods.isEmpty) {
    onProceedToSite();
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ApplyMethodSheet(
      job: job,
      strings: strings,
      onProceedToSite: onProceedToSite,
    ),
  );
}

class _ApplyMethodSheet extends ConsumerWidget {
  final Job job;
  final AppStrings strings;
  final VoidCallback onProceedToSite;

  const _ApplyMethodSheet({
    required this.job,
    required this.strings,
    required this.onProceedToSite,
  });

  static const _icons = {
    'online': Icons.computer_outlined,
    'homepage': Icons.language,
    'email': Icons.email_outlined,
    'phone': Icons.phone_outlined,
    'sms': Icons.sms_outlined,
    'simple': Icons.flash_on,
    'chat': Icons.chat_bubble_outline,
    'visit': Icons.place_outlined,
    'other': Icons.more_horiz,
  };

  Future<void> _selectMethod(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    analytics.log('apply_method_selected', {'job_id': job.id, 'method': code});
    Navigator.of(context).pop();

    if (code == 'phone') {
      final phone = job.applyContact?['phone'] as String?;
      if (phone != null && phone.isNotEmpty) {
        launchUrl(Uri.parse('tel:$phone'));
      }
      return;
    }

    // 세션 복원이 안 끝났을 수 있어 서버 확인까지 대기.
    final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
    if (loggedIn) {
      onProceedToSite();
      return;
    }
    if (!context.mounted) return;
    showLoginSignupSheet(
      context,
      showSkipOption: true,
      onSkip: onProceedToSite,
      // 로그인 성공(기존 회원) 시 지원 흐름을 끊지 않고 바로 사이트로 진행.
      onLoggedIn: onProceedToSite,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = job.applyContact?['phone'] as String?;

    // _ApplyMethodsRow와 동일 규칙 — 라벨 없는(미지) 코드 제외, 라벨 중복 제거
    final seenLabels = <String>{};
    final methods = <String>[];
    for (final m in job.applyMethods) {
      final label = strings.applyMethodLabel(m);
      if (label != null && seenLabels.add(label)) methods.add(m);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              strings.infoApplyMethod,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            for (final code in methods)
              _MethodTile(
                icon: _icons[code] ?? Icons.more_horiz,
                label: strings.applyMethodLabel(code)!,
                subtitle: code == 'phone'
                    ? phone
                    : strings.applyMethodDesc(code),
                onTap: () => _selectMethod(context, ref, code),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).pop();
                onProceedToSite();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${strings.applyViewOriginal}${job.siteName != null ? ' · ${job.siteName}' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.carrotLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: AppColors.carrot),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}
