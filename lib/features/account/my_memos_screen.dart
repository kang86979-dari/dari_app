import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../core/utils/native_ad_controller.dart';
import '../../core/widgets/empty_placeholder.dart';
import '../../core/widgets/error_retry.dart';
import '../../core/widgets/sort_sheet.dart';
import '../../data/models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../providers/applied_job_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/job_note_provider.dart';
import '../../providers/language_provider.dart';
import '../home/widgets/job_card.dart';
import '../home/widgets/mrec_ad_card.dart';
import '../../core/utils/mrec_ad_controller.dart';
import '../../core/constants/ad_config.dart';
import '../home/widgets/native_ad_card.dart';
import 'widgets/account_app_bar.dart';
import 'widgets/job_memo_sheet.dart';

/// 내 메모 — 메모를 남긴 공고 모아보기(2026-09-26, 마이페이지 마지막 메뉴).
/// 상단 구성은 즐겨찾기·지원 내역과 통일(사용자 확정): 타이틀 바 오른쪽 편집,
/// 왼쪽 회색 칩 정렬(메모 수정일 최신/오래된순), 리스트 최상단 네이티브 광고.
/// 카드는 홈과 동일(JobCard): 탭=상세, 하트 토글, 메모 노랑 바 탭=수정.
final _memoJobsProvider = FutureProvider<List<Job>>((ref) async {
  final notes = await ref.watch(jobNotesProvider.future);
  if (notes.isEmpty) return const [];
  return JobRepository().getFavoriteJobs(notes.keys.toList());
});

/// 메모 수정일 (job_id → updated_at) — 정렬용.
final _memoTimesProvider = FutureProvider<Map<String, DateTime>>((ref) async {
  ref.watch(authStateProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const {};
  ref.watch(jobNotesProvider); // 메모 변경 시 함께 갱신
  final rows = await Supabase.instance.client
      .from('job_notes')
      .select('job_id, updated_at')
      .eq('user_id', user.id);
  return {
    for (final r in rows)
      r['job_id'] as String: DateTime.parse(r['updated_at'] as String),
  };
});

class MyMemosScreen extends ConsumerStatefulWidget {
  const MyMemosScreen({super.key});

  @override
  ConsumerState<MyMemosScreen> createState() => _MyMemosScreenState();
}

class _MyMemosScreenState extends ConsumerState<MyMemosScreen> {
  bool _latestFirst = true;
  bool _editMode = false;
  final Set<String> _selected = {};
  final _adController = NativeAdController();
  final _mrecController = MrecAdController();

  @override
  void dispose() {
    _adController.disposeAll();
    _mrecController.disposeAll();
    super.dispose();
  }

  /// 광고 포함 총 아이템 수 — 즐겨찾기와 동일 규칙(최상단+매 N카드).
  int _listItemCount(int count) {
    if (count == 0) return 1;
    return 1 + count + count ~/ AdConfig.listAdInterval;
  }

  Future<void> _editMemo(Job job, String langCode) async {
    final s = ref.read(stringsProvider);
    // 조회 실패 시 무반응 방지(2026-09-26 검토).
    final Map<String, String> notes;
    try {
      notes = await ref.read(jobNotesProvider.future);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.accountSaveFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.accountSaveFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSortSheet() {
    final s = ref.read(stringsProvider);
    // 즐겨찾기와 동일한 공용 정렬 시트(2026-09-26).
    showSortOptionsSheet(
      context,
      title: s.sortBy,
      options: [
        SortSheetOption(
          label: s.sortLatest,
          selected: _latestFirst,
          onSelect: () => setState(() => _latestFirst = true),
        ),
        SortSheetOption(
          label: s.sortOldest,
          selected: !_latestFirst,
          onSelect: () => setState(() => _latestFirst = false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);
    final notes = ref.watch(jobNotesProvider).valueOrNull ?? const {};
    final times = ref.watch(_memoTimesProvider).valueOrNull ?? const {};
    final jobsAsync = ref.watch(_memoJobsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AccountAppBar(
              // 타이틀 (갯수) — 즐겨찾기와 동일 처리(2026-09-26).
              title: jobsAsync.valueOrNull == null
                  ? s.myPageMemos
                  : '${s.myPageMemos} (${jobsAsync.valueOrNull!.length})',
              // 편집 — 즐겨찾기·지원 내역과 동일 위치(2026-09-26).
              trailing: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() {
                  _editMode = !_editMode;
                  _selected.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  height: 44,
                  alignment: Alignment.center,
                  child: Text(
                    _editMode ? s.done : s.edit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _editMode ? AppColors.carrot : AppColors.gray600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: jobsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                // 에러를 "없어요"로 위장하지 않음 — 재시도 UI(2026-09-26 검토).
                error: (_, _) => ErrorRetry(
                  onRetry: () => ref.invalidate(jobNotesProvider),
                ),
                data: (jobs) {
                  if (jobs.isEmpty) return _empty(context, s);
                  // 메모 수정일 기준 정렬 (시간 정보 없으면 뒤로).
                  final sorted = [...jobs]..sort((a, b) {
                    final ta =
                        times[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final tb =
                        times[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return _latestFirst ? tb.compareTo(ta) : ta.compareTo(tb);
                  });
                  return Column(
                    children: [
                      // 정렬 칩 — 즐겨찾기와 동일 위치·스타일.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _showSortSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _latestFirst
                                          ? s.sortLatest
                                          : s.sortOldest,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.gray600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: AppColors.gray400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                            top: 4,
                            bottom: _editMode ? 90 : 24,
                          ),
                          itemCount: _listItemCount(sorted.length),
                          itemBuilder: (context, index) {
                            // 광고 규칙 — 즐겨찾기·홈과 동일: 최상단 네이티브 +
                            // 매 N카드마다 광고(짝수 주기 MREC/홀수 네이티브).
                            const n = AdConfig.listAdInterval;
                            if (index == 0) {
                              return NativeAdCard(
                                controller: _adController,
                                slot: -1,
                              );
                            }
                            final a = index - 1;
                            final cycle = a ~/ (n + 1);
                            final pos = a % (n + 1);
                            if (pos == n) {
                              return cycle.isEven
                                  ? MrecAdCard(
                                      controller: _mrecController,
                                      slot: cycle,
                                    )
                                  : NativeAdCard(
                                      controller: _adController,
                                      slot: cycle,
                                    );
                            }
                            final jIndex = cycle * n + pos;
                            if (jIndex >= sorted.length) {
                              return const SizedBox.shrink();
                            }
                            final job = sorted[jIndex];
                            final card = JobCard(
                              job: job,
                              langCode: langCode,
                              alwaysOpen: s.alwaysOpen,
                              salaryFallback: s.salaryByCompany,
                              strings: s,
                              expiredLabel: s.expired,
                              isFavorite:
                                  ref.watch(isFavoriteProvider(job.id)),
                              applied: ref
                                  .watch(appliedJobIdsProvider)
                                  .contains(job.id),
                              appliedLabel: s.jobAppliedChip,
                              memo: notes[job.id],
                              memoAddLabel: s.jobMemoAdd,
                              onMemoTap: () => _editMemo(job, langCode),
                              onFavoriteToggle: () => ref
                                  .read(favoriteProvider.notifier)
                                  .toggle(job.id),
                              onTap: () => context.push('/job/${job.id}'),
                            );
                            if (!_editMode) return card;
                            final checked = _selected.contains(job.id);
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  checked
                                      ? _selected.remove(job.id)
                                      : _selected.add(job.id);
                                });
                              },
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Icon(
                                      checked
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: 22,
                                      color: checked
                                          ? AppColors.carrot
                                          : AppColors.gray200,
                                    ),
                                  ),
                                  Expanded(child: IgnorePointer(child: card)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // 편집 모드 하단 삭제 — 선택한 공고의 메모 삭제.
                      if (_editMode && _selected.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.mediumImpact(); // 삭제 실행
                              final ids = _selected.toList();
                              setState(() {
                                _selected.clear();
                                _editMode = false;
                              });
                              try {
                                await ref
                                    .read(jobNoteActionsProvider)
                                    .deleteMany(ids);
                              } catch (_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(s.accountSaveFailed),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: AppColors.carrot,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${s.delete} (${_selected.length})',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, dynamic s) {
    return EmptyPlaceholder(
      icon: Icons.edit_note,
      title: s.myMemosEmpty,
      subtitle: s.myMemosEmptyDesc,
      buttonLabel: s.emptyBrowseJobs,
      onButton: () => context.go('/home'),
    );
  }
}
