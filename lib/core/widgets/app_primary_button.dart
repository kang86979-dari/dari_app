import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 앱 공통 주 버튼(풀폭 CTA) — 하단 지원하기·결과보기 등 통일(2026-10-10).
/// 높이 52·라운드 14·carrot 배경·흰 글씨 16 w700. 비활성 시 회색.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final on = enabled && onTap != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: on ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.carrot,
          disabledBackgroundColor: AppColors.gray300,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          // 테마 기본 padding(vertical 17)이 고정높이 52를 넘겨 한글 받침이
          // 잘렸음 — padding 재지정 + 최소높이 방식으로 변경(2026-10-11).
          // 긴 언어(독일어 등)는 2줄까지 늘어나며 잘리지 않음.
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          minimumSize: const Size.fromHeight(52),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
        ),
      ),
    );
  }
}
