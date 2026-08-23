import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/utils/native_ad_controller.dart';

/// 리스트에 삽입되는 네이티브 광고 (Flutter 템플릿 방식, 공고 카드 느낌).
/// 실제 인스턴스 생성/캐싱/해제는 [NativeAdController]가 화면 단위로 관리한다.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({
    super.key,
    required this.controller,
    required this.slot,
    this.height,
  });

  final NativeAdController controller;
  final int slot;

  /// small 템플릿 표시 높이(null이면 92).
  /// 주의: iOS small 템플릿은 미디어뷰가 고정 크기라 높이를 키워도
  /// 120x120 validator 경고는 안 사라짐(영상 광고 한정 WARNING이라 수용).
  final double? height;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {

  @override
  void initState() {
    super.initState();
    widget.controller.ensure(widget.slot, _onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.controller.adFor(widget.slot);
    if (!widget.controller.isLoaded(widget.slot) || ad == null) {
      // 로드 전/실패 시 공간을 예약하지 않아 리스트가 밀리지 않게 함.
      return const SizedBox.shrink();
    }
    // 안드로이드에서 플랫폼뷰(광고)를 둥글게 클리핑하면 모서리가 뚫리는 이슈가 있어
    // 라운드 클리핑 없이 사각 단일 테두리만 적용(구멍/이중선 방지).
    final h = widget.height ?? 92.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
      ),
      child: AdWidget(ad: ad),
    );
  }
}
