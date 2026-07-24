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
        case SalaryType.companyRule:
          return s.salaryByCompany;
        case SalaryType.negotiable:
          return s.salaryNegotiable;
        default:
          break;
      }
    }
    return job.salary ?? salaryFallback;
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

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: expired ? 0.5 : 1.0,
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
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
                  color: AppColors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),

            // 회사명
            Text(
              job.company ?? '',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            // 주소
            if (job.getShortLocation(langCode).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
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
                          bgColor: AppColors.tagBlue,
                          textColor: AppColors.tagBlueTxt,
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
                        bgColor: AppColors.navyLight,
                        textColor: AppColors.navy,
                      ),
                    ),
                  if (job.getJobType(langCode).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Tag(
                        label: job.getJobType(langCode),
                        bgColor: AppColors.gray50,
                        textColor: AppColors.gray600,
                      ),
                    ),
                  if (job.getEmploymentType(langCode).isNotEmpty)
                    _Tag(
                      label: job.getEmploymentType(langCode),
                      bgColor: AppColors.tagGreen,
                      textColor: AppColors.tagGreenTxt,
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
                      color: expired ? const Color(0xFFE53935) : AppColors.gray300,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _displaySalary(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.carrot,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
                ),
              ),
          ],
        ),
            // 사이트 뱃지 (카드 기준 오른쪽 상단, 세로 정렬)
            Positioned(
              top: 0,
              right: 0,
              child: _SiteBadge(name: job.siteName ?? job.siteId),
            ),
          ],
        ),
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
