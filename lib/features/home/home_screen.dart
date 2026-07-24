import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../data/models/job.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/filter_state.dart';
import '../../providers/job_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/utils/ad_helper.dart';
import '../../core/utils/region_mapper.dart';
import '../../core/utils/district_names.dart';
import '../../data/repositories/job_repository.dart';
import 'widgets/job_card.dart';
import 'widgets/skeleton_card.dart';
import 'widgets/ad_banner.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/notice_service.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/error_retry.dart';
import '../../data/services/app_open_ad_service.dart';
import '../../data/services/push_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  bool _showFab = false;
  final List<Job> _jobs = [];
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialLoaded = false;
  FilterState? _lastFilter;
  String? _lastLangCode;
  int _filterGeneration = 0;
  bool _isRefreshing = false;
  bool _showFilterTooltip = false;
  bool _pendingAppOpenAd = false;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFilterTooltip();
    _checkNotice();
    // 전국 등 삭제된 region ID 정리
    ref.read(filterStateProvider.notifier).cleanupInvalidRegionIds();
    // analytics를 지연시켜 DB 동시 요청 줄임
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) analytics.screenView('home');
    });
    _scrollController.addListener(_onScroll);
    // 앱 시작 시 푸시 구독 동기화 (기존 사용자 업데이트 대응)
    _syncPushSubscription();
  }

  Future<void> _syncPushSubscription() async {
    // 이미 동기화된 적 있으면 스킵 (기존 사용자 업데이트 시 1회만)
    if (await pushService.isSynced()) return;
    // init 완료 대기 (권한 팝업 + 토큰 발급)
    await pushService.waitForInit();
    if (!mounted) return;
    if (pushService.token == null) return;
    final enabled = await pushService.isEnabled();
    if (!enabled) return;
    final filter = ref.read(filterStateProvider);
    if (filter.isEmpty) return;
    final langCode = ref.read(languageProvider);
    await pushService.upsertSubscription(filter: filter, langCode: langCode);
    await pushService.markSynced();
  }

  Future<void> _checkFilterTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('filter_tooltip_dismissed') ?? false;
    if (!dismissed && mounted) {
      setState(() => _showFilterTooltip = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showFilterTooltip) _dismissFilterTooltip();
      });
    }
  }

  Future<void> _checkNotice() async {
    // 약간 지연시켜 홈 화면 로드 후 표시
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final langCode = ref.read(languageProvider);
    final notice = await noticeService.getActiveNotice();
    if (notice != null && mounted) {
      _showNoticeDialog(notice, langCode);
    }
  }

  void _showNoticeDialog(Notice notice, String langCode) {
    bool dontShowAgain = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            notice.getTitle(langCode),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.getContent(langCode),
                style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.gray400),
              ),
              if (!notice.isOnce) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setDialogState(() => dontShowAgain = !dontShowAgain),
                  child: Row(
                    children: [
                      Icon(
                        dontShowAgain ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 20,
                        color: dontShowAgain ? AppColors.carrot : AppColors.gray300,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        langCode == 'ko' ? '다시 보지 않기' : "Don't show again",
                        style: const TextStyle(fontSize: 13, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Column(
              children: [
                // update: 스토어 이동 / event: URL 이동
                if (notice.isUpdate || notice.isEvent)
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        if (notice.isOnce || dontShowAgain) {
                          noticeService.dismissNotice(notice.id);
                        }
                        Navigator.pop(ctx);
                        final url = notice.isUpdate
                            ? 'https://play.google.com/store/apps/details?id=com.dariwork.app'
                            : notice.actionUrl;
                        if (url != null && url.isNotEmpty) {
                          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.carrot,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notice.isUpdate
                              ? (langCode == 'ko' ? '업데이트' : 'Update')
                              : (langCode == 'ko' ? '바로가기' : 'Go'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                if (notice.isUpdate || notice.isEvent)
                  const SizedBox(height: 8),
                // 닫기 버튼 (모든 타입)
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      if (notice.isOnce || dontShowAgain) {
                        noticeService.dismissNotice(notice.id);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: notice.isNotice ? AppColors.carrot : AppColors.gray100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        langCode == 'ko' ? '닫기' : 'Close',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: notice.isNotice ? Colors.white : AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dismissFilterTooltip() async {
    setState(() => _showFilterTooltip = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filter_tooltip_dismissed', true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 광고 클릭 후 복귀: 리스트 위치 유지 (갱신/앱오픈광고 스킵)
      if (AdHelper.consumeAdClicked()) {
        if (kDebugMode) print('🔵 resumed: ad click return, skip refresh');
        return;
      }
      JobRepository.clearCountCache();
      final isCurrent = ModalRoute.of(context)?.isCurrent == true;
      if (kDebugMode) print('🔵 resumed: isCurrent=$isCurrent');
      // 홈 화면이 최상단이면 갱신 + 광고
      if (isCurrent) {
        _forceRefresh();
        appOpenAdService.showIfAvailable();
      } else {
        _pendingAppOpenAd = true;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 740;
    if (show != _showFab) setState(() => _showFab = show);

    // 무한 스크롤: 하단 200px 전에 다음 페이지 로드
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final gen = _filterGeneration;

    try {
      final repo = ref.read(jobRepositoryProvider);
      final filter = ref.read(filterStateProvider);
      final langCode = ref.read(languageProvider);
      final newJobs = await repo.getJobs(filter: filter, page: _currentPage + 1, langCode: langCode);
      if (!mounted || gen != _filterGeneration) return;
      analytics.scrollDepth(_currentPage + 1);
      analytics.pageLoaded(_currentPage + 1);
      setState(() {
        _currentPage++;
        _jobs.addAll(newJobs);
        _hasMore = newJobs.length >= 20;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || gen != _filterGeneration) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _forceRefresh() async {
    await _doRefresh();
  }

  Future<void> _onRefresh() async {
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inSeconds < 30) {
      return;
    }
    _lastRefreshTime = now;
    await _doRefresh();
  }

  Future<void> _doRefresh() async {
    final gen = ++_filterGeneration;
    JobRepository.clearCountCache();
    setState(() => _isRefreshing = true);

    try {
      final repo = ref.read(jobRepositoryProvider);
      final filter = ref.read(filterStateProvider);
      final langCode = ref.read(languageProvider);
      final newJobs = await repo.getJobs(filter: filter, page: 0, langCode: langCode);
      if (!mounted || gen != _filterGeneration) return;
      setState(() {
        _jobs.clear();
        _jobs.addAll(newJobs);
        _currentPage = 0;
        _hasMore = newJobs.length >= 20;
        _isLoadingMore = false;
        _isRefreshing = false;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
      ref.invalidate(jobTotalCountProvider);
    } catch (e) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _resetAndLoad(List<Job> initialJobs) {
    _jobs.clear();
    _jobs.addAll(initialJobs);
    _currentPage = 0;
    _hasMore = initialJobs.length >= 20;
    _isLoadingMore = false;
    _initialLoaded = true;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }


  void _showLanguageSheet(
    BuildContext context,
    String currentLang,
    LanguageNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LanguageBottomSheet(
        currentLang: currentLang,
        title: ref.read(stringsProvider).changeLanguage,
        onSelect: (code) {
          analytics.languageChanged(currentLang, code);
          notifier.setLanguage(code);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(stringsProvider).languageChanged),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobListProvider(0));
    final filter = ref.watch(filterStateProvider);
    final langCode = ref.watch(languageProvider);

    // 필터 또는 언어 변경 시 리셋
    if ((_lastFilter != null && _lastFilter != filter) ||
        (_lastLangCode != null && _lastLangCode != langCode)) {
      _initialLoaded = false;
      _filterGeneration++;
      // 홈에서 필터 칩 삭제 시 서버 구독 업데이트
      if (_lastFilter != null && _lastFilter != filter) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (filter.isEmpty) {
            pushService.deleteSubscription();
          } else {
            pushService.upsertSubscription(filter: filter, langCode: langCode);
          }
        });
      }
    }
    _lastFilter = filter;
    _lastLangCode = langCode;
    final langNotifier = ref.read(languageProvider.notifier);
    final s = ref.watch(stringsProvider);

    // 다른 화면에서 홈으로 돌아왔을 때 대기 중인 앱 오픈 광고 표시
    if (_pendingAppOpenAd && ModalRoute.of(context)?.isCurrent == true) {
      _pendingAppOpenAd = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appOpenAdService.showIfAvailable();
      });
    }

    return Stack(
      children: [
      Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/wordmark.png',
                    height: 22,
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/favorites'),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: AppColors.carrotLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  ref.watch(favoriteProvider).isNotEmpty
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 21,
                                  color: AppColors.carrot,
                                ),
                              ),
                              if (ref.watch(favoriteProvider).isNotEmpty)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.carrot,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '${ref.watch(favoriteProvider).length}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.carrot,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: Image.asset(
                          'assets/settings_icon.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 검색/필터 영역 + 목록
            // 검색바(및 필터 없을 때 필터 바로가기 바 / 필터 있을 때 필터 버튼)는
            // 스크롤 시 함께 올라가고, 결과 행(+선택 필터 칩)은 상단 고정.
            Expanded(
              child: RefreshIndicator(
                color: AppColors.carrot,
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  key: ValueKey(langCode),
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    // 스크롤되는 검색 영역
                    SliverToBoxAdapter(
                      child: filter.isEmpty
                          ? Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                  child: _searchGrayBox(s),
                                ),
                                _filterShortcutBar(s),
                              ],
                            )
                          : _searchWithFilterButton(s, filter),
                    ),
                    // 고정 영역 (결과 행 / 필터 있을 땐 선택 칩 포함)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedHeaderDelegate(
                        // 결과 행은 글꼴 확대 시 커지므로 textScaler 반영 (칩 38 고정)
                        height: (filter.isEmpty ? 0.0 : 38.0)
                            + MediaQuery.textScalerOf(context).scale(20) + 14,
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              if (!filter.isEmpty)
                                _ReadOnlyFilterChips(filter: filter, ref: ref),
                              _resultRow(s),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 공고 목록
                    ..._buildListSlivers(jobsAsync, langCode),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              mini: true,
              shape: const CircleBorder(),
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              ),
              child: const Icon(Icons.arrow_upward, size: 20),
            )
          : null,
    ),
      ],
    );
  }

  // 검색바 회색 박스 (필터 유무 공통)
  Widget _searchGrayBox(dynamic s) {
    return GestureDetector(
      onTap: () {
        analytics.searchBarTap();
        context.push('/search');
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: AppColors.gray300),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.searchHint,
                style: const TextStyle(fontSize: 14, color: AppColors.gray300),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 필터 미설정 시: 검색바 아래 필터 바로가기 바
  Widget _filterShortcutBar(dynamic s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: _FilterPulse(
        enabled: true,
        child: GestureDetector(
          onTap: () => context.push('/filter'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.carrot,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 고정 요소 너비: icon(15) + gaps(8+8+6+6) + container padding 제외(LayoutBuilder 안이라 이미 제외)
                // "Filter:" 텍스트 너비 추정: fontSize 13 * 0.6 per char
                // 칩 너비 추정: padding(16) + fontSize 12 * 0.65 per char
                const chipPad = 16.0;
                const charW = 7.8; // 평균 글자 너비 (라틴+CJK 혼합)
                const fixedW = 15 + 8 + 8 + 6 + 6; // icon + gaps
                final filterLabelW = (s.filter as String).length * 6.5 + 4; // "Filter:" + ":"
                final baseChipsW = chipPad + s.tabVisa.length * charW  // VISA
                    + 6 + chipPad + s.tabRegion.length * charW          // Region
                    + 6 + chipPad + s.filterMore.length * charW;        // + More
                final salaryChipW = 6 + chipPad + s.tabSalary.length * charW;
                final baseTotal = fixedW + filterLabelW + baseChipsW;
                final showSalary = (baseTotal + salaryChipW) <= constraints.maxWidth;

                return Row(
                  children: [
                    const Icon(Icons.tune, size: 15, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text('${s.filter}:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70)),
                    const SizedBox(width: 8),
                    _FilterShortcutChip(label: s.tabVisa, onTap: () => context.push('/filter?tab=0')),
                    const SizedBox(width: 6),
                    _FilterShortcutChip(label: s.tabRegion, onTap: () => context.push('/filter?tab=3')),
                    if (showSalary) ...[
                      const SizedBox(width: 6),
                      _FilterShortcutChip(label: s.tabSalary, onTap: () => context.push('/filter?tab=4')),
                    ],
                    const SizedBox(width: 6),
                    _FilterShortcutChip(label: s.filterMore, onTap: () => context.push('/filter')),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // 필터 설정 시: 검색바 + 필터 버튼 나란히
  Widget _searchWithFilterButton(dynamic s, FilterState filter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Expanded(child: _searchGrayBox(s)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push('/filter'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.carrotDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(s.filter,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_adjustedActiveCount(filter)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.carrot),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 결과 행 (Total 건수 + 알바만 체크)
  Widget _resultRow(dynamic s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          _TotalCount(s: s),
          const Spacer(),
          _PartTimeCheckbox(s: s),
        ],
      ),
    );
  }

  // 목록 영역 슬리버 (상태별)
  List<Widget> _buildListSlivers(AsyncValue<List<Job>> jobsAsync, String langCode) {
    if (_isRefreshing) return _skeletonSlivers();
    return jobsAsync.when(
      data: (jobs) => _jobListSlivers(jobs, langCode),
      loading: () => _skeletonSlivers(),
      error: (e, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorRetry(
            onRetry: () => ref.invalidate(jobListProvider(0)),
          ),
        ),
      ],
    );
  }

  List<Widget> _skeletonSlivers() {
    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            backgroundColor: const Color(0xFFF0F0F0),
            valueColor: const AlwaysStoppedAnimation(AppColors.carrot),
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: Column(
          children: [
            SkeletonCard(),
            SkeletonCard(),
            SkeletonCard(),
          ],
        ),
      ),
    ];
  }

  List<Widget> _jobListSlivers(List<Job> initialJobs, String langCode) {
    // 초기 로드 시 리셋
    if (!_initialLoaded) {
      _resetAndLoad(initialJobs);
    }

    if (_jobs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              ref.read(stringsProvider).noJobs,
              style: const TextStyle(fontSize: 16, color: AppColors.gray400),
            ),
          ),
        ),
      ];
    }

    final totalItems = _jobs.length + (_jobs.length ~/ 3) + 1 + (_isLoadingMore ? 1 : 0);

    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // 로딩 인디케이터 (마지막)
              if (_isLoadingMore && index == totalItems - 1) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.carrot)),
                );
              }

              if (index == 0) return const AdBanner();

              final adjustedIndex = index - 1;
              final isAd = (adjustedIndex + 1) % 4 == 0 && adjustedIndex > 0;

              if (isAd) return const AdBanner();

              final adCount = adjustedIndex ~/ 4;
              final jobIndex = adjustedIndex - adCount;
              if (jobIndex >= _jobs.length) return const SizedBox.shrink();

              final job = _jobs[jobIndex];
              return JobCard(
                job: job,
                langCode: langCode,
                alwaysOpen: ref.read(stringsProvider).alwaysOpen,
                salaryFallback: ref.read(stringsProvider).salaryByCompany,
                strings: ref.read(stringsProvider),
                isFavorite: ref.watch(isFavoriteProvider(job.id)),
                onTap: () {
                  analytics.jobCardTap(job.id, jobIndex);
                  context.push('/job/${job.id}');
                },
                onFavoriteToggle: () {
                  final isFav = ref.read(isFavoriteProvider(job.id));
                  if (isFav) {
                    analytics.favoriteRemoved(job.id);
                  } else {
                    analytics.favoriteAdded(job.id, 'home');
                  }
                  ref.read(favoriteProvider.notifier).toggle(job.id);
                  final s = ref.read(stringsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isFav ? s.favoriteRemovedMsg : s.favoriteAddedMsg),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              );
            },
            childCount: totalItems,
          ),
        ),
      ),
    ];
  }
}

class _LanguageBottomSheet extends ConsumerWidget {
  final String currentLang;
  final String title;
  final void Function(String code) onSelect;

  const _LanguageBottomSheet({
    required this.currentLang,
    required this.title,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(supportedLanguagesProvider);
    final languages = languagesAsync.valueOrNull ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 14, bottom: 4),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  '×',
                  style: TextStyle(fontSize: 24, color: Color(0xFFBBBBBB)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = lang.code == currentLang;
              return GestureDetector(
                onTap: () => onSelect(lang.code),
                child: Container(
                  color: isSelected ? AppColors.carrotLight : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.carrot : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.carrot : const Color(0xFFDDDDDD),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


class _TotalCount extends ConsumerWidget {
  final dynamic s;
  const _TotalCount({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(jobTotalCountProvider);
    final langCode = ref.watch(languageProvider);
    return countAsync.when(
      data: (count) => count < 0
          ? const SizedBox.shrink()
          : RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.gray400),
                children: [
                  TextSpan(text: s.totalPrefix),
                  TextSpan(
                    text: NumberFormat.decimalPattern(langCode).format(count),
                    style: const TextStyle(
                      color: AppColors.carrot,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: s.totalSuffix),
                ],
              ),
            ),
      loading: () => Text(
        s.loading,
        style: const TextStyle(fontSize: 14, color: AppColors.gray400),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

const _partTimeEmploymentId = 'c5bde521-d267-4e6f-a997-e67ede1b0c3f';

class _PartTimeCheckbox extends ConsumerWidget {
  final dynamic s;
  const _PartTimeCheckbox({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterStateProvider);
    final isChecked = filter.employmentTypeIds.contains(_partTimeEmploymentId);
    final notifier = ref.read(filterStateProvider.notifier);

    return GestureDetector(
      onTap: () {
        analytics.partTimeToggle(!isChecked);
        notifier.toggleEmploymentType(_partTimeEmploymentId);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: isChecked,
              onChanged: (_) {
                analytics.partTimeToggle(!isChecked);
                notifier.toggleEmploymentType(_partTimeEmploymentId);
              },
              activeColor: AppColors.carrot,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: AppColors.gray300, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            s.onlyPartTime,
            style: TextStyle(
              fontSize: 13,
              color: isChecked ? AppColors.carrot : AppColors.gray400,
              fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

int _adjustedActiveCount(FilterState filter) {
  var count = filter.activeCount;
  if (filter.regionIds.isNotEmpty) {
    final allRegions = JobRepository.allRegionsCacheSync;
    if (allRegions != null) {
      final siDoGroups = <String, List<int>>{};
      final siDoTotals = <String, int>{};
      final siDoHasGuGun = <String, bool>{};
      for (final r in allRegions) {
        final si = r['si_name'] as String;
        if (r['gu_name'] != null) {
          siDoTotals[si] = (siDoTotals[si] ?? 0) + 1;
          siDoHasGuGun[si] = true;
        } else {
          siDoHasGuGun.putIfAbsent(si, () => false);
        }
      }
      for (final id in filter.regionIds) {
        final r = allRegions.where((e) => e['id'] == id).firstOrNull;
        if (r != null) {
          final si = r['si_name'] as String;
          if (r['gu_name'] != null || !(siDoHasGuGun[si] ?? false)) {
            siDoGroups.putIfAbsent(si, () => []).add(id);
          }
        }
      }
      int regionChipCount = 0;
      for (final entry in siDoGroups.entries) {
        final hasGuGun = siDoHasGuGun[entry.key] ?? false;
        final total = hasGuGun ? (siDoTotals[entry.key] ?? 0) : entry.value.length;
        regionChipCount += entry.value.length >= total ? 1 : entry.value.length;
      }
      count = count - filter.regionIds.length + regionChipCount;
    }
  }
  return count;
}

class _FilterChipData {
  final String label;
  final VoidCallback onRemove;
  const _FilterChipData(this.label, this.onRemove);
}

class _ReadOnlyFilterChips extends StatelessWidget {
  final FilterState filter;
  final WidgetRef ref;

  const _ReadOnlyFilterChips({required this.filter, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(filterStateProvider.notifier);
    final chips = <_FilterChipData>[];

    // 비자 (선택된 경우만 옵션 로드)
    if (filter.visaIds.isNotEmpty) {
      final visaOpts = ref.watch(visaOptionsProvider).valueOrNull ?? [];
      for (final id in filter.visaIds) {
        final opt = visaOpts.where((o) => o.id == id).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('visa', opt.label);
          notifier.toggleVisa(id);
        }));
      }
    }
    // 직종
    if (filter.categoryIds.isNotEmpty) {
      final catOpts = ref.watch(categoryOptionsProvider).valueOrNull ?? [];
      for (final id in filter.categoryIds) {
        final opt = catOpts.where((o) => o.id == id).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('category', opt.label);
          notifier.toggleCategory(id);
        }));
      }
    }
    // 지역: 시/도 전체면 시/도명, 구/군 개별이면 구/군별 칩
    if (filter.regionIds.isNotEmpty) {
      // 캐시가 아직 없으면 로드 트리거 (앱 재시작 시)
      ref.watch(siDoOptionsProvider);
      final allRegions = JobRepository.allRegionsCacheSync;
      final lang = ref.watch(languageProvider);
      if (allRegions != null) {
        final siDoGroups = <String, List<int>>{};
        final siDoTotals = <String, int>{};
        final siDoHasGuGun = <String, bool>{};
        for (final r in allRegions) {
          final si = r['si_name'] as String;
          if (r['gu_name'] != null) {
            siDoTotals[si] = (siDoTotals[si] ?? 0) + 1;
            siDoHasGuGun[si] = true;
          } else {
            siDoHasGuGun.putIfAbsent(si, () => false);
          }
        }
        for (final id in filter.regionIds) {
          final r = allRegions.where((e) => e['id'] == id).firstOrNull;
          if (r != null) {
            final si = r['si_name'] as String;
            if (r['gu_name'] != null || !(siDoHasGuGun[si] ?? false)) {
              siDoGroups.putIfAbsent(si, () => []).add(id);
            }
          }
        }
        for (final entry in siDoGroups.entries) {
          final si = entry.key;
          final ids = entry.value;
          final hasGuGun = siDoHasGuGun[si] ?? false;
          final total = hasGuGun ? (siDoTotals[si] ?? 0) : ids.length;
          if (ids.length >= total) {
            // 시/도 전체 삭제: gu_name=null 행 포함 모든 ID 제거
            final allSiDoIds = allRegions
                .where((r) => r['si_name'] == si)
                .map((r) => r['id'] as int)
                .toSet();
            chips.add(_FilterChipData(
              RegionMapper.getLocalizedName(si, lang),
              () { analytics.filterChipRemoved('region', si);
                final u = Set<int>.from(filter.regionIds); u.removeAll(allSiDoIds); notifier.setRegionIds(u); },
            ));
          } else {
            for (final id in ids) {
              final r = allRegions.where((e) => e['id'] == id).firstOrNull;
              if (r != null && r['gu_name'] != null) {
                final gu = r['gu_name'] as String;
                final label = lang == 'ko' ? gu : DistrictNames.getLocalizedGuName(gu, si, lang);
                chips.add(_FilterChipData(label, () {
                  analytics.filterChipRemoved('region', gu);
                  notifier.toggleRegionId(id);
                }));
              }
            }
          }
        }
      }
    }
    // 급여
    if (filter.salaryRange != null && filter.salaryRange!.isNotEmpty) {
      chips.add(_FilterChipData(filter.salaryRange!, () {
        analytics.filterChipRemoved('salary', filter.salaryRange!);
        notifier.setSalary(null);
      }));
    }
    // 고용형태
    if (filter.employmentTypeIds.isNotEmpty) {
      final etOpts = ref.watch(employmentTypeOptionsProvider).valueOrNull ?? [];
      for (final id in filter.employmentTypeIds) {
        final opt = etOpts.where((o) => o.id == id).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('employment_type', opt.label);
          notifier.toggleEmploymentType(id);
        }));
      }
    }
    // 급여유형
    if (filter.salaryTypes.isNotEmpty) {
      final s = ref.watch(stringsProvider);
      final typeLabels = {
        'hourly': s.salaryHourly, 'daily': s.salaryDaily,
        'weekly': s.salaryWeekly, 'monthly': s.salaryMonthly,
        'annual': s.salaryAnnual,
      };
      for (final code in filter.salaryTypes) {
        final label = typeLabels[code] ?? code;
        chips.add(_FilterChipData(label, () {
          analytics.filterChipRemoved('salary_type', code);
          notifier.toggleSalaryType(code);
        }));
      }
    }
    // 근무요일
    if (filter.workScheduleIds.isNotEmpty) {
      final wsOpts = ref.watch(workScheduleOptionsProvider).valueOrNull ?? [];
      for (final id in filter.workScheduleIds) {
        final opt = wsOpts.where((o) => o.id == id.toString()).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('work_schedule', opt.label);
          notifier.toggleWorkSchedule(id);
        }));
      }
    }
    // 성별
    if (filter.gender != null) {
      final s = ref.watch(stringsProvider);
      final label = filter.gender == 'male' ? s.genderMale
          : filter.gender == 'female' ? s.genderFemale : s.genderAny;
      chips.add(_FilterChipData(label, () {
        analytics.filterChipRemoved('gender', filter.gender!);
        notifier.setGender(null);
      }));
    }
    // 학력
    if (filter.educations.isNotEmpty) {
      final s = ref.watch(stringsProvider);
      for (final code in filter.educations) {
        chips.add(_FilterChipData(s.educationLabel(code), () {
          analytics.filterChipRemoved('education', code);
          notifier.toggleEducation(code);
        }));
      }
    }
    // 경력
    if (filter.experiences.isNotEmpty) {
      final s = ref.watch(stringsProvider);
      for (final code in filter.experiences) {
        chips.add(_FilterChipData(s.experienceLabel(code), () {
          analytics.filterChipRemoved('experience', code);
          notifier.toggleExperience(code);
        }));
      }
    }
    // 한국어능력
    if (filter.koreanLevelIds.isNotEmpty) {
      final klOpts = ref.watch(koreanLevelOptionsProvider).valueOrNull ?? [];
      for (final id in filter.koreanLevelIds) {
        final opt = klOpts.where((o) => o.id == id.toString()).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('korean_level', opt.label);
          notifier.toggleKoreanLevel(id);
        }));
      }
    }
    // 복리후생
    if (filter.benefitIds.isNotEmpty) {
      final benOpts = ref.watch(benefitOptionsProvider).valueOrNull ?? [];
      for (final id in filter.benefitIds) {
        final opt = benOpts.where((o) => o.id == id).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('benefit', opt.label);
          notifier.toggleBenefit(id);
        }));
      }
    }
    // 비자지원
    if (filter.visaSponsorship != null) {
      final s = ref.watch(stringsProvider);
      chips.add(_FilterChipData(s.tabVisaSponsorship, () {
        analytics.filterChipRemoved('visa_sponsorship', '');
        notifier.setVisaSponsorship(null);
      }));
    }
    // 언어능력
    if (filter.languageIds.isNotEmpty) {
      final langOpts = ref.watch(languageOptionsProvider).valueOrNull ?? [];
      for (final id in filter.languageIds) {
        final opt = langOpts.where((o) => o.id == id.toString()).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('language', opt.label);
          notifier.toggleLanguage(id);
        }));
      }
    }
    // 국가
    if (filter.countryIds.isNotEmpty) {
      final countryOpts = ref.watch(countryOptionsProvider).valueOrNull ?? [];
      for (final id in filter.countryIds) {
        final opt = countryOpts.where((o) => o.id == id).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('country', opt.label);
          notifier.toggleCountry(id);
        }));
      }
    }
    // 출처(사이트)
    if (filter.siteIds.isNotEmpty) {
      final siteOpts = ref.watch(siteOptionsProvider).valueOrNull ?? [];
      for (final id in filter.siteIds) {
        final opt = siteOpts.where((o) => o.id == id).firstOrNull;
        if (opt != null) chips.add(_FilterChipData(opt.label, () {
          analytics.filterChipRemoved('site', opt.label);
          notifier.toggleSite(id);
        }));
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.carrotLight,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chips[i].label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.carrotDark,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: chips[i].onRemove,
                  child: const Icon(Icons.close, size: 14, color: AppColors.carrot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.carrot
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FilterShortcutChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterShortcutChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FilterPulse extends StatefulWidget {
  final bool enabled;
  final Widget child;
  const _FilterPulse({required this.enabled, required this.child});

  @override
  State<_FilterPulse> createState() => _FilterPulseState();
}

class _FilterPulseState extends State<_FilterPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _FilterPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

// 상단 고정 슬리버 헤더 (결과 행 / 선택 필터 칩)
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  const _PinnedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
