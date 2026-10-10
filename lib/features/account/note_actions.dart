import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../providers/job_note_provider.dart';
import 'widgets/job_memo_sheet.dart';

/// 카드의 메모 바/"+ 메모 남기기" 탭 → 서버 메모(job_notes) 작성·수정.
/// 2.1.6의 카드 메모 UX를 서버 저장으로 이식(2026-10-10 머지).
/// my_memos_screen·favorites_screen과 동일 패턴 — 시트 저장 시 서버 반영.
Future<void> editJobNote(
  BuildContext context,
  WidgetRef ref,
  Job job,
  String langCode,
) async {
  final s = ref.read(stringsProvider);
  final notes = ref.read(jobNotesProvider).valueOrNull ?? const {};
  final saved = await showJobMemoSheet(
    context,
    strings: s,
    jobTitle: job.getTitle(langCode),
    initialMemo: notes[job.id],
  );
  if (saved == null) return;
  try {
    await ref.read(jobNoteActionsProvider).save(job.id, saved);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.accountSaveFailed),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
