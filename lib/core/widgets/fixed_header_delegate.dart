import 'package:flutter/material.dart';

/// 고정 높이 sliver 헤더 델리게이트 — SliverPersistentHeader용 공용(2026-10-11).
/// floating:true 로 쓰면 아래로 스크롤 시 사라지고 위로 올리면 다시 나타남,
/// pinned:true 로 쓰면 항상 고정. (home_screen의 _FixedHeaderDelegate 공용화)
/// 리스트 위에 겹쳐 그려지므로 child에 흰 배경을 주는 것이 안전.
class FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  const FixedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant FixedHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
