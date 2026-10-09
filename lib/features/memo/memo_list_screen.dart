import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../core/utils/native_ad_controller.dart';
import '../../core/widgets/error_retry.dart';
import '../../core/widgets/offline_banner.dart';
import '../../data/models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../providers/job_memo_provider.dart';
import '../../providers/language_provider.dart';
import '../home/widgets/job_card.dart';
import '../home/widgets/native_ad_card.dart';
import 'memo_actions.dart';

/// 내 메모 — 메모 남긴 공고 모아보기 (홈 상단 진입, 로컬 저장, 2026-10-09).
/// 기존 공고 카드 그대로 + 메모 바 연필(수정)·휴지통(개별 즉시 삭제).
/// 정렬: 메모 수정일 최신/오래된순(칩+바텀시트, 즐겨찾기 패턴).
/// 최상단 네이티브 광고(즐겨찾기와 동일).
class MemoListScreen extends ConsumerStatefulWidget {
  const MemoListScreen({super.key});

  @override
  ConsumerState<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends ConsumerState<MemoListScreen> {
  bool _newestFirst = true;
  final _adController = NativeAdController();

  @override
  void dispose() {
    _adController.disposeAll();
    super.dispose();
  }

  void _showSortSheet(BuildContext context, dynamic s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            for (final (label, newest) in [
              (s.sortLatest as String, true),
              (s.sortOldest as String, false),
            ])
              ListTile(
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _newestFirst == newest
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _newestFirst == newest
                        ? AppColors.carrot
                        : AppColors.gray900,
                  ),
                ),
                trailing: _newestFirst == newest
                    ? const Icon(Icons.check, size: 20, color: AppColors.carrot)
                    : null,
                onTap: () {
                  setState(() => _newestFirst = newest);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);
    final memos = ref.watch(jobMemoProvider);

    // 메모 수정일 기준 정렬.
    final jobIds = memos.keys.toList()
      ..sort((a, b) => _newestFirst
          ? memos[b]!.updatedMs.compareTo(memos[a]!.updatedMs)
          : memos[a]!.updatedMs.compareTo(memos[b]!.updatedMs));

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
            // 정렬 칩 (즐겨찾기와 동일 스타일, 메모 수정일 기준)
            if (jobIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showSortSheet(context, s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _newestFirst ? s.sortLatest : s.sortOldest,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.gray600),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 16, color: AppColors.gray400),
                          ],
                        ),
                      ),
                    ),
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
                          return ErrorRetry(onRetry: () => setState(() {}));
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
                          // +1: 최상단 네이티브 광고(즐겨찾기와 동일).
                          itemCount: jobIds.length + 1,
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return NativeAdCard(
                                  controller: _adController, slot: -1);
                            }
                            final id = jobIds[i - 1];
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
