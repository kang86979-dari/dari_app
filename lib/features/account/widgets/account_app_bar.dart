import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// 계정 관련 전체화면 공통 앱바 규칙.
/// 뒤로가기는 아이콘만(라벨 없음), 타이틀은 항상 중앙 정렬 —
/// "← 제목"처럼 뒤로가기 버튼의 라벨로 오인되지 않게 하기 위함.
///
/// Scaffold.appBar 슬롯에 넣지 말 것 — 커스텀 위젯은 상태바 세이프에어리어를
/// 자동으로 확보해주지 않아 시계/배터리 아이콘과 겹침. 반드시 아래처럼
/// `Scaffold(body: SafeArea(child: Column([AccountAppBar(...), Expanded(...)])))`
/// 형태로, body 맨 위 자식으로 배치할 것.
class AccountAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  /// 오른쪽 액션(예: 지원 내역의 편집 버튼). 없으면 뒤로가기와 같은 폭의
  /// 여백을 둬서 타이틀 중앙 정렬 유지.
  final Widget? trailing;

  const AccountAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  static const height = 52.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: AppColors.black,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}
