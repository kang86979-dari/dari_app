import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final String langCode;
  final String alwaysOpen;
  final String salaryFallback;
  final AppStrings? strings;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  final String? expiredLabel;

  /// 이 공고에 남긴 내 메모 — 있으면 카드 하단에 한 줄 미리보기(노랑 바) 표시.
  /// 모든 리스트(홈·검색·즐겨찾기) 공통. job_notes 서버 연동 시 값이 채워짐.
  final String? memo;

  /// 메모 영역 탭(수정/작성) 콜백 — 즐겨찾기처럼 카드에서 바로 메모를 다루는
  /// 화면만 전달. null이면 미리보기 전용(홈·검색).
  final VoidCallback? onMemoTap;

  /// "+ 메모 남기기" 문구 — 전달된 화면에서만 메모 없을 때 작성 버튼 노출.
  final String? memoAddLabel;

  /// 이 공고에 지원했는지 — true면 우상단 사이트 뱃지 아래 "✓ 지원함" 초록 칩.
  final bool applied;

  /// "지원함" 라벨 (다국어).
  final String? appliedLabel;

  /// 메모 바 우측 휴지통(즉시 삭제) — 메모 리스트 전용(2.1.6 머지).
  final VoidCallback? onMemoDelete;

  const JobCard({
    super.key,
    required this.job,
    required this.langCode,
    this.alwaysOpen = '상시',
    this.salaryFallback = '회사 내규',
    this.strings,
    this.isFavorite = false,
    required this.onTap,
    this.onFavoriteToggle,
    this.expiredLabel,
    this.memo,
    this.onMemoTap,
    this.memoAddLabel,
    this.applied = false,
    this.appliedLabel,
    this.onMemoDelete,
  });

  // CJK는 제목이 짧아 16 유지, 번역 언어는 텍스트가 길어져 축소 (2줄 내 표시)
  static double _titleFontSize(String langCode) {
    const cjk = {'ko', 'ja', 'zh', 'zh-yue'};
    return cjk.contains(langCode) ? 16.0 : 14.5;
  }

  String _displaySalary() {
    final s = strings;
    if (s != null && job.salaryAmount != null && job.salaryTypeRaw != null) {
      return s.formatSalary(job.salaryTypeRaw!, job.salaryAmount!);
    }
    if (s != null) {
      switch (job.salaryType) {
        case SalaryType.negotiable:
          return s.salaryNegotiable;
        default:
          // 파싱 불가 원문(예: 제목이 salary에 들어온 오염 데이터)을 그대로
          // 노출하지 않도록 상세 화면과 동일하게 회사내규로 폴백(2026-10-10).
          return s.salaryByCompany;
      }
    }
    return salaryFallback;
  }

  static String _formatDeadline(String? expiresAt, String alwaysOpen) {
    if (expiresAt == null) return alwaysOpen;
    final date = DateTime.tryParse(expiresAt);
    if (date == null) return alwaysOpen;
    return '~${date.month}/${date.day}';
  }

  bool get _isExpired {
    if (expiredLabel == null || job.expiresAt == null) return false;
    final date = DateTime.tryParse(job.expiresAt!);
    if (date == null) return false;
    return date.isBefore(DateUtils.dateOnly(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final expired = _isExpired;

    // 마감 표현: 반투명 대신 요소별 회색 처리 — 지원 내역과 톤 통일(2026-09-26).
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // 테두리 한 단계 진하게 — 카드 구분이 또렷하게(2026-10-09).
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모집명 (오른쪽 여백으로 뱃지 공간 확보)
            Padding(
              padding: const EdgeInsets.only(right: 85),
              child: Text(
                job.getTitle(langCode),
                style: TextStyle(
                  fontSize: _titleFontSize(langCode),
                  fontWeight: FontWeight.w600,
                  color: expired ? AppColors.gray400 : AppColors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),

            // 회사명 — 오른쪽은 추후 회사 평가 점수 자리로 비워둠(2026-09-26).
            // 없으면 '비공개' placeholder(옅은 회색).
            Text(
              job.getDisplayCompany(langCode).isNotEmpty
                  ? job.getDisplayCompany(langCode)
                  : (strings?.companyUndisclosed ?? 'Undisclosed'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: expired
                    ? AppColors.gray300
                    : job.getDisplayCompany(langCode).isNotEmpty
                    ? AppColors.gray600
                    : AppColors.gray400,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            // 주소 — 위치 핀 포함 별도 행.
            if (job.getShortLocation(langCode).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 12,
                      color: AppColors.gray300,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        job.getShortLocation(langCode),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray300,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // 비자 태그 + 직종 + 고용형태 (한 줄)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...job.visas.take(2).map((v) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _Tag(
                          label: v.code == 'ANY' ? (strings?.visaGroupAny ?? 'Any visa') : v.code,
                          bgColor:
                              expired ? AppColors.gray50 : AppColors.tagBlue,
                          textColor: expired
                              ? AppColors.gray300
                              : AppColors.tagBlueTxt,
                        ),
                      )),
                  if (job.visas.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Tag(
                        label: '+${job.visas.length - 2}',
                        bgColor: AppColors.gray50,
                        textColor: AppColors.gray600,
                      ),
                    ),
                  if (job.housingProvided == true)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Tag(
                        label: strings?.housingChip ?? 'Housing',
                        bgColor:
                            expired ? AppColors.gray50 : AppColors.navyLight,
                        textColor:
                            expired ? AppColors.gray300 : AppColors.navy,
                      ),
                    ),
                  if (job.getJobType(langCode).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Tag(
                        label: job.getJobType(langCode),
                        bgColor: AppColors.gray50,
                        textColor:
                            expired ? AppColors.gray300 : AppColors.gray600,
                      ),
                    ),
                  if (job.getEmploymentType(langCode).isNotEmpty)
                    _Tag(
                      label: job.getEmploymentType(langCode),
                      bgColor: expired ? AppColors.gray50 : AppColors.tagGreen,
                      textColor:
                          expired ? AppColors.gray300 : AppColors.tagGreenTxt,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // D-day + 급여
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF8F8F8))),
              ),
              child: Row(
                children: [
                  if (onFavoriteToggle != null) ...[
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFavorite ? AppColors.carrot : AppColors.gray200,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    expired ? expiredLabel! : _formatDeadline(job.expiresAt, alwaysOpen),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          expired ? FontWeight.w600 : FontWeight.w400,
                      color: expired ? AppColors.gray400 : AppColors.gray300,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _displaySalary(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: expired ? AppColors.gray300 : AppColors.carrot,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
                ),
              ),

            // 내 메모 미리보기 — 노랑 포스트잇 톤(feature와 동일, 2026-10-09).
            if (memo != null && memo!.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMemoTap,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  // 아이콘 유무와 무관하게 "+ 메모 남기기" 바와 같은 높이 유지.
                  constraints: const BoxConstraints(minHeight: 26),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: expired ? AppColors.gray50 : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      // 연필 — 메모 앞쪽, 탭하면 수정 가능함을 알림(2026-10-09).
                      if (onMemoTap != null)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.edit_outlined,
                              size: 14, color: Color(0xFF9A7B24)),
                        ),
                      Expanded(
                        child: Text(
                          memo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: expired
                                ? AppColors.gray300
                                : const Color(0xFF6D5B1F),
                          ),
                        ),
                      ),
                      if (onMemoDelete != null)
                        GestureDetector(
                          onTap: onMemoDelete,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.delete_outline,
                                size: 16, color: Color(0xFF9A7B24)),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            // 메모 없음: "+ 메모 남기기" — 작성 진입(모든 카드 공통).
            // 메모 있는 바와 구분: 배경 없이 노랑 계열 텍스트만(2026-10-10).
            else if (onMemoTap != null && memoAddLabel != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMemoTap,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  // 메모 바(아이콘 포함)와 동일 높이(2026-10-09).
                  constraints: const BoxConstraints(minHeight: 26),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    memoAddLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      // 배경 없는 상태에서 노랑끼가 보이도록 골든 옐로(2026-10-10).
                      color: Color(0xFFC9A227),
                    ),
                  ),
                ),
              ),
          ],
        ),
            // 사이트 뱃지 + "✓ 지원함" 칩 (카드 오른쪽 상단, 세로 정렬)
            // 사이트명 없으면(예: RLS로 숨겨진 testing 사이트) 뱃지 생략 — UUID 노출 방지
            if ((job.siteName != null && job.siteName!.isNotEmpty) ||
                (applied && appliedLabel != null))
              Positioned(
                top: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (job.siteName != null && job.siteName!.isNotEmpty)
                      _SiteBadge(name: job.siteName!),
                    if (applied && appliedLabel != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tagGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 11,
                              color: AppColors.tagGreenTxt,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              appliedLabel!,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tagGreenTxt,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SiteBadge extends StatelessWidget {
  final String name;
  const _SiteBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 80),
        child: Text(name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.gray400)),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _Tag({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
    );
  }
}
