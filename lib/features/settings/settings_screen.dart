import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/apply_confirm_dialog.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/applicant_profile.dart';
import '../../providers/language_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/push_service.dart';
import '../../providers/job_provider.dart';
import '../../providers/test_mode_provider.dart';
import '../../providers/account_provider.dart';
import '../account/login_signup_sheet.dart';
import '../../core/widgets/app_dialog.dart';
import '../filter/filter_chips_row.dart';
import '../../providers/search_alert_provider.dart';
import 'widgets/language_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _pushEnabled = true;
  // 검색어 알림 조건은 공유 프로바이더(searchAlertProvider)에서 watch.
  bool _loaded = false;

  // 테스트 모드 숨김 스위치: 설정 제목 7탭으로 잠금 해제
  int _versionTapCount = 0;
  bool _testUnlocked = false;

  void _onVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 7 && !_testUnlocked) {
      setState(() => _testUnlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('테스트 모드 잠금 해제됨'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPushSetting();
    _loadAlertConditions();
  }

  Future<void> _loadAlertConditions() async {
    ref.read(searchAlertProvider.notifier).refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPushSetting();
    }
  }

  Future<void> _loadPushSetting() async {
    // Firebase 미초기화(iOS plist 미배치 등) 시 푸시 설정 비활성 표시
    NotificationSettings? settings;
    try {
      settings = await FirebaseMessaging.instance.getNotificationSettings();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pushEnabled = false;
        _loaded = true;
      });
      return;
    }
    final osAllowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    final appEnabled = await pushService.isEnabled();
    if (!mounted) return;
    setState(() {
      _pushEnabled = osAllowed && appEnabled;
      _loaded = true;
    });
    // OS에서 거부했으면 앱 설정도 동기화
    if (!osAllowed && appEnabled) {
      await pushService.setEnabled(false);
    }
  }

  Future<void> _togglePush(bool value) async {
    // 토글 횟수 제한
    if (!await pushService.canToggle()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(languageProvider) == 'ko'
            ? '오늘 변경 횟수를 초과했습니다. 내일 다시 시도해주세요.'
            : 'Daily limit reached. Please try again tomorrow.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (value) {
      // OS 권한 확인 (Firebase 미초기화 시 무시)
      NotificationSettings settings;
      try {
        settings = await FirebaseMessaging.instance.requestPermission();
      } catch (_) {
        return;
      }
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        // 권한 거부됨 → 다이얼로그로 OS 설정 안내(공용 showAppDialog)
        if (!mounted) return;
        final s = ref.read(stringsProvider);
        final go = await showAppDialog(
          context,
          message: s.enableNotificationsInSettings,
          cancelLabel: ref.read(languageProvider) == 'ko' ? '닫기' : 'Close',
          confirmLabel: s.settings,
        );
        if (go == true) {
          AppSettings.openAppSettings(type: AppSettingsType.notification);
        }
        return;
      }
    }

    setState(() => _pushEnabled = value);
    await pushService.setEnabled(value);
    await pushService.incrementToggleCount();
    analytics.log('push_toggle', {'enabled': value});

    if (value) {
      // ON → 서버 행 전체 재동기화(기본 필터 + 키워드 조건 + 추천 설정).
      // OFF 때 행이 삭제되므로 필터가 비어도 복원해야 함(2026-10-09).
      pushService.resyncServer(
        filter: ref.read(filterStateProvider),
        langCode: ref.read(languageProvider),
      );
      pushService.markSynced();
    } else {
      // OFF → 서버에서 구독 삭제
      pushService.deleteSubscription();
    }
  }

  // 검색어 조건의 토글·삭제는 설정에서 제거 — 조건은 신규 공고 알림의
  // 한 줄 요약으로만 표시(등록·변경·해제는 검색 화면 종 버튼에서, 2026-10-09).

  // 조건 칩(×삭제) — 검색어 칩=알림 해제(navy) / 필터 칩=홈 필터 해제(carrot).
  Widget _condChip(String label, VoidCallback onRemove, {bool navy = false}) {
    // 홈 칩 행과 동일 톤: 연한 배경+진한 글자(2026-10-10).
    final bg = navy ? AppColors.navyLight : AppColors.carrotLight;
    final fg = navy ? AppColors.navy : AppColors.carrotDark;
    final icon = navy ? AppColors.navy : AppColors.carrot;
    return GestureDetector(
      onTap: onRemove,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 6, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
            const SizedBox(width: 3),
            Icon(Icons.close, size: 13, color: icon),
          ],
        ),
      ),
    );
  }

  // 신규 공고 알림: 조건(칩)·알림시간 — 토글과 같은 블록(구분선 없음).
  // 조건 = 검색어 칩(등록된 경우) + 홈 필터 칩. 각 × 로 개별 삭제.
  Widget _alertConditionRow(dynamic s) {
    // 검색어 칩(등록된 알림, 공유 프로바이더) — × 시 해제. 남색 칩으로 구분.
    final keyword = ref.watch(searchAlertProvider)?['keyword'] as String?;
    // 필터 칩(현재 홈 필터, 실시간) — × 시 홈 필터에서 해제.
    final filterChips = buildFilterChipData(ref.watch(filterStateProvider), ref);

    final chips = <Widget>[
      if (keyword != null && keyword.isNotEmpty)
        _condChip(keyword,
            () => ref.read(searchAlertProvider.notifier).clear(),
            navy: true),
      for (final c in filterChips) _condChip(c.label, c.onRemove),
    ];

    // 칩 없으면 구분선만 (토글 행과 다음 블록 분리) — 알림시간 표시는
    // 제거(2026-10-10, 굳이 보여줄 필요 없음).
    if (chips.isEmpty) {
      return Container(height: 1, color: const Color(0xFFF5F5F5));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 0, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 칩(높이 ~26)의 첫 줄과 세로 중앙을 맞추기 위한 보정(2026-10-10).
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('·  ${s.settingsFilterHead}  ',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray400)),
          ),
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: chips),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet() {
    final currentLang = ref.read(languageProvider);
    final langNotifier = ref.read(languageProvider.notifier);
    showLanguageSheet(
      context,
      title: ref.read(stringsProvider).appLanguage,
      currentLang: currentLang,
      onSelect: (code) {
        analytics.languageChanged(currentLang, code);
        langNotifier.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  String _providerLabel(String provider) {
    if (provider.isEmpty) return provider;
    return provider[0].toUpperCase() + provider.substring(1);
  }

  // 로그아웃·회원탈퇴 — 마이페이지에서 설정 화면 하단으로 이동(2026-09-26).
  Future<void> _confirmLogout(
    BuildContext context,
    AppStrings s,
    ApplicantProfile profile,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      question: s.myPageLogoutConfirmTitle,
      boxTitle: _providerLabel(profile.snsProvider),
      boxSubtitle: profile.email,
      desc: s.myPageLogoutConfirmDesc,
      confirmLabel: s.myPageLogout,
      cancelLabel: s.cancel,
    );
    if (confirmed == true) {
      ref.read(accountProvider.notifier).logout();
    }
  }

  Future<void> _confirmWithdraw(BuildContext context, AppStrings s) async {
    final confirmed = await showConfirmDialog(
      context,
      question: s.myPageWithdrawConfirmTitle,
      desc: s.myPageWithdrawConfirmDesc,
      confirmLabel: s.myPageWithdraw,
      cancelLabel: s.cancel,
      destructive: true,
    );
    if (confirmed == true) {
      // 서버(auth 계정) 삭제가 성공해야 완료 — 실패 시 로그인 유지, 재시도 가능.
      try {
        await ref.read(accountProvider.notifier).withdraw();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.accountWithdrawFailed),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.accountWithdrawDoneToast),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);
    final testMode = ref.watch(testModeProvider);
    final profile = ref.watch(accountProvider).profile;
    final isLoggedIn = profile != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  const AppBackButton(),
                  Expanded(
                    child: GestureDetector(
                      // 숨김: 제목 7탭 → 테스트 모드 잠금해제
                      behavior: HitTestBehavior.opaque,
                      onTap: _onVersionTap,
                      child: Text(
                        s.settings,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                // 상단 16 — 첫 섹션 위 여백을 다른 섹션(SizedBox16+헤더8=24)과
                // 맞춤(16+헤더8=24, 2026-10-09).
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                children: [
                  // 계정 섹션
                  _SectionHeader(title: s.settingsAccountSection),
                  _SettingsTile(
                    title: isLoggedIn ? s.myPageTitle : s.accountLoginTitle,
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.gray300,
                    ),
                    onTap: () async {
                      // 세션 복원이 안 끝났을 수 있어 서버 확인까지 대기.
                      final loggedIn = await ref
                          .read(accountProvider.notifier)
                          .ensureLoaded();
                      if (!context.mounted) return;
                      if (loggedIn) {
                        context.push('/my-page');
                      } else {
                        // 로그인 성공(기존 회원) 시 마이페이지로 자동 이동.
                        showLoginSignupSheet(
                          context,
                          onLoggedIn: () => context.push('/my-page'),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // 알림 섹션
                  _SectionHeader(title: s.notifications),
                  _SettingsTile(
                    title: s.newJobAlerts,
                    subtitle: s.newJobAlertsDesc,
                    showDivider: false,
                    trailing: _loaded
                        ? Switch(
                            value: _pushEnabled,
                            onChanged: _togglePush,
                            activeColor: AppColors.carrot,
                          )
                        : const SizedBox(width: 48),
                  ),
                  _alertConditionRow(s),
                  // 추천 공고 토글: 2.1.6 배포에서 제외(2026-10-10) — 발송도
                  // 크롤러에 보류 전달. 재도입 시 git 히스토리 참조.

                  const SizedBox(height: 16),

                  // 언어 섹션
                  _SectionHeader(title: s.language),
                  _SettingsTile(
                    title: s.appLanguage,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nativeLanguageName(langCode),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppColors.gray300,
                        ),
                      ],
                    ),
                    onTap: _showLanguageSheet,
                  ),

                  // 테스트 모드 토글 (제목 7탭으로 잠금해제됐거나 이미 ON일 때만 노출)
                  if (_testUnlocked || testMode) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'TEST'),
                    _SettingsTile(
                      title: '테스트 모드',
                      subtitle: 'testing 사이트(JobnShop) 포함 표시',
                      trailing: Switch(
                        value: testMode,
                        onChanged: (v) =>
                            ref.read(testModeProvider.notifier).set(v),
                        activeColor: AppColors.carrot,
                      ),
                    ),
                  ],

                  // [DEV] 디버그 전용 진입점 (릴리즈 빌드엔 미노출)
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'DEV'),
                    _SettingsTile(
                      title: 'Apply WebView 분석',
                      subtitle: 'K-HIRE 로그인/폼 HTML 덤프 도구',
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.gray300,
                      ),
                      onTap: () => context.push('/dev/apply-webview'),
                    ),
                  ],
                ],
              ),
            ),
            // 로그아웃·회원탈퇴 — 스크롤 밖, 화면 가장 하단 왼쪽 고정.
            // 마이페이지에서 이동해옴(2026-09-26 사용자 지시), 로그인 시에만 노출.
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _confirmLogout(context, s, profile),
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
                      onTap: () => _confirmWithdraw(context, s),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // top 8 — 섹션 앞 SizedBox(16)와 합쳐 24px(과다 32px 방지, 2026-10-09).
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.gray400,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, showDivider ? 14 : 6),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFF5F5F5)))
              : null,
        ),
        child: Row(
          // trailing(토글·값)을 제목 줄에 맞춤 — 설명이 길어도 안 쳐짐(통일).
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
