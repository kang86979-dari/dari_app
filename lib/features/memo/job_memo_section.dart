import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../providers/job_memo_provider.dart';
import 'memo_actions.dart';

/// 공고 상세 메모 섹션 — 로컬 저장(2026-10-09).
/// feature 브랜치 _JobMemoSection과 동일 디자인: 제목·아이콘 없이
/// 있으면 노랑 박스에 전문, 없으면 가운데 정렬 "+ 메모 남기기" 바.
class JobMemoSection extends ConsumerWidget {
  final Job job;
  final String langCode;
  const JobMemoSection({super.key, required this.job, required this.langCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final memo = ref.watch(jobMemoTextProvider(job.id));
    final hasMemo = memo != null && memo.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => editJobMemo(context, ref, job, langCode),
      child: hasMemo
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              // 메모 있을 때 — 제목·아이콘 없이 내용만(2026-10-05 확정).
              child: Text(
                memo,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF6D5B1F),
                ),
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              // 메모 없음 — "+ 메모 남기기"(문자열에 + 포함, 아이콘 없음).
              alignment: Alignment.center,
              child: Text(
                s.jobMemoAdd,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A7B24),
                ),
              ),
            ),
    );
  }
}
