import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 빈 목록 공통 플레이스홀더 — 아이콘(연한 원 배경) + 제목 + 설명 + CTA 버튼.
/// 지원 내역·내 메모 등 "아직 없어요" 화면이 심심하다는 피드백으로 통일(2026-09-26).
class EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.carrotLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 40, color: AppColors.carrot),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.gray400,
              ),
            ),
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 22),
              // 고정폭(180) 금지 — 긴 번역은 버튼이 내용만큼 늘어남(2026-10-11).
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180),
                // 드래프트: 빈상태 CTA = 외곽선형(흰 배경 + carrot 테두리/글자).
                child: OutlinedButton(
                  onPressed: onButton,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.carrot,
                    side: const BorderSide(color: AppColors.carrot, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonLabel!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
