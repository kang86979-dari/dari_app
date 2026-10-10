import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../providers/language_provider.dart';

/// 언어 선택 바텀시트 — 홈·설정 공용(2026-10-10, 중복 _LanguageBottomSheet 통합).
/// 공용 껍데기(showAppSheet: 라운드·핸들·제목) 위에 언어 목록만 그린다.
void showLanguageSheet(
  BuildContext context, {
  required String title,
  required String currentLang,
  required void Function(String code) onSelect,
}) {
  showAppSheet<void>(
    context,
    title: title,
    isScrollControlled: true,
    // 16개 언어를 전부 펼치면 풀스크린이 돼서 최대 70%로 제한, 내부 스크롤.
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: _LanguageList(currentLang: currentLang, onSelect: onSelect),
    ),
  );
}

class _LanguageList extends ConsumerWidget {
  final String currentLang;
  final void Function(String code) onSelect;
  const _LanguageList({required this.currentLang, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages =
        ref.watch(supportedLanguagesProvider).valueOrNull ?? const [];
    return ListView.builder(
      shrinkWrap: true,
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final lang = languages[index];
        final isSelected = lang.code == currentLang;
        return GestureDetector(
          onTap: () => onSelect(lang.code),
          child: Container(
            color: isSelected ? AppColors.carrotLight : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.name,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.carrot : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.carrot
                          : const Color(0xFFDDDDDD),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: CircleAvatar(
                              radius: 4, backgroundColor: Colors.white))
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
