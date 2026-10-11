import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 앱 공통 토스트 — 기본 SnackBar가 투박하다는 피드백으로 교체(2026-10-11).
/// 하단 중앙 알약형(다크 ink 배경 + 흰 글자 + 선택 아이콘), 페이드+슬라이드업.
/// Overlay 기반이라 Scaffold 구조와 무관하게 어디서든 호출 가능.
///
/// 사용: showAppToast(context, '즐겨찾기에 추가했어요', icon: Icons.favorite);
void showAppToast(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration duration = const Duration(milliseconds: 1800),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);

  // 직전 토스트가 남아 있으면 제거(중복 쌓임 방지).
  _currentToast?.remove();
  _currentToast = null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _AppToast(
      message: message,
      icon: icon,
      duration: duration,
      onDismissed: () {
        if (_currentToast == entry) _currentToast = null;
        entry.remove();
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

OverlayEntry? _currentToast;

class _AppToast extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppToast({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottomInset + 56,
      child: IgnorePointer(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            // Overlay에는 Material 조상이 없어 Text에 노란 밑줄이 생김 —
            // Material(transparent)로 감싸 기본 텍스트 스타일 보장(2026-10-11).
            child: Material(
              type: MaterialType.transparency,
              child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E14161B),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 16, color: AppColors.carrot),
                      const SizedBox(width: 7),
                    ],
                    // 긴 번역(독일어 등)은 2줄까지 — 알약이 세로로 늘어남.
                    Flexible(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
