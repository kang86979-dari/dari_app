import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/apply_method_style.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../core/widgets/empty_placeholder.dart';
import '../../core/widgets/error_retry.dart';
import '../../core/widgets/sheet_handle.dart';
import '../../core/widgets/sort_sheet.dart';
import '../../providers/applied_job_provider.dart';
import '../../providers/job_note_provider.dart';
import '../home/widgets/mrec_ad_card.dart';
import '../../core/utils/mrec_ad_controller.dart';
import '../../core/constants/ad_config.dart';
import '../home/widgets/native_ad_card.dart';
import '../../core/utils/native_ad_controller.dart';
import 'widgets/account_app_bar.dart';
import 'widgets/job_memo_sheet.dart';

/// 지원 내역 — applied_jobs 실데이터(2026-09-26).
/// 카드 구성(사용자 확정): 제목(+미확인 N 뱃지) / 우상단 사이트뱃지+지원일 /
/// 회사명 / 📍주소 / 지원 방법 칩(같은 공고 복수 방법 묶음) / 하단 메모(좌) —
/// 마감·삭제(우). 카드 탭 → 공고 상세(마감이어도 열람, 실삭제 공고만 불가).
/// N 해소: 카드 탭 시 해당 공고, 화면 이탈 시 전체(markAllSeen).
class ApplyHistoryScreen extends ConsumerStatefulWidget {
  const ApplyHistoryScreen({super.key});

  @override
  ConsumerState<ApplyHistoryScreen> createState() =>
      _ApplyHistoryScreenState();
}

/// 같은 공고의 방법별 행들을 카드 1장으로 묶은 것.
class _AppliedGroup {
  final String? jobId;
  final List<AppliedJob> rows; // appliedAt desc

  _AppliedGroup(this.jobId, this.rows);

  AppliedJob get latest => rows.first;
  List<int> get ids => [for (final r in rows) r.id];
  List<String> get methods {
    final seen = <String>{};
    return [
      for (final r in rows)
        if (seen.add(r.method)) r.method,
    ];
  }

  bool get isNew => rows.any((r) => r.isNew);
  bool get expired => latest.expired;
}

class _ApplyHistoryScreenState extends ConsumerState<ApplyHistoryScreen> {
  bool _latestFirst = true;
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

  // 편집 모드(다중 선택 삭제) — 즐겨찾기와 동일 패턴(2026-09-26).
  bool _editMode = false;
  final Set<String> _selected = {};

  String _groupKey(_AppliedGroup g) => g.jobId ?? 'row-${g.latest.id}';

  /// 이 방문에서 "미확인"이던 행 id 스냅샷 — 서버는 목록을 연 순간 즉시 읽음
  /// 처리하고(홈·마이페이지 점 소멸), 화면의 점은 이 스냅샷으로 유지.
  /// dispose 시점의 일괄 처리가 실행되지 않는 문제를 피한 구조(2026-09-26).
  Set<int>? _newIdsSnapshot;

  void _captureAndMarkSeen(List<AppliedJob> rows) {
    if (_newIdsSnapshot != null) return; // 최초 로드 1회만
    _newIdsSnapshot = {
      for (final r in rows)
        if (r.isNew) r.id,
    };
    if (_newIdsSnapshot!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appliedJobActionsProvider).markAllSeen();
      });
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

  Future<void> _editMemo(_AppliedGroup group) async {
    final jobId = group.jobId;
    if (jobId == null) return; // 실삭제된 공고는 메모 불가
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
      jobTitle: group.latest.title,
      initialMemo: notes[jobId],
    );
    if (saved == null) return;
    try {
      await ref.read(jobNoteActionsProvider).save(jobId, saved);
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

  void _openDetail(_AppliedGroup group) {
    final jobId = group.jobId;
    if (jobId == null) return; // 공고 실삭제 — 스냅샷 카드만 유지
    // 상세 진입 = 해당 공고 점 즉시 해소(서버는 이미 읽음 처리됨).
    if (_newIdsSnapshot?.any(group.ids.contains) ?? false) {
      setState(() => _newIdsSnapshot!.removeAll(group.ids));
    }
    context.push('/job/$jobId');
  }

  List<_AppliedGroup> _group(List<AppliedJob> rows) {
    final map = <String, List<AppliedJob>>{};
    for (final r in rows) {
      // 실삭제 공고(jobId null)는 행별로 개별 카드.
      final key = r.jobId ?? 'row-${r.id}';
      map.putIfAbsent(key, () => []).add(r);
    }
    final groups = [
      for (final e in map.entries) _AppliedGroup(e.value.first.jobId, e.value),
    ];
    groups.sort(
      (a, b) => _latestFirst
          ? b.latest.appliedAt.compareTo(a.latest.appliedAt)
          : a.latest.appliedAt.compareTo(b.latest.appliedAt),
    );
    return groups;
  }

  // 편집 모드용 카드(동작 없는 표시 전용).
  Widget _buildCard(_AppliedGroup group, dynamic s) {
    final notes = ref.watch(jobNotesProvider).valueOrNull ?? const {};
    return _AppliedJobCard(
      group: group,
      isNew: _newIdsSnapshot?.any(group.ids.contains) ?? false,
      memo: group.jobId == null ? null : notes[group.jobId],
      methodLabelOf: (code) => s.applyMethodLabel(code) ?? code,
      methodLabelPrefix: s.applyHistoryMethodLabel,
      appliedDateLabel: s.applyHistoryAppliedDate,
      expiredLabel: s.expired,
      memoAddLabel: s.jobMemoAdd,
      onTap: () {},
      onMemoTap: null,
    );
  }

  Widget _empty(BuildContext context, dynamic s) {
    return EmptyPlaceholder(
      icon: Icons.fact_check_outlined,
      title: s.applyHistoryEmpty,
      subtitle: s.applyHistoryEmptyDesc,
      buttonLabel: s.emptyBrowseJobs,
      onButton: () => context.go('/home'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final async = ref.watch(appliedJobsProvider);
    final notes = ref.watch(jobNotesProvider).valueOrNull ?? const {};

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AccountAppBar(
              // 타이틀 (갯수) — 즐겨찾기와 동일 처리(2026-09-26).
              title: () {
                final rows = ref.watch(appliedJobsProvider).valueOrNull;
                if (rows == null) return s.myPageApplyHistory;
                final count = {
                  for (final r in rows) r.jobId ?? 'row-${r.id}',
                }.length;
                return '${s.myPageApplyHistory} ($count)';
              }(),
              // 편집 버튼 — 즐겨찾기와 동일하게 상단 바 오른쪽(2026-09-26).
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
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                // 에러를 "없어요"로 위장하지 않음 — 재시도 UI(2026-09-26 검토).
                error: (_, _) => ErrorRetry(
                  onRetry: () => ref.invalidate(appliedJobsProvider),
                ),
                data: (rows) {
                  if (rows.isEmpty) return _empty(context, s);
                  _captureAndMarkSeen(rows);
                  final groups = _group(rows);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                        // 정렬 칩 — 즐겨찾기와 동일한 위치(왼쪽)·스타일(2026-09-26).
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
                          itemCount: _listItemCount(groups.length),
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
                            final gIndex = cycle * n + pos;
                            if (gIndex >= groups.length) {
                              return const SizedBox.shrink();
                            }
                            final group = groups[gIndex];
                            if (_editMode) {
                              final key = _groupKey(group);
                              final checked = _selected.contains(key);
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    checked
                                        ? _selected.remove(key)
                                        : _selected.add(key);
                                  });
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 14),
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
                                    Expanded(
                                      child: IgnorePointer(
                                        child: _buildCard(group, s),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return _AppliedJobCard(
                              group: group,
                              isNew:
                                  _newIdsSnapshot?.any(group.ids.contains) ??
                                  false,
                              memo: group.jobId == null
                                  ? null
                                  : notes[group.jobId],
                              methodLabelOf: (code) =>
                                  s.applyMethodLabel(code) ?? code,
                              methodLabelPrefix: s.applyHistoryMethodLabel,
                              appliedDateLabel: s.applyHistoryAppliedDate,
                              expiredLabel: s.expired,
                              memoAddLabel: s.jobMemoAdd,
                              onTap: () => _openDetail(group),
                              onMemoTap: group.jobId == null
                                  ? null
                                  : () => _editMemo(group),
                              onDelete: group.expired
                                  ? () {
                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(appliedJobActionsProvider)
                                          .deleteRows(group.ids);
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                      // 편집 모드 하단 삭제 버튼 — 시그니처 색(즐겨찾기와 동일).
                      if (_editMode && _selected.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact(); // 삭제 실행
                              final ids = <int>[
                                for (final g in groups)
                                  if (_selected.contains(_groupKey(g)))
                                    ...g.ids,
                              ];
                              ref
                                  .read(appliedJobActionsProvider)
                                  .deleteRows(ids);
                              setState(() {
                                _selected.clear();
                                _editMode = false;
                              });
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
}

class _AppliedJobCard extends StatelessWidget {
  final _AppliedGroup group;
  final bool isNew;
  final String? memo;
  final String Function(String) methodLabelOf;
  final String methodLabelPrefix;
  final String appliedDateLabel;
  final String expiredLabel;
  final String memoAddLabel;
  final VoidCallback onTap;
  final VoidCallback? onMemoTap;
  final VoidCallback? onDelete;

  const _AppliedJobCard({
    required this.group,
    required this.isNew,
    required this.memo,
    required this.methodLabelOf,
    required this.methodLabelPrefix,
    required this.appliedDateLabel,
    required this.expiredLabel,
    required this.memoAddLabel,
    required this.onTap,
    required this.onMemoTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final item = group.latest;
    final expired = group.expired;
    final hasMemo = (memo ?? '').isNotEmpty;

    return GestureDetector(
      onTap: onTap,
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
                // 모집명 (+미확인 N 뱃지)
                Padding(
                  padding: const EdgeInsets.only(right: 85),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 미확인 표시 — 주황 점(2026-09-26 사용자 확정, N 글자 대신).
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(top: 6, right: 6),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.carrot,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: expired
                                ? AppColors.gray400
                                : AppColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),

                // 회사명 — 오른쪽은 추후 회사 평가 점수 자리(2026-09-26).
                Text(
                  item.company,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: expired ? AppColors.gray300 : AppColors.gray600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                // 주소 — 별도 행.
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
                          item.location,
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
                const SizedBox(height: 10),

                // 지원 방법 칩 (공용 스타일, 복수 방법 묶음)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          methodLabelPrefix,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray400,
                          ),
                        ),
                      ),
                      for (final method in group.methods)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _MethodTag(
                            icon: ApplyMethodStyle.of(method).icon,
                            label: methodLabelOf(method),
                            bgColor: expired
                                ? AppColors.gray50
                                : ApplyMethodStyle.of(method).bg,
                            textColor: expired
                                ? AppColors.gray300
                                : ApplyMethodStyle.of(method).fg,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 하단: 메모(좌) — 마감·삭제(우)를 침범하지 않음.
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF8F8F8))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onMemoTap,
                          child: hasMemo
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: expired
                                        ? AppColors.gray50
                                        : const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note,
                                        size: 14,
                                        color: expired
                                            ? AppColors.gray300
                                            : const Color(0xFF9A7B24),
                                      ),
                                      const SizedBox(width: 4),
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
                                    ],
                                  ),
                                )
                              : onMemoTap == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    memoAddLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB1953B),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (expired) ...[
                        const SizedBox(width: 10),
                        Text(
                          expiredLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                      if (onDelete != null) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // 우상단: 사이트 뱃지 + 지원일
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: expired
                          ? AppColors.gray50
                          : AppColors.carrotLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        item.siteName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: expired
                              ? AppColors.gray300
                              : AppColors.carrot,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$appliedDateLabel ${item.appliedAt.month}/${item.appliedAt.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: expired ? AppColors.gray300 : AppColors.gray400,
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

class _MethodTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _MethodTag({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
