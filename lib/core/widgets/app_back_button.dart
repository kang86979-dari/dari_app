import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

/// 공용 뒤로가기 버튼(`<`).
///
/// 화면마다 헤더를 따로 구현하면서 아이콘 글리프(arrow_back_ios /
/// arrow_back_ios_new / chevron_left)·크기(18/20)·좌측 여백이 제각각이던 걸
/// 하나로 통일한다. 모든 커스텀 헤더는 이 위젯을 써서 `<`의 위치를 맞춘다.
/// (닫기 X 버튼은 별개 — 웹뷰 등에서 의도적으로 사용, 통일 대상 아님.)
///
/// onTap 미지정 시 `context.pop()`.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;

  const AppBackButton({super.key, this.onTap, this.color = AppColors.black});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => context.pop(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.arrow_back_ios_new, size: 20, color: color),
      ),
    );
  }
}
