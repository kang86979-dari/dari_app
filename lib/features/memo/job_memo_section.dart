import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../providers/job_memo_provider.dart';
import 'memo_actions.dart';

/// 공고 상세 메모 섹션 — 로컬 저장(2026-10-09).
/// 있으면 노랑 박스에 전문(탭=수정), 없으면 "+ 메모 남기기"
/// (카드 메모 바와 동일한 노랑 톤으로 통일).
class JobMemoSection extends ConsumerWidget {
  final Job job;
  final String langCode;
  const JobMemoSection({super.key, required this.job, required this.langCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final memo = ref.watch(jobMemoTextProvider(job.id));
    final hasMemo = memo != null && memo.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, size: 18, color: AppColors.gray600),
              const SizedBox(width: 4),
              Text(
                s.jobMemoTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => editJobMemo(context, ref, job, langCode),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hasMemo ? memo : s.jobMemoAdd,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: hasMemo ? FontWeight.w500 : FontWeight.w600,
                  color: hasMemo
                      ? const Color(0xFF6D5B1F)
                      : const Color(0xFF9A7B24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
