import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/sheet_handle.dart';

/// 공고 메모 입력·수정 바텀시트 (지원 내역·공고 상세 공용, 2026-09-26).
/// 반환: 저장 시 trim된 텍스트('' = 삭제), 그냥 닫으면 null.
Future<String?> showJobMemoSheet(
  BuildContext context, {
  required AppStrings strings,
  required String jobTitle,
  String? initialMemo,
}) {
  final controller = TextEditingController(text: initialMemo ?? '');
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Padding(
      // 키보드 높이만큼 올려서 입력창이 가려지지 않게.
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.edit_note, size: 20, color: AppColors.gray600),
              const SizedBox(width: 6),
              Text(
                strings.jobMemoTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            jobTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.gray400),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            minLines: 3,
            maxLength: 500,
            style: const TextStyle(fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: strings.jobMemoPlaceholder,
              hintStyle: const TextStyle(
                color: AppColors.gray300,
                fontSize: 13.5,
              ),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.all(12),
              counterStyle: const TextStyle(
                fontSize: 11,
                color: AppColors.gray300,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // 기존 메모가 있을 때만 삭제 노출.
              if ((initialMemo ?? '').isNotEmpty)
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact(); // 삭제 실행
                    Navigator.of(sheetContext).pop('');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    strings.delete,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.carrot,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    strings.jobMemoSave,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
