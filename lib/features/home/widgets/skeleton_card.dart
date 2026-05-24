import 'package:flutter/material.dart';

class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bone(width: 180, height: 18),
                _bone(width: 70, height: 24, radius: 6),
              ],
            ),
            const SizedBox(height: 10),
            _bone(width: 140, height: 14),
            const SizedBox(height: 10),
            Row(
              children: [
                _bone(width: 50, height: 24, radius: 10),
                const SizedBox(width: 6),
                _bone(width: 60, height: 24, radius: 10),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF8F8F8))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _bone(width: 40, height: 14),
                  _bone(width: 80, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bone({required double width, required double height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
