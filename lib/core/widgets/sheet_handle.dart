import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 바텀시트 공통 상단 바 — 가운데 드래그 핸들 + 오른쪽 X 닫기(2026-09-26).
/// X는 시트만 닫음(아무 동작 안 함). 로그인/가입 시트의 패턴을 공용화한 것.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.gray300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
