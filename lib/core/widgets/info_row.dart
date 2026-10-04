import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 라벨·값 한 행 — 공고 상세 핵심정보 테이블(_InfoRow)과 동일 스타일(기준).
/// 요약본·회원정보 등 "라벨: 데이터" 표시가 필요한 모든 화면에서 공용 사용해
/// 디자인 통일(2026-10-04 사용자 확정, 기준=공고 상세).
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isOrange;
  final bool isLast;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isOrange = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // 값이 없으면 행 자체를 숨김 (상세 테이블과 동일 규칙)
    if (value.trim().isEmpty || value.trim() == '-') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray300)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: isOrange ? 15 : 14,
                  fontWeight: FontWeight.w600,
                  color: isOrange ? AppColors.carrot : AppColors.black,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
