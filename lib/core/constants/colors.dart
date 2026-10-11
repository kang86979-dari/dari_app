import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color carrot = Color(0xFFFF6F0F);
  static const Color carrotLight = Color(0xFFFFF3EB);
  static const Color carrotDark = Color(0xFFE55A00);

  static const Color black = Color(0xFF1A1A1A);
  static const Color gray900 = Color(0xFF333333);
  static const Color gray600 = Color(0xFF555555);
  static const Color gray500 = Color(0xFF666666);
  static const Color gray400 = Color(0xFF888888);
  static const Color gray300 = Color(0xFFAAAAAA);
  static const Color gray200 = Color(0xFFCCCCCC);
  static const Color gray100 = Color(0xFFE0E0E0);
  static const Color gray50 = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFFFFFFF);

  static const Color tagBlue = Color(0xFFE3F2FD);
  static const Color tagBlueTxt = Color(0xFF1565C0);
  static const Color tagGreen = Color(0xFFE8F5E9);
  static const Color tagGreenTxt = Color(0xFF2E7D32);
  // 지원방법(이메일) 전용 — 주황은 브랜드 색이라 방법 칩에 안 씀(2026-09-26).
  static const Color tagPurple = Color(0xFFF3E8FD);
  static const Color tagPurpleTxt = Color(0xFF7B1FA2);
  static const Color urgent = Color(0xFFE53935);

  static const Color navy = Color(0xFF003478);
  static const Color navyLight = Color(0xFFE8EEF7);
  static const Color navyDark = Color(0xFF002255);

  // ── 새 디자인(v2) 토큰 — 색 역할 분리로 "온통 주황" 해소 ──
  // 보조색(Teal): 정보·링크·선택 상태. carrot은 "지금 누를 것"에만.
  static const Color teal = Color(0xFF0E7C66);
  static const Color tealLight = Color(0xFFE6F2EF);
  // 섹션 배경(Sand, 아이보리) + 테두리(Line)
  static const Color sand = Color(0xFFFAF7F2);
  static const Color line = Color(0xFFECE9E4);
  // 메모(Gold)
  static const Color gold = Color(0xFFC9A227);
  static const Color goldBg = Color(0xFFFFF8E1);
  static const Color goldInk = Color(0xFF9A7B24);
}
