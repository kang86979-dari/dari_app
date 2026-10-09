import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/apply_method_style.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/sheet_handle.dart';
import '../../core/widgets/apply_confirm_dialog.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/job.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/pending_apply_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/test_mode_provider.dart';
import '../../providers/applied_job_provider.dart';
import '../../providers/resume_provider.dart';
import '../account/login_signup_sheet.dart';
import '../apply/sms/sms_prepare_screen.dart';
import '../apply/sms/khire_apply_webview_screen.dart';
import '../resume/resume_edit_screen.dart';

/// 지원방법 선택 바텀시트 (2026-09-14 UI A안 + 2026-09-20 다리 로그인 연결).
/// - 전화: 로그인 필수(2026-09-26 변경, 지원 기록 관리 목적), 광고 없이 발신.
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
  // 방문접수·번호없는 전화는 노출 안 함 — 노출할 방법이 하나도 없으면 바로 사이트로.
  final phoneNo = (job.applyContact?['phone'] as String?) ?? '';
  final hasVisibleMethod = job.applyMethods.any((m) =>
      m != 'visit' &&
      !(m == 'phone' && phoneNo.isEmpty) &&
      strings.applyMethodLabel(m) != null);
  if (!hasVisibleMethod) {
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

/// 지원방법 하나를 선택해 그 방법으로 진행 — 시트 타일과 **공고 상세 지원방법
/// 칩**이 공유하는 공용 로직(2026-10-05). 칩에서 바로 호출하면 "지원하러 가기"를
/// 거치지 않고 해당 방법으로 이동한다.
/// [closeSheet]=true면 호출 전에 현재 바텀시트를 닫는다(시트 타일 경로).
Future<void> selectApplyMethod(
  BuildContext context,
  WidgetRef ref, {
  required Job job,
  required AppStrings strings,
  required String code,
  required VoidCallback onProceedToSite,
  bool closeSheet = false,
}) async {
  analytics.log('apply_method_selected', {'job_id': job.id, 'method': code});
  // 콜백(onLoggedIn)에서 쓸 네비게이터/프로바이더 컨테이너를 async gap 전에
  // 미리 캡처 — 시트가 pop되면 시트의 ref/context가 dispose되므로, 로그인 후
  // 콜백에서 ref 대신 이 컨테이너를 쓴다(로그인 후 전화 자동진행 버그 수정, 2026-10-05).
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final container = ProviderScope.containerOf(context, listen: false);
  if (closeSheet) Navigator.of(context).pop();

  if (code == 'phone') {
    final phone = job.applyContact?['phone'] as String?;
    if (phone == null || phone.isEmpty) return;
    // 전화도 로그인 필수(2026-09-26 사용자 확정) — 지원 기록 관리를 위해.
    final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
    if (!loggedIn) {
      // 시트가 pop되면 이 위젯 context가 죽으므로 root context로 로그인 시트를 띄움
      // (비로그인 전화/문자/간편/홈페이지에서 로그인 시트가 안 뜨던 버그 수정, 2026-10-05).
      // 로그인·회원가입 완료 후 자동 발신 — ref 대신 캡처한 container 사용.
      showLoginSignupSheet(
        rootNavigator.context,
        onLoggedIn: () => _dialAndRecord(container, job, phone),
      );
      return;
    }
    await _dialAndRecord(container, job, phone);
    return;
  }

  // 채팅: K-HIRE 앱에서만 가능 → 플랫폼 스토어의 K-HIRE 앱 페이지로 이동.
  // 복귀 시 "채팅으로 지원하셨나요?" 확인용 대기 저장(전화와 동일 패턴).
  if (code == 'chat') {
    final langCode = ref.read(languageProvider);
    final isIos = Platform.isIOS;
    final store = isIos ? 'App Store' : 'Google Play';
    // 시트가 닫힌 뒤면 이 위젯 context가 unmount되므로 root context로 다이얼로그.
    final go = await showApplyConfirmDialog(
      rootNavigator.context,
      company: job.getDisplayCompany(langCode),
      title: job.getTitle(langCode),
      question: strings.applyChatStoreMoveQuestion(store),
      desc: strings.applyChatStoreMoveDesc,
      yesLabel: strings.yes,
      noLabel: strings.no,
    );
    if (go != true) return;
    await PendingApplyService.save(PendingPhoneApply(
      jobId: job.id,
      title: job.getTitle(langCode),
      company: job.getDisplayCompany(langCode),
      siteName: job.siteName ?? '',
      location: job.getShortLocation(langCode),
      dialedAt: DateTime.now(),
      method: 'chat',
    ));
    final url = isIos
        ? 'https://apps.apple.com/app/id6754261988'
        : 'https://play.google.com/store/apps/details?id=kr.co.khire';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return;
  }

  // 문자 지원 + K-HIRE 공고: 전용 메시지 화면 → K-HIRE 웹뷰(JS 주입).
  if (code == 'sms' && _isKhire(job)) {
    final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
    if (!loggedIn) {
      // 시트가 pop되면 이 위젯 context가 죽으므로 root context로 로그인 시트를 띄움
      // (비로그인 전화/문자/간편/홈페이지에서 로그인 시트가 안 뜨던 버그 수정, 2026-10-05).
      showLoginSignupSheet(
        rootNavigator.context,
        onLoggedIn: () => _openSmsPrepare(rootNavigator, job),
      );
      return;
    }
    _openSmsPrepare(rootNavigator, job);
    return;
  }

  // 간편지원 + K-HIRE 공고: 메시지(각오한마디) 기반 → SMS와 동일하게 문구 작성
  // (SmsPrepareScreen) → 웹뷰(simple). 로그인 필수.
  if (code == 'simple' && _isKhire(job)) {
    final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
    if (!loggedIn) {
      showLoginSignupSheet(
        rootNavigator.context,
        onLoggedIn: () =>
            _openSmsPrepare(rootNavigator, job, applyType: 'simple'),
      );
      return;
    }
    _openSmsPrepare(rootNavigator, job, applyType: 'simple');
    return;
  }

  // 홈페이지 지원 + K-HIRE 공고: 외부 URL 미수집 → K-HIRE 공고 상세로 보내
  // 사용자가 "홈페이지 지원"을 직접 탭. K-HIRE 정책상 로그인 필수, 닫을 때
  // "홈페이지로 지원하셨나요?" 확인(2026-10-05 사용자 확정).
  if (code == 'homepage' && _isKhire(job)) {
    final langCode = ref.read(languageProvider);
    final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
    if (!loggedIn) {
      // 시트가 pop되면 이 위젯 context가 죽으므로 root context로 로그인 시트를 띄움
      // (비로그인 전화/문자/간편/홈페이지에서 로그인 시트가 안 뜨던 버그 수정, 2026-10-05).
      showLoginSignupSheet(
        rootNavigator.context,
        onLoggedIn: () => _openHomepageApply(rootNavigator, job, langCode),
      );
      return;
    }
    _openHomepageApply(rootNavigator, job, langCode);
    return;
  }

  // 온라인(이력서) 지원 + K-HIRE 공고: Dari 이력서(canonical) 확인 →
  // 없으면 작성 화면 먼저 → 웹뷰에서 Regist.asp 도달 시 localStorage 주입.
  // K-HIRE에 이력서가 이미 있으면(resumecount>0) K-HIRE가 Regist를 건너뛰어
  // 주입 없이 바로 지원됨 — 분기는 K-HIRE 라우터가 처리(2026-10-05).
  if (code == 'online' && _isKhire(job)) {
    final langCode = ref.read(languageProvider);
    final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
    if (!loggedIn) {
      showLoginSignupSheet(
        rootNavigator.context,
        onLoggedIn: () => _openOnlineApply(container, rootNavigator, job, langCode),
      );
      return;
    }
    await _openOnlineApply(container, rootNavigator, job, langCode);
    return;
  }

  // 세션 복원이 안 끝났을 수 있어 서버 확인까지 대기.
  final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
  if (loggedIn) {
    onProceedToSite();
    return;
  }
  showLoginSignupSheet(
    rootNavigator.context,
    showSkipOption: true,
    onSkip: onProceedToSite,
    onLoggedIn: onProceedToSite,
  );
}

/// 전화 발신 — 즉시 기록하지 않고 "확인 대기"로 저장(2026-09-26). 앱 복귀 시
/// "전화로 지원하셨나요?" 확인 후 '네'만 기록.
Future<void> _dialAndRecord(
    ProviderContainer container, Job job, String phone) async {
  // [TEST] 테스트 모드에서는 테스트 번호로 발신(실공고 사장님 오발신 방지).
  final dialTo = container.read(testModeProvider) ? '01053372951' : phone;
  final opened = await launchUrl(Uri.parse('tel:$dialTo'));
  if (!opened) return;
  final langCode = container.read(languageProvider);
  await PendingApplyService.save(
    PendingPhoneApply(
      jobId: job.id,
      title: job.getTitle(langCode),
      company: job.getDisplayCompany(langCode),
      siteName: job.siteName ?? '',
      location: job.getShortLocation(langCode),
      dialedAt: DateTime.now(),
    ),
  );
}

bool _isKhire(Job job) => (job.siteName ?? '').toUpperCase().contains('HIRE');

/// 문자/간편 공통 — 문구 작성(SmsPrepareScreen) → 웹뷰. applyType으로 구분.
void _openSmsPrepare(NavigatorState navigator, Job job,
    {String applyType = 'talk'}) {
  navigator.push(MaterialPageRoute(
    builder: (_) => SmsPrepareScreen(job: job, applyType: applyType),
  ));
}

/// 온라인(이력서) 지원 — Dari 이력서가 없으면 작성 화면 먼저, 완성돼 있으면
/// 바로 웹뷰(online)로. 작성 화면에서 저장하고 돌아오면 이어서 웹뷰 진행.
Future<void> _openOnlineApply(ProviderContainer container,
    NavigatorState navigator, Job job, String langCode) async {
  var resume = await container.read(resumeProvider('khire').future);
  // 주소는 프로필 소관이지만 K-HIRE 간편지원 필수 — 없으면 작성 화면으로
  // 보내 주소까지 채우게 한다(작성 화면 저장 조건에 포함, 2026-10-09).
  final hasAddress =
      (container.read(accountProvider).profile?.addrRoad ?? '').isNotEmpty;
  if (resume == null || !resume.isComplete || !hasAddress) {
    final saved = await navigator.push<bool>(MaterialPageRoute(
      builder: (_) => const ResumeEditScreen(site: 'khire'),
    ));
    if (saved != true) return; // 작성 취소 — 지원 중단
    resume = await container.read(resumeProvider('khire').future);
    // 임시저장(미완성)으로 돌아온 경우 — 지원 진행 안 함(2026-10-09).
    final addrOk =
        (container.read(accountProvider).profile?.addrRoad ?? '').isNotEmpty;
    if (resume == null || !resume.isComplete || !addrOk) return;
  }
  navigator.push(MaterialPageRoute(
    builder: (_) => KhireApplyWebViewScreen(
      job: job,
      message: '',
      wantsImmediateStart: false,
      langCode: langCode,
      applyType: 'online',
      resume: resume,
    ),
  ));
}

/// 홈페이지 지원 — K-HIRE 공고 상세로 보내고, 사용자가 "홈페이지 지원"을
/// 직접 탭해 업체 사이트로. 주입 없음, 닫을 때 지원 여부 확인.
void _openHomepageApply(NavigatorState navigator, Job job, String langCode) {
  navigator.push(MaterialPageRoute(
    builder: (_) => KhireApplyWebViewScreen(
      job: job,
      message: '',
      wantsImmediateStart: false,
      langCode: langCode,
      applyType: 'homepage',
    ),
  ));
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

  // 시트 타일 탭 — 공용 로직(selectApplyMethod)에 위임(시트는 닫고 진행).
  Future<void> _selectMethod(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) =>
      selectApplyMethod(
        context,
        ref,
        job: job,
        strings: strings,
        code: code,
        onProceedToSite: onProceedToSite,
        closeSheet: true,
      );

  /// 이 공고를 해당 방법으로 지원한 최근 일자 (없으면 null).
  DateTime? _appliedAtOf(WidgetRef ref, String code) {
    final rows = ref.watch(appliedJobsProvider).valueOrNull;
    if (rows == null) return null;
    DateTime? latest;
    for (final r in rows) {
      if (r.jobId == job.id && r.method == code) {
        if (latest == null || r.appliedAt.isAfter(latest)) latest = r.appliedAt;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = job.applyContact?['phone'] as String?;
    final hasPhone = (phone ?? '').isNotEmpty;

    // _ApplyMethodsRow와 동일 규칙 — 방문접수 제외, 전화번호 없는 전화 제외,
    // 라벨 없는(미지) 코드 제외, 라벨 중복 제거. (방문접수·번호없는 전화는
    // 노출 안 함, DB엔 유지 — 2026-10-05)
    final seenLabels = <String>{};
    final methods = <String>[];
    for (final m in job.applyMethods) {
      if (m == 'visit') continue;
      if (m == 'phone' && !hasPhone) continue;
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
            const SheetHandle(),
            const SizedBox(height: 12),
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
                style: ApplyMethodStyle.of(code),
                label: strings.applyMethodLabel(code)!,
                // 전화번호는 노출하지 않음(로그인해도) — 항상 설명만 표시.
                subtitle: strings.applyMethodDesc(code),
                // 이 방법으로 이미 지원했으면 ✓ 날짜 표시(선택은 안 막음).
                appliedAt: _appliedAtOf(ref, code),
                onTap: () => _selectMethod(context, ref, code),
              ),
            const SizedBox(height: 12),
            // 회색 텍스트 링크라 잘 안 보인다는 피드백 → 보조 버튼 형태로 톤업
            // (연회색 박스+가운데 정렬, 2026-09-26).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).pop();
                onProceedToSite();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: AppColors.gray600,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${strings.applyViewOriginal}${job.siteName != null ? ' · ${job.siteName}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray600,
                        ),
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
  final ApplyMethodStyle style;
  final String label;
  final String? subtitle;
  final DateTime? appliedAt;
  final VoidCallback onTap;

  const _MethodTile({
    required this.style,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.appliedAt,
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
            // 방법별 색 원형 아이콘 — 공용 정의(ApplyMethodStyle)로 전 화면 통일.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.bg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(style.icon, size: 18, color: style.fg),
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
            if (appliedAt != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 13,
                      color: AppColors.tagGreenTxt,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${appliedAt!.month}/${appliedAt!.day}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tagGreenTxt,
                      ),
                    ),
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
