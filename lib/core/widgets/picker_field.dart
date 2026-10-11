import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'app_primary_button.dart';

/// 질문형 선택 입력 공용 위젯 (SMS 요약·자기소개서 공용, 2026-10-11).
///
/// 설계 의도 — "칩 나열"은 선택 상태가 전부 주황이라 위계가 없고 정신없음.
/// 대신 **중립 필드(흰 배경·회색 테두리) + 탭하면 하단 리스트 팝업**으로:
///  - 입력 화면은 차분(주황 없음, 선택값만 진한 글자)
///  - "선택됨" 강조는 팝업 안에서만(carrotLight + 체크)
///  - 주황은 하단 저장 버튼 등 포인트에만 남김
///
/// 라벨은 사용자 언어. (조립 결과물의 한국어 변환은 호출부 책임.)

/// 질문 라벨 + 선택 필드(탭 → 팝업). 이력서 피커 행과 동일 톤.
class PickerField extends StatelessWidget {
  final String label;
  final String value; // 선택된 값 표시(비어있으면 hint)
  final String hint;
  final VoidCallback onTap;
  final String? optionalLabel; // "(선택)" 등 — 필수 아님 표시
  final String? postingInfo; // 공고값 등 보조 안내
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.optionalLabel,
    this.postingInfo,
  });

  @override
  Widget build(BuildContext context) {
    final has = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black)),
              if (optionalLabel != null) ...[
                const SizedBox(width: 6),
                Text(optionalLabel!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray400)),
              ],
              if (postingInfo != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(postingInfo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray400)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray100),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      has ? value : hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: has ? AppColors.gray900 : AppColors.gray300,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: AppColors.gray300),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 단일/복수 선택 바텀시트 — 둥근 상단·핸들·제목·선택행(carrotLight+체크).
class PickerSheet {
  PickerSheet._();

  /// 단일 선택. 반환: 선택 cd(또는 재선택 시 해제 신호). 바깥 탭=null(변경 없음).
  /// 호출부는 결과를 받아 처리 — '재선택=해제'는 [PickerUnset]로 전달된다.
  static Future<Object?> pickOne<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T? selected,
  }) {
    return showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _shell(
        context,
        title: title,
        child: ListView(
          shrinkWrap: true,
          children: options
              .map((o) => _row(
                    text: labelOf(o),
                    selected: o == selected,
                    onTap: () => Navigator.of(ctx)
                        .pop(o == selected ? const PickerUnset() : o),
                  ))
              .toList(),
        ),
      ),
    );
  }

  /// 복수 선택 — 확인 버튼으로 확정. 반환: 선택 Set, 바깥 탭=null.
  /// [normalize]: 탭 직후 집합 보정(예: 배타 옵션). [max]: 최대 개수.
  static Future<Set<T>?> pickMulti<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required Set<T> selected,
    required String confirmLabel,
    int? max,
    void Function(Set<T> next, T tapped)? normalize,
  }) {
    final temp = Set<T>.of(selected);
    return showModalBottomSheet<Set<T>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _shell(
          context,
          title: title,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options
                      .map((o) => _row(
                            text: labelOf(o),
                            selected: temp.contains(o),
                            onTap: () => setSheet(() {
                              if (temp.contains(o)) {
                                temp.remove(o);
                              } else if (max == null || temp.length < max) {
                                temp.add(o);
                              }
                              normalize?.call(temp, o);
                            }),
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: AppPrimaryButton(
                  label: confirmLabel,
                  onTap: () => Navigator.of(ctx).pop(Set<T>.of(temp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _shell(BuildContext context,
      {required String title, required Widget child}) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  static Widget _row({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppColors.carrotLight : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          selected ? AppColors.carrotDark : AppColors.gray900)),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 20, color: AppColors.carrot),
          ],
        ),
      ),
    );
  }
}

/// 단일 피커에서 '재선택=해제'를 pop 값으로 전달하기 위한 표식.
class PickerUnset {
  const PickerUnset();
}
