import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 앱 공통 가운데 다이얼로그 — 모든 확인/안내 팝업의 껍데기·버튼 통일.
/// 2026-10-10 확정 디자인(캡처 기준):
///   타이틀(굵게) > 본문 문장(핵심 단어만 색 강조 가능) > 헬프(작게 회색)
///   > 우측 하단 텍스트 버튼 2개(취소=회색, 확정=carrot 굵게).
///
/// 반환: 확정 true / 취소(또는 바깥 탭) false 또는 null.
/// [body] 리치 본문(색 강조 등) — 주면 [message] 대신 그대로 렌더.
/// [helper] 본문 아래 작은 회색 보조 문구.
/// [confirmDanger] true면 확정 버튼을 urgent(빨강)로 — 삭제 등 파괴적 동작.
Future<bool?> showAppDialog(
  BuildContext context, {
  String? title,
  String? message,
  Widget? body,
  String? helper,
  required String confirmLabel,
  String? cancelLabel,
  bool confirmDanger = false,
  bool barrierDismissible = true,
}) {
  assert(message != null || body != null || helper != null);
  final mainBody = body ??
      (message == null
          ? null
          : Text(
              message,
              style: const TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray900),
            ));
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AppDialogShell(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mainBody != null) mainBody,
          if (helper != null) ...[
            if (mainBody != null) const SizedBox(height: 10),
            Text(
              helper,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.4, color: AppColors.gray400),
            ),
          ],
        ],
      ),
      actions: [
        if (cancelLabel != null)
          AppDialogAction(
            label: cancelLabel,
            onTap: () => Navigator.pop(ctx, false),
          ),
        AppDialogAction(
          label: confirmLabel,
          emphasized: true,
          danger: confirmDanger,
          onTap: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
}

/// 커스텀 본문이 필요한 다이얼로그용 공통 셸(라운드·패딩·제목·액션 통일).
class AppDialogShell extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget> actions;
  const AppDialogShell({
    super.key,
    this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      // 너비: 내용 길이와 무관하게 일정(2026-10-10).
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      actionsPadding: const EdgeInsets.fromLTRB(24, 6, 20, 14),
      title: title == null
          ? null
          : Text(title!,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black)),
      content: SizedBox(width: double.maxFinite, child: content),
      actions: actions,
    );
  }
}

/// 다이얼로그 하단 텍스트 버튼 — 확정(carrot/urgent 굵게) / 취소(회색) 통일.
class AppDialogAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
  final bool danger;
  const AppDialogAction({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = !emphasized
        ? AppColors.gray400
        : (danger ? AppColors.urgent : AppColors.carrot);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 16.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
