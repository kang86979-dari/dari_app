import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 앱바 우측 텍스트 액션(수정하기 등) 공용 — 전 화면 통일(2026-10-11).
/// carrot · 15 · w500 (볼드 금지 — 타이틀보다 튀지 않게).
class AppBarTextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AppBarTextAction({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: AppColors.carrot),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}
