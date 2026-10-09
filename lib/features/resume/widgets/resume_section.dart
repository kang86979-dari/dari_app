import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

/// 이력서 섹션 헤더 (라벨 + 필수 표시 + 선택적 "추가" 버튼).
class ResumeSection extends StatelessWidget {
  final String title;
  final bool required;
  final VoidCallback? onAdd;
  const ResumeSection({
    super.key,
    required this.title,
    this.required = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.carrot),
            ),
          ],
          const Spacer(),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Icon(Icons.add, size: 22, color: AppColors.carrot),
              ),
            ),
        ],
      ),
    );
  }
}

/// 피커 열기 행 (선택값 or 힌트 + chevron).
class ResumePickerRow extends StatelessWidget {
  final String? value;
  final String hint;
  final VoidCallback onTap;
  const ResumePickerRow({
    super.key,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filled = value != null && value!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                filled ? value! : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: filled ? AppColors.gray900 : AppColors.gray300,
                  fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}

/// 추가된 항목 칩 행 (라벨 + 삭제 ×).
class ResumeChipRow extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const ResumeChipRow({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.carrotLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.carrotDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.close, size: 18, color: AppColors.carrot),
            ),
          ),
        ],
      ),
    );
  }
}
