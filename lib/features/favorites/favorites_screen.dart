import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/language_provider.dart';
import '../home/widgets/job_card.dart';
import '../home/widgets/ad_banner.dart';
import '../../data/services/analytics_service.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/error_retry.dart';

enum FavoriteSortType { deadline, added }

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  FavoriteSortType _sortType = FavoriteSortType.added;
  bool _editMode = false;
  final Set<String> _selectedForDelete = {};
  bool _tracked = false;

  @override
  void initState() {
    super.initState();
    _loadSortType();
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
                            // 최상단 배너
                            if (index == 0) return const AdBanner();
                            // 3카드마다 배너
                            final jobIndex = _favJobIndex(index);
                            if (jobIndex < 0) return const AdBanner();
                            if (jobIndex >= jobs.length) return const SizedBox.shrink();
                            final job = jobs[jobIndex];
                            if (_editMode) {
                              final isChecked =
                                  _selectedForDelete.contains(job.id);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  isChecked
                                      ? _selectedForDelete.remove(job.id)
                                      : _selectedForDelete.add(job.id);
                                }),
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
                        color: AppColors.urgent,
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

  /// 배너 포함 총 아이템 수: 최상단 배너 + (3카드마다 배너)
  int _buildFavListItemCount(int jobCount) {
    if (jobCount == 0) return 1; // 최상단 배너만
    final adCount = (jobCount - 1) ~/ 3; // 3카드마다 1개 (첫 3개 후)
    return 1 + jobCount + adCount; // 최상단 배너 + 카드 + 중간 배너
  }

  /// index → 실제 job 인덱스 (-1이면 배너)
  int _favJobIndex(int index) {
    final adjustedIndex = index - 1; // 최상단 배너 제외
    final isAd = (adjustedIndex + 1) % 4 == 0 && adjustedIndex > 0;
    if (isAd) return -1;
    final adCount = adjustedIndex ~/ 4;
    return adjustedIndex - adCount;
  }

  void _showSortSheet(BuildContext context, dynamic s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(s.sortBy,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black)),
          ),
          _SortOption(
            label: s.sortByDeadline,
            isSelected: _sortType == FavoriteSortType.deadline,
            onTap: () {
              _setSortType(FavoriteSortType.deadline);
              Navigator.pop(context);
            },
          ),
          _SortOption(
            label: s.sortByAdded,
            isSelected: _sortType == FavoriteSortType.added,
            onTap: () {
              _setSortType(FavoriteSortType.added);
              Navigator.pop(context);
            },
          ),
          SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected ? AppColors.carrotLight : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.carrotDark : AppColors.black,
                )),
            if (isSelected)
              const Icon(Icons.check, size: 18, color: AppColors.carrot),
          ],
        ),
      ),
    );
  }
}
