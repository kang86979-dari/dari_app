import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'app_sheet.dart';

/// 정렬 선택 바텀시트 — 공용 껍데기(showAppSheet) 위에 옵션 목록만(2026-10-10).
/// 즐겨찾기·검색·내 메모가 동일한 UI/UX를 쓰도록 한 곳에 정의.
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
  showAppSheet<void>(
    context,
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              option.onSelect();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color:
                  option.selected ? AppColors.carrotLight : Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          option.selected ? FontWeight.w700 : FontWeight.w500,
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
      ],
    ),
  );
}
