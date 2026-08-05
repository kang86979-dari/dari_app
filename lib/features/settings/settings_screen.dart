import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../providers/language_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/push_service.dart';
import '../../providers/job_provider.dart';
import '../../providers/test_mode_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool _pushEnabled = true;
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
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
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
      final s = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(languageProvider) == 'ko'
            ? '오늘 변경 횟수를 초과했습니다. 내일 다시 시도해주세요.'
            : 'Daily limit reached. Please try again tomorrow.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (value) {
      // OS 권한 확인
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        // 권한 거부됨 → 다이얼로그로 OS 설정 안내
        if (!mounted) return;
        final s = ref.read(stringsProvider);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Text(
              s.enableNotificationsInSettings,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ref.read(languageProvider) == 'ko' ? '닫기' : 'Close',
                  style: const TextStyle(color: Color(0xFF999999))),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  AppSettings.openAppSettings(type: AppSettingsType.notification);
                },
                child: Text(s.settings,
                  style: const TextStyle(color: AppColors.carrot, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() => _pushEnabled = value);
    await pushService.setEnabled(value);
    await pushService.incrementToggleCount();
    analytics.log('push_toggle', {'enabled': value});

    if (value) {
      // ON → 필터 있으면 구독 등록
      final filter = ref.read(filterStateProvider);
      if (!filter.isEmpty) {
        final langCode = ref.read(languageProvider);
        pushService.upsertSubscription(filter: filter, langCode: langCode);
        pushService.markSynced();
      }
    } else {
      // OFF → 서버에서 구독 삭제
      pushService.deleteSubscription();
    }
  }

  void _showLanguageSheet() {
    final currentLang = ref.read(languageProvider);
    final langNotifier = ref.read(languageProvider.notifier);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LanguageBottomSheet(
        currentLang: currentLang,
        title: ref.read(stringsProvider).appLanguage,
        onSelect: (code) {
          analytics.languageChanged(currentLang, code);
          langNotifier.setLanguage(code);
          Navigator.pop(context);
        },
      ),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 알림 섹션
                  _SectionHeader(title: s.notifications),
                  _SettingsTile(
                    title: s.newJobAlerts,
                    subtitle: s.newJobAlertsDesc,
                    trailing: _loaded
                        ? Switch(
                            value: _pushEnabled,
                            onChanged: _togglePush,
                            activeColor: AppColors.carrot,
                          )
                        : const SizedBox(width: 48),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
        ),
        child: Row(
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

class _LanguageBottomSheet extends ConsumerWidget {
  final String currentLang;
  final String title;
  final void Function(String code) onSelect;

  const _LanguageBottomSheet({
    required this.currentLang,
    required this.title,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(supportedLanguagesProvider);
    final languages = languagesAsync.valueOrNull ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 14, bottom: 4),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('×', style: TextStyle(fontSize: 24, color: Color(0xFFBBBBBB))),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = lang.code == currentLang;
              return GestureDetector(
                onTap: () => onSelect(lang.code),
                child: Container(
                  color: isSelected ? AppColors.carrotLight : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.black)),
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.carrot : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.carrot : const Color(0xFFDDDDDD),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Center(child: CircleAvatar(radius: 4, backgroundColor: Colors.white))
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
