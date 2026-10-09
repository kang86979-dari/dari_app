import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// 공용 확인 팝업 (앱 전체 yes/no 확인의 단일 모듈, 2026-10-05 모듈화).
///
/// 위계: 질문(타이틀, 제일 크게) → [선택] 회색 박스(보조 정보) → [선택] 안내(14)
/// → [취소(outlined) | 확인(채움 버튼)]. 확인=true, 취소/닫기=false/null.
/// [destructive]=true면 확인 버튼이 빨강(urgent) — 탈퇴 등 파괴적 동작용.
///
/// 로그아웃·회원탈퇴·지원 확인 등 모든 확인 팝업이 이 함수를 쓴다.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String question,
  String? desc,
  String? boxTitle, // 회색 박스 상단(예: 회사명/로그인 수단). null이면 박스 없음.
  String? boxSubtitle, // 회색 박스 둘째 줄(예: 공고명/이메일).
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
  bool barrierDismissible = false,
}) {
  final confirmColor = destructive ? AppColors.urgent : AppColors.carrot;
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dctx) => AlertDialog(
      // M3 seed(carrot) surfaceTint로 카드가 연주황으로 물드는 것 방지 → 순백.
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      // 안내문과 버튼 사이 간격 확보(2026-10-05).
      actionsPadding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.black,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (boxTitle != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  // 흰 카드 위에서 정보 박스를 연주황으로 강조(2026-10-05).
                  color: AppColors.carrotLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boxTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    if ((boxSubtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        boxSubtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if ((desc ?? '').isNotEmpty) const SizedBox(height: 12),
            ],
            if ((desc ?? '').isNotEmpty)
              Text(
                desc!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.gray600,
                ),
              ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray500,
                    side: const BorderSide(color: AppColors.gray100),
                    // 기본 세로 패딩/탭타깃이 46px 안에서 한글 글자를 눌러
                    // 세로로 잘리던 문제 → 패딩 제거+탭타깃 축소(2026-10-05).
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(cancelLabel,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(confirmLabel,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// 지원 확인 팝업 (전화/문자/채팅/홈페이지 공용) — [showConfirmDialog]의 래퍼.
/// 회사·공고를 회색 박스로 보여준다. '네'=true, '아니요'/닫기=false/null.
Future<bool?> showApplyConfirmDialog(
  BuildContext context, {
  required String company,
  required String title,
  required String question,
  required String desc,
  required String yesLabel,
  required String noLabel,
}) {
  return showConfirmDialog(
    context,
    question: question,
    desc: desc,
    boxTitle: company,
    boxSubtitle: title,
    confirmLabel: yesLabel,
    cancelLabel: noLabel,
  );
}
