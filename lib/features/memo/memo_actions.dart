import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../providers/job_memo_provider.dart';
import 'job_memo_sheet.dart';

/// 메모 작성/수정 공통 진입점 — 카드·상세·메모 목록 공용(2026-10-09).
/// 시트 반환: 저장 시 trim 텍스트('' = 삭제), 닫으면 null.
Future<void> editJobMemo(
  BuildContext context,
  WidgetRef ref,
  Job job,
  String langCode,
) async {
  final s = ref.read(stringsProvider);
  final existing = ref.read(jobMemoProvider)[job.id]?.text;
  final result = await showJobMemoSheet(
    context,
    strings: s,
    jobTitle: job.getTitle(langCode),
    initialMemo: existing,
  );
  if (result == null) return;
  await ref.read(jobMemoProvider.notifier).set(
        job.id,
        result,
        title: job.getTitle(langCode),
        company: job.getDisplayCompany(langCode),
      );
}
