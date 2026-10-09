import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 물음표(ⓘ) 아이콘 옆에 뜨는 말풍선 안내.
///
/// 공통 다이얼로그(화면 중앙 큰 팝업)가 아니라, 누른 아이콘 바로 아래에
/// 작은 풍선으로 안내를 띄운다. 라벨 옆 도움말 용도 전용 공용 위젯 —
/// 다른 화면에서도 `HelpBalloon(title:..., body:...)` 그대로 재사용(2026-10-05).
class HelpBalloon extends StatefulWidget {
  final String? title;
  final String body;
  final double iconSize;
  final Color iconColor;

  const HelpBalloon({
    super.key,
    this.title,
    required this.body,
    this.iconSize = 15,
    this.iconColor = AppColors.gray400,
  });

  @override
  State<HelpBalloon> createState() => _HelpBalloonState();
}

class _HelpBalloonState extends State<HelpBalloon> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  void _toggle() {
    if (_entry != null) {
      _remove();
      return;
    }
    _entry = _build();
    Overlay.of(context).insert(_entry!);
  }

  OverlayEntry _build() {
    return OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // 바깥 아무 곳이나 탭하면 닫힘.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _remove,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              // 아이콘 왼쪽 기준, 바로 아래로 풍선을 띄움.
              offset: const Offset(-8, 20),
              child: Align(
                alignment: Alignment.topLeft,
                child: _BalloonBody(title: widget.title, body: widget.body),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(Icons.help_outline,
              size: widget.iconSize, color: widget.iconColor),
        ),
      ),
    );
  }
}

class _BalloonBody extends StatelessWidget {
  final String? title;
  final String body;
  const _BalloonBody({this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width - 48;
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 위를 향한 작은 꼬리.
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: CustomPaint(
              size: Size(16, 7),
              painter: _ArrowPainter(),
            ),
          ),
          Container(
            constraints: BoxConstraints(maxWidth: maxW > 320 ? 320 : maxW),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray100),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((title ?? '').isNotEmpty) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = AppColors.gray100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, fill);
    // 아래쪽(풍선 몸체와 닿는 변)은 선을 안 그어 자연스럽게 이어지게 함.
    canvas.drawLine(Offset(0, size.height), Offset(size.width / 2, 0), border);
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width, size.height), border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
