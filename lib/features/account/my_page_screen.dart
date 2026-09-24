import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/applicant_profile.dart';
import '../../providers/account_provider.dart';
import 'additional_info_screen.dart';
import 'widgets/account_app_bar.dart';

String _providerLabel(String provider) {
  if (provider.isEmpty) return provider;
  return provider[0].toUpperCase() + provider.substring(1);
}

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  void _comingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
    ApplicantProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _providerLabel(profile.snsProvider),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              profile.email,
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ],
        ),
        content: Text(
          s.myPageLogoutConfirmDesc,
          style: const TextStyle(fontSize: 13.5, color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.myPageLogout,
              style: const TextStyle(
                color: AppColors.carrot,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(accountProvider.notifier).logout();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmWithdraw(
    BuildContext context,
    WidgetRef ref,
    AppStrings s,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.myPageWithdrawConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          s.myPageWithdrawConfirmDesc,
          style: const TextStyle(fontSize: 13.5, color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.myPageWithdraw,
              style: const TextStyle(
                color: AppColors.urgent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(accountProvider.notifier).withdraw();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final profile = ref.watch(accountProvider).profile;

    // 로그인 상태에서만 접근 가능한 화면. 프로필 없으면(비정상 진입) 안전하게 뒤로.
    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AccountAppBar(title: s.myPageTitle),
            Expanded(
              child: ListView(
                children: [
                  // 프로필 카드 위 여백 — 카드 아래(16)와 동일하게 맞춤(2026-09-24).
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdditionalInfoScreen(initialProfile: profile),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.carrotLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.carrot,
                            child: Text(
                              profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile.name,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        profile.visaLabel,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.carrot,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${profile.nationalityLabel} · ${profile.phone}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.gray400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray100),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          label: s.myPageApplyHistory,
                          onTap: () => _comingSoon(context, s.myPageComingSoon),
                        ),
                        _MenuTile(
                          label: s.myPageResume,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdditionalInfoScreen(initialProfile: profile),
                            ),
                          ),
                        ),
                        _MenuTile(
                          label: s.myPageSmsManage,
                          onTap: () => _comingSoon(context, s.myPageComingSoon),
                        ),
                        _MenuTile(
                          label: s.myPageEmailManage,
                          onTap: () => _comingSoon(context, s.myPageComingSoon),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // 로그아웃·회원탈퇴 — 스크롤 영역 밖, 화면 가장 하단 왼쪽 고정(2026-09-24).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _confirmLogout(context, ref, s, profile),
                    child: Text(
                      s.myPageLogout,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 11,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: AppColors.gray200,
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _confirmWithdraw(context, ref, s),
                    child: Text(
                      s.myPageWithdraw,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.gray400,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuTile({
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.gray300,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: AppColors.gray100,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
