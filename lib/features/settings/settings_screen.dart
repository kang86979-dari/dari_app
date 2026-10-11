import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../providers/language_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/push_service.dart';
import '../../providers/job_provider.dart';
import '../../providers/test_mode_provider.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_toast.dart';
import '../filter/filter_chips_row.dart';
import '../../providers/search_alert_provider.dart';
import 'widgets/language_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool _pushEnabled = true;
  // 검색어 알림 조건은 공유 프로바이더(searchAlertProvider)에서 watch.
  bool _loaded = false;

  // 테스트 모드 숨김 스위치: 설정 제목 7탭으로 잠금 해제
  int _versionTapCount = 0;
  bool _testUnlocked = false;

  // 하단 버전 표기 (새 디자인, 2026-10-11)
  String _version = '';

  void _onVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 7 && !_testUnlocked) {
      setState(() => _testUnlocked = true);
      showAppToast(context, '테스트 모드 잠금 해제됨', icon: Icons.lock_open);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPushSetting();
    _loadAlertConditions();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
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
    final osAllowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
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
      showAppToast(
          context,
          ref.read(languageProvider) == 'ko'
              ? '오늘 변경 횟수를 초과했습니다. 내일 다시 시도해주세요.'
              : 'Daily limit reached. Please try again tomorrow.',
          icon: Icons.info_outline);
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
          borderRadius: BorderRadius.circular(8),
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

  // 신규 공고 알림 조건 — 알림 타일 footer로 들어감(설명 아래, 2026-10-11).
  // 조건 = 검색어 칩(등록된 경우, navy) + 홈 필터 칩(carrot). 각 × 개별 삭제.
  // 라벨+칩을 한 Wrap에 담아 자연스럽게 흐르게(외톨이 라벨/공백 제거).
  Widget _condRow(dynamic s) {
    final keyword = ref.watch(searchAlertProvider)?['keyword'] as String?;
    final filterChips = buildFilterChipData(ref.watch(filterStateProvider), ref);

    final chips = <Widget>[
      if (keyword != null && keyword.isNotEmpty)
        _condChip(keyword,
            () => ref.read(searchAlertProvider.notifier).clear(),
            navy: true),
      for (final c in filterChips) _condChip(c.label, c.onRemove),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    // 타일(토글 행) 아래, 카드 내부. 토글/아이콘은 위 타일에 그대로 두고
    // 조건은 아래로 분리 — 라벨+칩 한 Wrap에 담아 자연스럽게(2026-10-11).
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(s.settingsFilterHead,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray400)),
          ...chips,
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);
    final testMode = ref.watch(testModeProvider);

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
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: 40, height: 40,
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
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
                // 새 디자인(2026-10-11): 섹션 = 테두리 카드(보조 위계) +
                // 역할색 아이콘(알림=carrot / 언어=teal) + 하단 버전 표기.
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                children: [
                  // 언어 섹션 — 외국인 사용자 1순위라 최상단(2026-10-11).
                  _SectionHeader(title: s.language),
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.language,
                        iconBg: AppColors.tealLight,
                        iconColor: AppColors.teal,
                        title: s.appLanguage,
                        showDivider: false,
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
                            const Icon(Icons.chevron_right,
                                size: 20, color: AppColors.gray300),
                          ],
                        ),
                        onTap: _showLanguageSheet,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 알림 섹션 — 조건 칩은 알림 타일 안(설명 아래)에 footer로 포함.
                  _SectionHeader(title: s.notifications),
                  _SectionCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        iconBg: AppColors.carrotLight,
                        iconColor: AppColors.carrot,
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
                      // 조건 칩 — 타일 아래 카드 내부 별도 행(드래프트 condrow).
                      _condRow(s),
                    ],
                  ),
                  // 추천 공고 토글: 2.1.6 배포에서 제외(2026-10-10) — 발송도
                  // 크롤러에 보류 전달. 재도입 시 git 히스토리 참조.

                  // 테스트 모드 토글 (제목 7탭으로 잠금해제됐거나 이미 ON일 때만 노출)
                  if (_testUnlocked || testMode) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'TEST'),
                    _SectionCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.science_outlined,
                          iconBg: AppColors.gray50,
                          iconColor: AppColors.gray600,
                          title: '테스트 모드',
                          subtitle: 'testing 사이트(JobnShop) 포함 표시',
                          showDivider: false,
                          trailing: Switch(
                            value: testMode,
                            onChanged: (v) =>
                                ref.read(testModeProvider.notifier).set(v),
                            activeColor: AppColors.carrot,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // [DEV] 디버그 전용 진입점 (릴리즈 빌드엔 미노출)
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(title: 'DEV'),
                    _SectionCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.bug_report_outlined,
                          iconBg: AppColors.gray50,
                          iconColor: AppColors.gray600,
                          title: 'Apply WebView 분석',
                          subtitle: 'K-HIRE 로그인/폼 HTML 덤프 도구',
                          showDivider: false,
                          trailing: const Icon(Icons.chevron_right,
                              size: 20, color: AppColors.gray300),
                          onTap: () => context.push('/dev/apply-webview'),
                        ),
                      ],
                    ),
                  ],

                  // 하단 버전
                  if (_version.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'Dari $_version',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray300),
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

/// 설정 섹션 카드 — 테두리 rounded 컨테이너(보조 위계, 2026-10-11 새 디자인).
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        // 홈 카드와 통일: 테두리 대신 미세 그림자(2026-10-11).
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F14161B), blurRadius: 3, offset: Offset(0, 1)),
          BoxShadow(
              color: Color(0x0D14161B), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
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
  // 역할색 아이콘 칩(알림=carrot / 언어=teal 등).
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.icon,
    this.iconBg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(0xFFF5F5F5)))
              : null,
        ),
        child: Row(
          // 아이콘·제목·trailing(토글·값) 전부 세로 중앙 정렬(2026-10-11).
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg ?? AppColors.gray50,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor ?? AppColors.gray600),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
