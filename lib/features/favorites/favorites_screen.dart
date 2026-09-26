import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/job_note_provider.dart';
import '../account/widgets/job_memo_sheet.dart';
import '../account/login_signup_sheet.dart';
import '../../providers/account_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/language_provider.dart';
import '../home/widgets/job_card.dart';
import '../home/widgets/native_ad_card.dart';
import '../home/widgets/mrec_ad_card.dart';
import '../../core/constants/ad_config.dart';
import '../../core/utils/native_ad_controller.dart';
import '../../core/utils/mrec_ad_controller.dart';
import '../../data/services/analytics_service.dart';
import '../../core/widgets/sort_sheet.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/error_retry.dart';

enum FavoriteSortType { deadline, added }

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  /// 카드에서 메모 작성/수정 — 비로그인도 진입점은 항상 보이고, 탭 시 로그인
  /// 유도 후 이어서 작성(상세 화면과 동일 패턴, 2026-09-26).
  Future<void> _editMemo(Job job, {bool resumedAfterLogin = false}) async {
    final loggedIn = await ref.read(accountProvider.notifier).ensureLoaded();
    if (!mounted) return;
    if (!loggedIn) {
      showLoginSignupSheet(
        context,
        onLoggedIn: () => _editMemo(job, resumedAfterLogin: true),
      );
      return;
    }
    final s = ref.read(stringsProvider);
    final langCode = ref.read(languageProvider);
    // 로그인 직후엔 프로바이더가 재로드 중일 수 있어 완료를 기다려 최신값 사용.
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
    final current = notes[job.id];
    // 로그인 복귀 시 기존 메모가 있으면 팝업 없이 카드의 노랑 바로 표시만.
    if (resumedAfterLogin && (current ?? '').isNotEmpty) return;
    final saved = await showJobMemoSheet(
      context,
      strings: s,
      jobTitle: job.getTitle(langCode),
      initialMemo: current,
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

  FavoriteSortType _sortType = FavoriteSortType.added;
  bool _editMode = false;
  final Set<String> _selectedForDelete = {};
  bool _tracked = false;
  final _adController = NativeAdController();
  final _mrecController = MrecAdController();

  @override
  void initState() {
    super.initState();
    _loadSortType();
  }

  @override
  void dispose() {
    _adController.disposeAll();
    _mrecController.disposeAll();
    super.dispose();
  }

  Future<void> _loadSortType() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('favorite_sort');
    if (saved == 'deadline' && mounted) {
      setState(() => _sortType = FavoriteSortType.deadline);
    }
  }

  Future<void> _setSortType(FavoriteSortType type) async {
    final sortName = type == FavoriteSortType.deadline ? 'deadline' : 'added';
    analytics.favoritesSortChanged(sortName);
    setState(() => _sortType = type);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_sort', sortName);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);
    final favorites = ref.watch(favoriteProvider);

    if (!_tracked) {
      _tracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        analytics.favoritesOpened(favorites.length);
      });
    }
    final jobIds = favorites.map((f) => f.jobId).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            // 헤더
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
                      width: 40, height: 40,
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${s.favorites} (${favorites.length})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _editMode = !_editMode;
                      _selectedForDelete.clear();
                    }),
                    child: Text(
                      _editMode ? s.done : s.edit,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _editMode ? AppColors.carrot : AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 정렬 선택
            if (favorites.isNotEmpty)
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
                              _sortType == FavoriteSortType.deadline
                                  ? s.sortByDeadline
                                  : s.sortByAdded,
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

            // 목록
            Expanded(
              child: jobIds.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_border,
                                size: 64, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 16),
                            Text(s.noFavorites,
                                style: const TextStyle(
                                    fontSize: 16, color: AppColors.gray400)),
                            const SizedBox(height: 8),
                            Text(s.noFavoritesHint,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.gray300)),
                          ],
                        ),
                      ),
                    )
                  : FutureBuilder<List<Job>>(
                      future: JobRepository().getFavoriteJobs(jobIds),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return ErrorRetry(
                            onRetry: () => setState(() {}),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.carrot));
                        }

                        var jobs = snapshot.data!;
                        // 정렬
                        if (_sortType == FavoriteSortType.deadline) {
                          jobs.sort((a, b) {
                            final aDate = a.expiresAt ?? '9999-12-31';
                            final bDate = b.expiresAt ?? '9999-12-31';
                            return aDate.compareTo(bDate);
                          });
                        } else {
                          // 등록순 (favorites 리스트 순서 유지)
                          final orderMap = <String, int>{};
                          for (var i = 0; i < favorites.length; i++) {
                            orderMap[favorites[i].jobId] = i;
                          }
                          jobs.sort((a, b) =>
                              (orderMap[b.id] ?? 0)
                                  .compareTo(orderMap[a.id] ?? 0));
                        }

                        // 배너 삽입 위치 계산: 0번(최상단) + 매 3카드마다
                        final itemCount = _buildFavListItemCount(jobs.length);

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            const n = AdConfig.listAdInterval;
                            // 최상단도 네이티브. slot -1로 인-리스트 슬롯과 키 분리.
                            if (index == 0) {
                              return NativeAdCard(
                                  controller: _adController, slot: -1);
                            }
                            final a = index - 1;
                            final cycle = a ~/ (n + 1); // (공고 N개 + 광고 1개) 단위
                            final pos = a % (n + 1);
                            // 각 주기 마지막 = 광고 슬롯 (cycle 짝수=MREC, 홀수=small)
                            if (pos == n) {
                              return cycle.isEven
                                  ? MrecAdCard(
                                      controller: _mrecController, slot: cycle)
                                  : NativeAdCard(
                                      controller: _adController, slot: cycle);
                            }
                            final jobIndex = cycle * n + pos;
                            if (jobIndex >= jobs.length) return const SizedBox.shrink();
                            final job = jobs[jobIndex];
                            if (_editMode) {
                              final isChecked =
                                  _selectedForDelete.contains(job.id);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    isChecked
                                        ? _selectedForDelete.remove(job.id)
                                        : _selectedForDelete.add(job.id);
                                  });
                                },
                                child: Container(
                                  color: isChecked
                                      ? AppColors.carrotLight
                                      : Colors.transparent,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 16),
                                        child: Icon(
                                          isChecked
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: isChecked
                                              ? AppColors.carrot
                                              : AppColors.gray200,
                                          size: 22,
                                        ),
                                      ),
                                      Expanded(
                                        child: IgnorePointer(
                                          child: JobCard(
                                            job: job,
                                            langCode: langCode,
                                            alwaysOpen: s.alwaysOpen,
                                            salaryFallback: s.salaryByCompany,
                                            strings: s,
                                            expiredLabel: s.expired,
                                            memo: ref
                                                .watch(jobNotesProvider)
                                                .valueOrNull?[job.id],
                                            onTap: () {},
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return JobCard(
                              job: job,
                              langCode: langCode,
                              alwaysOpen: s.alwaysOpen,
                              salaryFallback: s.salaryByCompany,
                              strings: s,
                              expiredLabel: s.expired,
                              isFavorite: true,
                              memo: ref.watch(jobNotesProvider).valueOrNull?[job.id],
                              memoAddLabel: s.jobMemoAdd,
                              onMemoTap: () => _editMemo(job),
                              onTap: () => context.push('/job/${job.id}'),
                              onFavoriteToggle: () {
                                analytics.favoriteRemoved(job.id);
                                ref
                                    .read(favoriteProvider.notifier)
                                    .toggle(job.id);
                              },
                            );
                          },
                        );
                      },
                    ),
            ),

            // 편집 모드 하단 삭제 버튼
            if (_editMode && _selectedForDelete.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact(); // 삭제 실행
                      analytics.favoritesBulkDelete(_selectedForDelete.length);
                      ref
                          .read(favoriteProvider.notifier)
                          .removeMultiple(_selectedForDelete);
                      setState(() {
                        _selectedForDelete.clear();
                        _editMode = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        // 시그니처 색으로 변경(2026-09-26 사용자 확정).
                        color: AppColors.carrot,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${s.delete} (${_selectedForDelete.length})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 광고 포함 총 아이템 수: 최상단 배너 + 공고 + (공고 N개마다 네이티브 광고)
  int _buildFavListItemCount(int jobCount) {
    if (jobCount == 0) return 1; // 최상단 배너만
    final adCount = jobCount ~/ AdConfig.listAdInterval;
    return 1 + jobCount + adCount;
  }

  void _showSortSheet(BuildContext context, AppStrings s) {
    // 공용 정렬 시트(핸들+X 포함) — 지원 내역·내 메모와 동일(2026-09-26).
    showSortOptionsSheet(
      context,
      title: s.sortBy,
      options: [
        SortSheetOption(
          label: s.sortByDeadline,
          selected: _sortType == FavoriteSortType.deadline,
          onSelect: () => _setSortType(FavoriteSortType.deadline),
        ),
        SortSheetOption(
          label: s.sortByAdded,
          selected: _sortType == FavoriteSortType.added,
          onSelect: () => _setSortType(FavoriteSortType.added),
        ),
      ],
    );
  }
}
