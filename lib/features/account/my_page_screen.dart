import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/applied_job_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/job_note_provider.dart';
import '../../providers/resume_provider.dart';
import '../resume/resume_edit_screen.dart';
import '../resume/resume_manage_screen.dart';
import 'additional_info_screen.dart';
import 'apply_history_screen.dart';
import '../apply/sms/sms_prepare_screen.dart';
import '../favorites/favorites_screen.dart';
import 'my_memos_screen.dart';
import '../home/widgets/mrec_ad_card.dart';
import '../../core/utils/mrec_ad_controller.dart';
import 'widgets/account_app_bar.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  // 하단 큰 광고(MREC) 컨트롤러 — 화면 수명에 맞춰 해제(2026-09-26).
  final _mrecController = MrecAdController();

  @override
  void dispose() {
    _mrecController.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            // 마이페이지 아바타는 주황 유지(사용자 확정) — 홈
                            // 상단 아이콘만 남색.
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
                          icon: Icons.favorite_border,
                          label: s.favorites,
                          count: ref.watch(favoriteProvider).length,
                          // 미확인 즐겨찾기(즐겨찾기 화면 열면 소멸) — 메뉴에도 점.
                          showNew: ref.watch(favoritesUnseenProvider),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          ),
                        ),
                        _MenuTile(
                          icon: Icons.fact_check_outlined,
                          label: s.myPageApplyHistory,
                          showNew: ref.watch(unseenAppliedCountProvider) > 0,
                          count: ref.watch(appliedJobsProvider).valueOrNull?.length,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ApplyHistoryScreen(),
                            ),
                          ),
                        ),
                        // 내 이력서 관리(사이트별) — Dari가 이력서 원본,
                        // 여기서 작성/수정 → 온라인 지원 시 K-HIRE에 주입(2026-10-05).
                        _MenuTile(
                          icon: Icons.description_outlined,
                          label: s.myPageResume,
                          // 0건이면 숫자 숨김 — '없으면 없는 것'(2026-10-09).
                          count: switch (
                              ref.watch(resumeCountProvider).valueOrNull) {
                            null || 0 => null,
                            final c => c,
                          },
                          // 미작성이면 관리 화면 없이 바로 작성 화면으로(2026-10-11).
                          onTap: () async {
                            final resume = await ref
                                .read(resumeProvider('khire').future);
                            if (!context.mounted) return;
                            if (resume == null) {
                              ResumeEditScreen.show(context, site: 'khire');
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ResumeManageScreen(),
                                ),
                              );
                            }
                          },
                        ),
                        _MenuTile(
                          icon: Icons.sms_outlined,
                          label: s.myPageSmsManage,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SmsPrepareScreen(),
                            ),
                          ),
                        ),
                        // 지원 이메일 관리 삭제(2026-10-05) — 이력서 제출과 중복.
                        _MenuTile(
                          icon: Icons.edit_note,
                          label: s.myPageMemos,
                          count: ref.watch(jobNotesProvider).valueOrNull?.length,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyMemosScreen(),
                            ),
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 하단 큰 광고(MREC) — 사용자 확정(2026-09-26).
                  MrecAdCard(controller: _mrecController, slot: -1),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // 로그아웃·회원탈퇴는 설정 화면 하단으로 이동(2026-09-26 사용자 지시).
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  /// 미확인 항목 존재 표시(빨간 N) — 지원 내역 메뉴 등.
  final bool showNew;

  /// 항목 개수 미리 표시(지원 내역·메모 등). null이면 숨김.
  final int? count;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
    this.showNew = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 기능별 아이콘 — 연한 브랜드 톤 배경의 둥근 사각(2026-09-26).
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.carrotLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: AppColors.carrot),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      if (showNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.carrot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.carrot,
                    ),
                  ),
                if (count != null) const SizedBox(width: 6),
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
            // 아이콘까지 포함해 이어지도록 좌우 여백(16)만 유지(2026-09-26).
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
