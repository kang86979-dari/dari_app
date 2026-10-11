import 'package:flutter/material.dart';
import 'colors.dart';

/// 지원방법 코드별 공통 스타일(아이콘·배경색·전경색) — 단일 정의(2026-09-26).
/// 공고 상세 지원방법 칩 / 지원하기 바텀시트 / 지원 내역 카드가 모두 이걸
/// 참조해서 화면 간 색·아이콘이 어긋나지 않게 함.
///
/// 색 배정(새 디자인 역할색, 2026-10-11): 온라인 지원 계열
/// (online/homepage/simple)+전화 = teal(정보·링크), 메시지·이메일
/// (sms/chat/email) = navy, 방문/기타 = gray. 주황은 브랜드 주행동 전용이라 제외.
class ApplyMethodStyle {
  final IconData icon;
  final Color bg;
  final Color fg;

  const ApplyMethodStyle(this.icon, this.bg, this.fg);

  static const ApplyMethodStyle _fallback = ApplyMethodStyle(
    Icons.more_horiz,
    AppColors.gray50,
    AppColors.gray600,
  );

  static const Map<String, ApplyMethodStyle> _byCode = {
    'online': ApplyMethodStyle(
      Icons.computer_outlined,
      AppColors.tealLight,
      AppColors.teal,
    ),
    'homepage': ApplyMethodStyle(
      Icons.language,
      AppColors.tealLight,
      AppColors.teal,
    ),
    'simple': ApplyMethodStyle(
      Icons.flash_on,
      AppColors.tealLight,
      AppColors.teal,
    ),
    'phone': ApplyMethodStyle(
      Icons.phone_outlined,
      AppColors.tealLight,
      AppColors.teal,
    ),
    'sms': ApplyMethodStyle(
      Icons.sms_outlined,
      AppColors.navyLight,
      AppColors.navy,
    ),
    'chat': ApplyMethodStyle(
      Icons.chat_bubble_outline,
      AppColors.navyLight,
      AppColors.navy,
    ),
    'email': ApplyMethodStyle(
      Icons.email_outlined,
      AppColors.navyLight,
      AppColors.navy,
    ),
    'visit': ApplyMethodStyle(
      Icons.place_outlined,
      AppColors.gray50,
      AppColors.gray600,
    ),
    'other': _fallback,
  };

  static ApplyMethodStyle of(String code) => _byCode[code] ?? _fallback;
}
