import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/utils/mrec_ad_controller.dart';

/// 리스트에 삽입되는 MREC(300x250) 광고. 인스턴스 생성/캐싱/해제는 화면 단위 [MrecAdController]가 관리.
class MrecAdCard extends StatefulWidget {
  const MrecAdCard({
    super.key,
    required this.controller,
    required this.slot,
  });

  final MrecAdController controller;
  final int slot;

  @override
  State<MrecAdCard> createState() => _MrecAdCardState();
}

class _MrecAdCardState extends State<MrecAdCard> {
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
      // 로드 전/실패 시 공간 예약 없이 접음.
      return const SizedBox.shrink();
    }
    // 300x250 고정. MREC 크리에이티브가 자체 테두리를 가져 별도 테두리는 넣지 않음(이중 방지).
    // 폭 부족분은 가운데 정렬(배경 흰색).
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      height: AdSize.mediumRectangle.height.toDouble(), // 250
      color: Colors.white,
      alignment: Alignment.center,
      child: SizedBox(
        width: AdSize.mediumRectangle.width.toDouble(), // 300
        height: AdSize.mediumRectangle.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
