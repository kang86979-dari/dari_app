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
  });

  final NativeAdController controller;
  final int slot;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  // small 템플릿 표시 높이. 하단 여백 최소화(콘텐츠에 맞춤).
  static const double _height = 105;

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
    // 공고 카드와 동일한 테두리·라운드 적용(플랫폼뷰를 라운드로 클리핑)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      height: _height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: ad),
    );
  }
}
