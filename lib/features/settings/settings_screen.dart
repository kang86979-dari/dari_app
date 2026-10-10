import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../providers/language_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/push_service.dart';
import '../../providers/job_provider.dart';
import '../../providers/test_mode_provider.dart';
import '../../core/widgets/app_dialog.dart';
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
  bool _recommendEnabled = true;
  bool _loaded = false;

  // 테스트 모드 숨김 스위치: 설정 제목 7탭으로 잠금 해제
  int _versionTapCount = 0;
  bool _testUnlocked = false;

  void _onVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 7 && !_testUnlocked) {
      setState(() => _testUnlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테스트 모드 잠금 해제됨'), duration: Duration(seconds: 1)),
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
    final rec = await pushService.isRecommendEnabled();
    if (!mounted) return;
    setState(() => _recommendEnabled = rec);
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

  Future<void> _toggleRecommend(bool v) async {
    setState(() => _recommendEnabled = v);
    await pushService.setRecommendEnabled(v);
    analytics.log('recommend_push_toggle', {'enabled': v});
  }

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
                // 상단 16 — 첫 섹션 위 여백을 다른 섹션(SizedBox16+헤더8=24)과
                // 맞춤(16+헤더8=24, 2026-10-09).
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                children: [
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
                  _SettingsTile(
                    title: s.settingsRecommendPush,
                    subtitle: s.settingsRecommendPushDesc,
                    trailing: Switch(
                      value: _recommendEnabled,
                      onChanged: _pushEnabled ? _toggleRecommend : null,
                      activeColor: AppColors.carrot,
                    ),
                  ),

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
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.gray300),
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
                        onChanged: (v) => ref.read(testModeProvider.notifier).set(v),
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
                      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.gray300),
                      onTap: () => context.push('/dev/apply-webview'),
                    ),
                  ],
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
