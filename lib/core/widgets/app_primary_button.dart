import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 앱 공통 주 버튼(풀폭 CTA) — 하단 지원하기·결과보기 등 통일(2026-10-10).
/// 높이 52·라운드 14·carrot 배경·흰 글씨 16 w700. 비활성 시 회색.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  /// 저장 등 진행 중 — 스피너 표시 + 비활성(이력서 저장 등, 2026-10-10).
  final bool loading;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final on = enabled && !loading && onTap != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: on ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.carrot,
          disabledBackgroundColor: AppColors.gray300,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
