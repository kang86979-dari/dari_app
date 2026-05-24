// =============================================================================
// Dari 온보딩 다리 일러스트 (A3 - 두 아치 + 중간 Dari)
// =============================================================================
//
// 사용법:
//   1. flutter_svg 패키지가 있다면 SVG 버전 사용 가능
//      dependencies:
//        flutter_svg: ^2.0.10
//
//   2. 이 파일(bridge_illustration.dart)을 lib/features/onboarding/widgets/ 에 복사
//
//   3. 온보딩 페이지에서:
//        import 'widgets/bridge_illustration.dart';
//        ...
//        const BridgeIllustration(animated: true)   // 애니메이션
//        const BridgeIllustration()                  // 정적
//
// =============================================================================

import 'package:flutter/material.dart';

/// Dari 온보딩용 다리 일러스트.
///
/// 외국인(오렌지) → Dari(중간) → 한국 직장(네이비) 의 연결을
/// 두 개의 아치로 표현합니다.
///
/// [animated] 가 true 면 좌측 아치 → 중간 점 → 우측 아치 순서로 그려집니다.
class BridgeIllustration extends StatefulWidget {
  const BridgeIllustration({
    super.key,
    this.animated = false,
    this.size = const Size(340, 180),
    this.duration = const Duration(milliseconds: 1800),
  });

  final bool animated;
  final Size size;
  final Duration duration;

  @override
  State<BridgeIllustration> createState() => _BridgeIllustrationState();
}

class _BridgeIllustrationState extends State<BridgeIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: widget.size,
          painter: _BridgePainter(progress: _controller.value),
        );
      },
    );
  }
}

class _BridgePainter extends CustomPainter {
  _BridgePainter({required this.progress});

  final double progress;

  // 브랜드 색상
  static const _orange = Color(0xFFFF6F0F);
  static const _midOrange = Color(0xFFFFAA5C);
  static const _navy = Color(0xFF003478);
  static const _cream = Color(0xFFFFFAF5);
  static const _groundLine = Color(0xFFE8DED0);

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 340 x 180 기준으로 설계됨 → 스케일 자동 조정
    final sx = size.width / 340;
    final sy = size.height / 180;

    // 좌표 변환 헬퍼
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    double r(double v) => v * ((sx + sy) / 2);

    // ----- 1. 바닥선 (fade in 0 ~ 0.15) -----
    final groundOpacity = _stageOpacity(progress, 0.0, 0.15);
    if (groundOpacity > 0) {
      final groundPaint = Paint()
        ..color = _groundLine.withValues(alpha: groundOpacity)
        ..strokeWidth = 1 * sy;
      canvas.drawLine(p(30, 135), p(310, 135), groundPaint);
    }

    // ----- 2. 좌측 아치 (0.1 ~ 0.5) -----
    final leftArchT = _stageProgress(progress, 0.1, 0.5);
    if (leftArchT > 0) {
      _drawArch(
        canvas,
        start: p(45, 135),
        control: p(107, 75),
        end: p(170, 135),
        progress: leftArchT,
        color: _orange,
        strokeWidth: 6 * sy,
      );
    }

    // ----- 3. 좌측 anchor (외국인) 0.0 ~ 0.2 -----
    final leftAnchorOpacity = _stageOpacity(progress, 0.0, 0.2);
    if (leftAnchorOpacity > 0) {
      _drawAnchor(canvas, p(45, 135), r(12), r(5), _orange, leftAnchorOpacity);
    }

    // ----- 4. 중간 anchor (Dari) 0.45 ~ 0.6 -----
    final midAnchorOpacity = _stageOpacity(progress, 0.45, 0.6);
    if (midAnchorOpacity > 0) {
      _drawAnchor(canvas, p(170, 135), r(12), r(5), _midOrange, midAnchorOpacity);
    }

    // ----- 5. 우측 아치 (0.55 ~ 0.95) -----
    final rightArchT = _stageProgress(progress, 0.55, 0.95);
    if (rightArchT > 0) {
      _drawArch(
        canvas,
        start: p(170, 135),
        control: p(232, 75),
        end: p(295, 135),
        progress: rightArchT,
        color: _navy,
        strokeWidth: 6 * sy,
      );
    }

    // ----- 6. 우측 anchor (한국 직장) 0.9 ~ 1.0 -----
    final rightAnchorOpacity = _stageOpacity(progress, 0.9, 1.0);
    if (rightAnchorOpacity > 0) {
      _drawAnchor(canvas, p(295, 135), r(12), r(5), _navy, rightAnchorOpacity);
    }
  }

  // 앵커 (외곽 원 + 안쪽 흰 점) 그리기
  void _drawAnchor(
    Canvas canvas,
    Offset center,
    double outerR,
    double innerR,
    Color color,
    double opacity,
  ) {
    final outer = Paint()..color = color.withValues(alpha: opacity);
    final inner = Paint()..color = _cream.withValues(alpha: opacity);
    canvas.drawCircle(center, outerR, outer);
    canvas.drawCircle(center, innerR, inner);
  }

  // 이차 베지어 아치를 progress (0..1) 비율만큼 그리기
  void _drawArch(
    Canvas canvas, {
    required Offset start,
    required Offset control,
    required Offset end,
    required double progress,
    required Color color,
    required double strokeWidth,
  }) {
    final path = Path()..moveTo(start.dx, start.dy);
    // progress 구간까지 샘플링해서 quadraticBezierTo 대신 lineTo 로 점진 그림
    const steps = 40;
    final last = (steps * progress).round().clamp(1, steps);
    for (int i = 1; i <= last; i++) {
      final t = i / steps;
      final x = _quad(start.dx, control.dx, end.dx, t);
      final y = _quad(start.dy, control.dy, end.dy, t);
      path.lineTo(x, y);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  // 이차 베지어 좌표
  double _quad(double p0, double p1, double p2, double t) {
    final u = 1 - t;
    return u * u * p0 + 2 * u * t * p1 + t * t * p2;
  }

  // 전체 progress 에서 특정 구간 [from, to] 의 진행도 (0..1)
  double _stageProgress(double p, double from, double to) {
    if (p <= from) return 0;
    if (p >= to) return 1;
    return (p - from) / (to - from);
  }

  // 전체 progress 에서 특정 구간 [from, to] 의 opacity (0..1)
  double _stageOpacity(double p, double from, double to) =>
      _stageProgress(p, from, to);

  @override
  bool shouldRepaint(covariant _BridgePainter old) => old.progress != progress;
}
