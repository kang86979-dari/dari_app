import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'sheet_handle.dart';

/// 정렬 선택 바텀시트 — 즐겨찾기 스타일을 공용화(2026-09-26).
/// 즐겨찾기·지원 내역·내 메모가 동일한 UI/UX를 쓰도록 한 곳에 정의.
class SortSheetOption {
  final String label;
  final bool selected;
  final VoidCallback onSelect;

  const SortSheetOption({
    required this.label,
    required this.selected,
    required this.onSelect,
  });
}

void showSortOptionsSheet(
  BuildContext context, {
  required String title,
  required List<SortSheetOption> options,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: SheetHandle(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
        for (final option in options)
          GestureDetector(
            onTap: () {
              option.onSelect();
              Navigator.pop(sheetContext);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              color: option.selected
                  ? AppColors.carrotLight
                  : Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: option.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: option.selected
                          ? AppColors.carrotDark
                          : AppColors.black,
                    ),
                  ),
                  if (option.selected)
                    const Icon(Icons.check, size: 18, color: AppColors.carrot),
                ],
              ),
            ),
          ),
        SizedBox(height: 20 + MediaQuery.of(sheetContext).padding.bottom),
      ],
    ),
  );
}
