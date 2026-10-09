import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../core/widgets/error_retry.dart';
import '../../core/widgets/offline_banner.dart';
import '../../data/models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../providers/job_memo_provider.dart';
import '../../providers/language_provider.dart';
import '../home/widgets/job_card.dart';
import 'memo_actions.dart';

/// 내 메모 — 메모 남긴 공고 모아보기 (홈 상단 진입, 로컬 저장, 2026-10-09).
/// 기존 공고 카드 그대로 + 메모 바 우측 휴지통으로 개별 즉시 삭제.
/// 최신 수정순 정렬.
class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);
    final memos = ref.watch(jobMemoProvider);

    // 최신 수정순 ID 목록.
    final jobIds = memos.keys.toList()
      ..sort((a, b) => memos[b]!.updatedMs.compareTo(memos[a]!.updatedMs));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            // 헤더 — 즐겨찾기 화면과 동일 구성 (타이틀+건수).
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${s.myMemosTitle} (${jobIds.length})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // 타이틀 중앙 유지용
                ],
              ),
            ),
            Expanded(
              child: jobIds.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_note,
                                size: 64, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 16),
                            Text(s.myMemosEmpty,
                                style: const TextStyle(
                                    fontSize: 16, color: AppColors.gray400)),
                            const SizedBox(height: 8),
                            Text(s.myMemosEmptyDesc,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: AppColors.gray300)),
                          ],
                        ),
                      ),
                    )
                  : FutureBuilder<List<Job>>(
                      // 즐겨찾기와 동일한 ID 묶음 조회 재사용(마감 포함).
                      future: JobRepository().getFavoriteJobs(jobIds),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return ErrorRetry(
                              onRetry: () => (context as Element)
                                  .markNeedsBuild());
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.carrot));
                        }
                        final byId = {
                          for (final j in snapshot.data!) j.id: j
                        };
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 20),
                          itemCount: jobIds.length,
                          itemBuilder: (context, i) {
                            final id = jobIds[i];
                            final job = byId[id];
                            if (job == null) return const SizedBox.shrink();
                            return JobCard(
                              job: job,
                              langCode: langCode,
                              alwaysOpen: s.alwaysOpen,
                              salaryFallback: s.salaryByCompany,
                              strings: s,
                              expiredLabel: s.expired,
                              memo: memos[id]?.text,
                              onMemoTap: () =>
                                  editJobMemo(context, ref, job, langCode),
                              onMemoDelete: () => ref
                                  .read(jobMemoProvider.notifier)
                                  .remove(id),
                              onTap: () => context.push('/job/${job.id}'),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
