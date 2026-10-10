import 'package:flutter/material.dart';
import '../../providers/job_memo_provider.dart';
import '../memo/memo_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/language_provider.dart';
import '../home/widgets/job_card.dart';
import '../home/widgets/native_ad_card.dart';
import '../home/widgets/mrec_ad_card.dart';
import '../../core/constants/ad_config.dart';
import '../../core/utils/native_ad_controller.dart';
import '../../core/utils/mrec_ad_controller.dart';
import '../../data/services/analytics_service.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/error_retry.dart';
import '../../core/widgets/empty_placeholder.dart';
import '../../core/widgets/sort_sheet.dart';

enum FavoriteSortType { deadline, added }

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  FavoriteSortType _sortType = FavoriteSortType.added;
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
                  // 편집 버튼 삭제 — 하트 해제로 삭제 가능(2026-10-10).
                  // 타이틀 중앙 유지용 더미(뒤로가기와 대칭).
                  const SizedBox(width: 40),
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
                  ? EmptyPlaceholder(
                      icon: Icons.favorite_border,
                      title: s.noFavorites,
                      subtitle: s.noFavoritesHint,
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
                            return JobCard(
                              job: job,
                              langCode: langCode,
                              alwaysOpen: s.alwaysOpen,
                              salaryFallback: s.salaryByCompany,
                              strings: s,
                              expiredLabel: s.expired,
                              isFavorite: true,
                              memo: ref.watch(jobMemoTextProvider(job.id)),
                              memoAddLabel: s.jobMemoAdd,
                              onMemoTap: () =>
                                  editJobMemo(context, ref, job, langCode),
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

  void _showSortSheet(BuildContext context, dynamic s) {
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
