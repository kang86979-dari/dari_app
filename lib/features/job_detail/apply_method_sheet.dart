import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/apply_method_style.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/sheet_handle.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/job.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/pending_apply_service.dart';
import '../../providers/account_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/test_mode_provider.dart';
import '../../providers/applied_job_provider.dart';
import '../account/login_signup_sheet.dart';

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

  Future<void> _selectMethod(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    analytics.log('apply_method_selected', {'job_id': job.id, 'method': code});
    Navigator.of(context).pop();

    if (code == 'phone') {
      final phone = job.applyContact?['phone'] as String?;
      if (phone == null || phone.isEmpty) return;
      // 전화도 로그인 필수(2026-09-26 사용자 확정) — 지원 기록 관리를 위해.
      // 비로그인이면 로그인/가입 유도(스킵 없음), 완료 후 자동 발신+기록.
      final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
      if (!loggedIn) {
        if (!context.mounted) return;
        showLoginSignupSheet(
          context,
          onLoggedIn: () => _dialAndRecord(ref, phone),
        );
        return;
      }
      await _dialAndRecord(ref, phone);
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

  /// 전화 발신 — 즉시 기록하지 않고 "확인 대기"로 저장(2026-09-26 사용자
  /// 확정). 앱 복귀/재실행 시 "전화로 지원하셨나요?" 확인 후 '네'만 기록 —
  /// 다이얼러만 열고 통화 안 한 오기록과 미복귀 누락을 동시에 방지.
  Future<void> _dialAndRecord(WidgetRef ref, String phone) async {
    // [TEST] 테스트 모드에서는 실제 구인처 대신 테스트 번호로 발신 —
    // 실공고 사장님한테 전화가 가는 사고 방지(2026-09-26).
    final dialTo = ref.read(testModeProvider) ? '01053372951' : phone;
    final opened = await launchUrl(Uri.parse('tel:$dialTo'));
    if (!opened) return;
    final langCode = ref.read(languageProvider);
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
                subtitle: code == 'phone'
                    ? phone
                    : strings.applyMethodDesc(code),
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
