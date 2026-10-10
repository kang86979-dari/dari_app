import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../favorites/favorite_actions.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../data/repositories/job_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/applied_job_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/job_note_provider.dart';
import '../home/widgets/job_card.dart';
import '../../data/services/analytics_service.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/error_retry.dart';
import '../../core/utils/filter_matcher.dart';
import '../../core/utils/region_mapper.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/empty_placeholder.dart';
import '../../core/widgets/sort_sheet.dart';
import '../../providers/search_alert_provider.dart';
import '../filter/filter_chips_row.dart';
import '../account/note_actions.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/constants/ad_config.dart';
import '../../core/utils/native_ad_controller.dart';
import '../../core/utils/mrec_ad_controller.dart';
import '../home/widgets/native_ad_card.dart';
import '../home/widgets/mrec_ad_card.dart';
import '../../data/models/filter_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  /// 푸시 딥링크 등에서 넘어온 초기 검색어 — 있으면 진입 즉시 검색 실행.
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _showResults = false; // false=추천/최근, true=검색결과
  bool _showFab = false;
  final List<Job> _searchJobs = [];
  final _adController = NativeAdController();
  final _mrecController = MrecAdController();
  int _searchPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _sortBy = 'relevance'; // 'relevance' | 'latest' | 'salary_desc'
  String? _lastLangCode;
  String? _lastFilterJson; // 전역 필터 변경 감지 — 검색 결과 리셋용(2026-10-09)

  // 필터 추천 탭
  int _activeTab = 0; // 0=검색결과, 1=필터추천
  List<FilterMatchGroup> _filterMatches = [];
  final Set<String> _selectedFilterKeys = {}; // "category:id" 형식
  int? _filterPreviewCount;
  bool _isCountLoading = false;

  @override
  void initState() {
    super.initState();
    analytics.screenView('search');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = widget.initialQuery?.trim() ?? '';
      if (q.isNotEmpty) {
        _controller.text = q;
        _executeSearch(q);
      } else {
        _focusNode.requestFocus();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  // ── 키워드 알림 (결과 상단 제안 배너, 2026-10-10) ──
  // 판정은 **검색어만** 일치로 — 공유 프로바이더(searchAlertProvider) 사용.
  bool get _alertMatchesCurrent =>
      ref.watch(searchAlertProvider.notifier).matchesKeyword(
          ref.read(searchQueryProvider));

  // 결과 상단 알림 제안/활성 배너 — 아이콘만으론 "검색 저장+알림" 개념이
  // 안 보여서 문장으로 제안(2026-10-10). 현재 조건이 등록돼 있으면
  // "받고 있어요 + 해제", 아니면 "알려드릴까요? [알림 받기]".
  Widget _alertOfferBanner(dynamic s) {
    final q = ref.read(searchQueryProvider);
    if (q.isEmpty) return const SizedBox.shrink();
    // 상태를 무조건 watch — 조건부(&&) 뒤에 두면 활성 상태에선 watch가
    // 등록되지 않아 해제해도 배너가 안 바뀌는 버그(2026-10-10 수정).
    final cond = ref.watch(searchAlertProvider);
    final active = (cond?['keyword'] as String?) == q;
    // 다른 키워드가 이미 등록돼 있으면 "등록"이 아닌 "변경"으로 안내.
    final hasOther = !active && cond != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.carrotLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.notifications_active : Icons.notifications_none,
            size: 18,
            color: AppColors.carrot,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              active ? s.searchAlertActiveBanner(q) : s.searchAlertOfferTitle(q),
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: AppColors.carrotDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _onBellTap(s),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? Colors.transparent : AppColors.carrot,
                borderRadius: BorderRadius.circular(8),
                border: active ? Border.all(color: AppColors.carrot) : null,
              ),
              child: Text(
                active
                    ? s.searchAlertOffButton
                    : hasOther
                        ? s.searchAlertChangeButton
                        : s.searchAlertOfferButton,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.carrot : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// {from}/{to} 템플릿 → 키워드만 색 강조(기존=남색, 새=carrot)한 리치 본문.
  Widget _replaceBodyRich(String tpl, String from, String to) {
    const base = TextStyle(
        fontSize: 15.5,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: AppColors.gray900);
    final spans = <TextSpan>[];
    var i = 0;
    for (final m in RegExp(r'\{from\}|\{to\}').allMatches(tpl)) {
      if (m.start > i) spans.add(TextSpan(text: tpl.substring(i, m.start)));
      final isFrom = m.group(0) == '{from}';
      spans.add(TextSpan(
        text: isFrom ? from : to,
        style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isFrom ? AppColors.navy : AppColors.carrot),
      ));
      i = m.end;
    }
    if (i < tpl.length) spans.add(TextSpan(text: tpl.substring(i)));
    return Text.rich(TextSpan(style: base, children: spans));
  }

  Future<void> _onBellTap(dynamic s) async {
    final alertNotifier = ref.read(searchAlertProvider.notifier);
    final cond = ref.read(searchAlertProvider);
    // 현재 검색어가 이미 등록돼 있으면 재탭 = 해제.
    if (_alertMatchesCurrent) {
      await alertNotifier.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.searchAlertOffToast),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    // 다른 키워드가 등록돼 있으면 변경 확인(1개만 등록).
    if (cond != null) {
      final ok = await showAppDialog(
        context,
        title: s.searchAlertReplaceTitle,
        // 문장 속 키워드만 색 강조(기존=남색, 새=carrot) — 캡처 디자인(2026-10-10).
        body: _replaceBodyRich(
            s.searchAlertReplaceTemplate as String,
            (cond['keyword'] as String?) ?? '',
            ref.read(searchQueryProvider)),
        helper: s.searchAlertReplaceBody,
        cancelLabel: s.cancel,
        confirmLabel: s.searchAlertReplaceConfirm,
      );
      if (ok != true || !mounted) return;
    }
    final keyword = ref.read(searchQueryProvider);
    final filter = ref.read(filterStateProvider);
    // 표시용 라벨: 검색어 + 필터 칩 라벨 (저장 시점 언어).
    final labels = buildFilterChipData(filter, ref).map((c) => c.label);
    final label = [keyword, ...labels].join(' · ');
    await alertNotifier.register(
      keyword: keyword,
      label: label,
      filter: filter,
      langCode: ref.read(languageProvider),
    );
    analytics.log('search_alert_saved', {'keyword': keyword});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.searchAlertOnToast),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _adController.disposeAll();
    _mrecController.disposeAll();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 740;
    if (show != _showFab) setState(() => _showFab = show);

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _executeSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    analytics.searchExecuted(q, 0);
    ref.read(recentSearchProvider.notifier).add(q);
    _searchJobs.clear();
    ref.read(searchQueryProvider.notifier).state = q;
    ref.invalidate(searchResultProvider);
    // count는 결과 로드 후 지연 호출 (검색 속도 우선)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) ref.invalidate(searchTotalCountProvider);
    });
    _searchPage = 0;
    _hasMore = true;
    _activeTab = 0;
    _selectedFilterKeys.clear();
    _filterPreviewCount = null;
    _filterMatches = [];
    setState(() => _showResults = true);
    _focusNode.unfocus();
    _matchFilters(q);
  }

  Future<void> _matchFilters(String query) async {
    final s = ref.read(stringsProvider);
    final optionsByCategory = <String, List<FilterOption>>{};
    final categoryLabels = <String, String>{};

    // 이미 로드된 provider에서 즉시 가져오기 (대기 없음)
    final visas = ref.read(visaOptionsProvider).valueOrNull;
    final regions = ref.read(siDoOptionsProvider).valueOrNull;
    final categories = ref.read(categoryOptionsProvider).valueOrNull;
    final empTypes = ref.read(employmentTypeOptionsProvider).valueOrNull;
    final korLevels = ref.read(koreanLevelOptionsProvider).valueOrNull;

    if (visas != null && visas.isNotEmpty) {
      optionsByCategory['visa'] = visas;
      categoryLabels['visa'] = s.tabVisa;
    }
    if (regions != null && regions.isNotEmpty) {
      optionsByCategory['region'] = regions;
      categoryLabels['region'] = s.tabRegion;
    }
    if (categories != null && categories.isNotEmpty) {
      optionsByCategory['category'] = categories;
      categoryLabels['category'] = s.tabJobType;
    }
    if (empTypes != null && empTypes.isNotEmpty) {
      optionsByCategory['employmentType'] = empTypes;
      categoryLabels['employmentType'] = s.tabEmployType;
    }
    if (korLevels != null && korLevels.isNotEmpty) {
      optionsByCategory['koreanLevel'] = korLevels;
      categoryLabels['koreanLevel'] = s.tabKoreanLevel;
    }
    final benefits = ref.read(benefitOptionsProvider).valueOrNull;
    if (benefits != null && benefits.isNotEmpty) {
      optionsByCategory['benefit'] = benefits;
      categoryLabels['benefit'] = s.tabBenefits;
    }

    final matches = FilterMatcher.match(
      query: query,
      optionsByCategory: optionsByCategory,
      categoryLabels: categoryLabels,
    );
    if (mounted) setState(() => _filterMatches = matches);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final query = ref.read(searchQueryProvider);
      final newJobs = await JobRepository().searchJobs(query,
          page: _searchPage + 1,
          langCode: ref.read(languageProvider),
          sortBy: _sortBy,
          filter: ref.read(filterStateProvider));
      if (!mounted) return;
      setState(() {
        _searchPage++;
        _searchJobs.addAll(newJobs);
        _hasMore = newJobs.length >= 20;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);
    final recentSearches = ref.watch(recentSearchProvider);
    final inputText = _controller.text.trim();

    // 필터 옵션 미리 로드 (필터 추천 탭용)
    ref.watch(visaOptionsProvider);
    ref.watch(siDoOptionsProvider);
    ref.watch(categoryOptionsProvider);
    ref.watch(employmentTypeOptionsProvider);
    ref.watch(koreanLevelOptionsProvider);

    // 언어 변경 시 검색 결과 캐시 리셋
    if (_lastLangCode != null && _lastLangCode != langCode && _showResults) {
      _searchJobs.clear();
      _searchPage = 0;
      _hasMore = true;
      ref.invalidate(searchResultProvider);
    }
    _lastLangCode = langCode;

    // 전역 필터 변경 시 검색 결과·건수 리셋 — 검색은 검색어 AND 필터(2026-10-09).
    final searchFilter = ref.watch(filterStateProvider);
    final filterJson = jsonEncode(searchFilter.toJson());
    if (_lastFilterJson != null && _lastFilterJson != filterJson && _showResults) {
      _searchJobs.clear();
      _searchPage = 0;
      _hasMore = true;
      ref.invalidate(searchResultProvider);
      ref.invalidate(searchTotalCountProvider);
    }
    _lastFilterJson = filterJson;

    return Scaffold(
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
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            // 검색 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  AppBackButton(
                    onTap: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                      context.pop();
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 18, color: AppColors.gray300),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLength: 50,
                              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                              onChanged: (_) => setState(() {
                                _showResults = false;
                              }),
                              onSubmitted: _executeSearch,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                  fontSize: 16, color: AppColors.black),
                              decoration: InputDecoration(
                                hintText: s.searchPlaceholder,
                                hintStyle:
                                    const TextStyle(color: AppColors.gray300),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() => _showResults = false);
                              },
                              child: const Icon(Icons.close,
                                  size: 18, color: AppColors.gray300),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      ref.read(searchQueryProvider.notifier).state = '';
                      context.pop();
                    },
                    child: Text(s.cancel,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.gray600)),
                  ),
                ],
              ),
            ),

            // 내용
            Expanded(
              child: _showResults
                  ? _buildResults(s, langCode)
                  : _buildSuggestions(s, recentSearches, inputText),
            ),
          ],
        ),
      ),
    );
  }

  /// 추천/최근 검색어
  Widget _buildSuggestions(
      dynamic s, List<String> recentSearches, String inputText) {
    // 입력 중이면 필터된 최근 검색어 + "검색" 옵션
    if (inputText.isNotEmpty) {
      final filtered =
          recentSearches.where((r) => r.contains(inputText)).toList();
      return ListView(
        children: [
          // "'{query}' 검색" 옵션
          _SuggestionTile(
            icon: Icons.search,
            text: s.searchFor(inputText),
            onTap: () => _executeSearch(inputText),
          ),
          ...filtered.map((r) => _SuggestionTile(
                icon: Icons.history,
                text: r,
                onTap: () {
                  _controller.text = r;
                  _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: r.length));
                  _executeSearch(r);
                },
                onDelete: () =>
                    ref.read(recentSearchProvider.notifier).remove(r),
              )),
        ],
      );
    }

    // 안내 텍스트
    Widget guideWidget = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.gray300),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.searchGuide,
                style: const TextStyle(fontSize: 12, color: AppColors.gray400, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );

    // 빈 입력 → 최근 검색어
    if (recentSearches.isEmpty) {
      return Column(
        children: [
          guideWidget,
          Expanded(child: _EmptyState(hint: s.searchEmptyHint)),
        ],
      );
    }

    return ListView(
      children: [
        guideWidget,
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.recentSearches,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray600)),
              GestureDetector(
                onTap: () => ref.read(recentSearchProvider.notifier).clear(),
                child: Text(s.clearAll,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.gray300)),
              ),
            ],
          ),
        ),
        ...recentSearches.map((r) => _SuggestionTile(
              icon: Icons.history,
              text: r,
              onTap: () {
                _controller.text = r;
                _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: r.length));
                _executeSearch(r);
              },
              onDelete: () =>
                  ref.read(recentSearchProvider.notifier).remove(r),
            )),
      ],
    );
  }

  /// 검색 결과
  Widget _buildResults(dynamic s, String langCode) {
    final resultsAsync = ref.watch(searchResultProvider);
    final hasFilterMatches = _filterMatches.isNotEmpty;

    return resultsAsync.when(
      data: (jobs) {
        if (_searchJobs.isEmpty && jobs.isNotEmpty) {
          _searchJobs.addAll(jobs);
          _hasMore = jobs.length >= 20;
        }

        if (_searchJobs.isEmpty && !hasFilterMatches) {
          return _NoResults(
              title: s.noSearchResults, subtitle: s.tryOtherKeyword);
        }

        final totalMatchCount = _filterMatches.fold<int>(0, (sum, g) => sum + g.options.length);

        return Column(
          children: [
            // 탭 바 (필터 매칭이 있을 때만)
            if (hasFilterMatches)
              SegmentedTabs(
                tabs: [
                  // 로드된 페이지 수(20)가 전체 건수처럼 보여 혼동 — Total에 이미
                  // 표시되므로 탭 숫자는 제거(2026-10-09).
                  SegmentedTabItem(key: 'results', label: s.searchResultsTab),
                  SegmentedTabItem(key: 'filter', label: s.filterMatchTab, count: totalMatchCount),
                ],
                active: _activeTab == 0 ? 'results' : 'filter',
                onChange: (k) => setState(() => _activeTab = k == 'results' ? 0 : 1),
              ),

            // 필터 추천 탭
            if (_activeTab == 1 && hasFilterMatches)
              Expanded(child: _buildFilterRecommendations(s))
            else ...[

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: AppColors.gray400),
                      children: [
                        TextSpan(text: s.totalPrefix),
                        TextSpan(
                          text: ref.watch(searchTotalCountProvider).when(
                            data: (count) => NumberFormat.decimalPattern(ref.watch(languageProvider)).format(count),
                            loading: () => '...',
                            error: (_, __) => NumberFormat.decimalPattern(ref.watch(languageProvider)).format(_searchJobs.length),
                          ),
                          style: const TextStyle(
                            color: AppColors.carrot,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: s.totalSuffix),
                      ],
                    ),
                  ),
                  // 종 버튼 제거(2026-10-10) — 알림 등록은 결과 상단 제안
                  // 배너(문장)로 유도. 필터 버튼도 제거(조정은 홈에서만).
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
                          Text(_sortLabel(s),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.gray600)),
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
            // 적용된 필터 칩 (홈과 동일 위젯, 탭=삭제) — 2026-10-09.
            if (!ref.watch(filterStateProvider).isEmpty)
              ReadOnlyFilterChips(
                  filter: ref.watch(filterStateProvider), ref: ref),
            Expanded(
              child: Builder(builder: (context) {
                // 알림 배너를 리스트 첫 항목(헤더)으로 넣어 스크롤 시 함께
                // 올라가게 함(2026-10-10). header=배너 유무.
                final showBanner = _searchJobs.isNotEmpty;
                final header = showBanner ? 1 : 0;
                return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: header +
                    1 +
                    _searchJobs.length +
                    (_searchJobs.length ~/ AdConfig.listAdInterval) +
                    (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, rawIndex) {
                  // 헤더(배너) 먼저.
                  if (showBanner && rawIndex == 0) return _alertOfferBanner(s);
                  final index = rawIndex - header;
                  const n = AdConfig.listAdInterval;
                  final total = 1 +
                      _searchJobs.length +
                      (_searchJobs.length ~/ n) +
                      (_isLoadingMore ? 1 : 0);

                  // 로딩 인디케이터 (마지막)
                  if (_isLoadingMore && index == total - 1) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                          child:
                              CircularProgressIndicator(color: AppColors.carrot)),
                    );
                  }

                  // 최상단도 네이티브. slot -1로 인-리스트 슬롯과 키 분리.
                  if (index == 0) {
                    return NativeAdCard(controller: _adController, slot: -1);
                  }

                  final a = index - 1;
                  final cycle = a ~/ (n + 1); // (공고 N개 + 광고 1개) 반복 단위
                  final pos = a % (n + 1);

                  // 각 주기 마지막(pos==n) = 광고 슬롯 (cycle 짝수=MREC, 홀수=small)
                  if (pos == n) {
                    return cycle.isEven
                        ? MrecAdCard(controller: _mrecController, slot: cycle)
                        : NativeAdCard(controller: _adController, slot: cycle);
                  }

                  final jobIndex = cycle * n + pos;
                  if (jobIndex >= _searchJobs.length) {
                    return const SizedBox.shrink();
                  }

                  final job = _searchJobs[jobIndex];
                  final query = ref.read(searchQueryProvider);
                  return JobCard(
                    job: job,
                    langCode: langCode,
                    alwaysOpen: s.alwaysOpen,
                    salaryFallback: s.salaryByCompany,
                    strings: s,
                    isFavorite: ref.watch(isFavoriteProvider(job.id)),
                    // 메모=서버(job_notes) + 2.1.6 카드 작성 UX 이식(2026-10-10 머지).
                    memo: ref.watch(jobNotesProvider).valueOrNull?[job.id],
                    memoAddLabel: s.jobMemoAdd,
                    onMemoTap: () => editJobNote(context, ref, job, langCode),
                    applied: ref.watch(appliedJobIdsProvider).contains(job.id),
                    appliedLabel: s.jobAppliedChip,
                    onTap: () {
                      analytics.searchResultTap(job.id, query, jobIndex);
                      context.push('/job/${job.id}');
                    },
                    onFavoriteToggle: () => toggleFavoriteWithAuth(
                        context, ref, job.id,
                        source: 'search'),
                  );
                },
              );
              }),
            ),
            ], // ...[  닫기
          ],
        );
      },
      loading: () => Column(
        children: [
          SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: const AlwaysStoppedAnimation(AppColors.carrot),
            ),
          ),
          const Spacer(),
        ],
      ),
      error: (e, _) => ErrorRetry(
        onRetry: () => ref.invalidate(searchResultProvider),
      ),
    );
  }

  String _sortLabel(dynamic s) {
    switch (_sortBy) {
      case 'latest': return s.sortLatest;
      case 'salary_desc': return s.sortSalaryHigh;
      default: return s.sortAccuracy;
    }
  }

  Widget _buildFilterRecommendations(dynamic s) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              // 이 탭이 "검색어 관련 추천 필터"임을 안내(2026-10-10).
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  s.filterMatchHint,
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.4, color: AppColors.gray400),
                ),
              ),
              for (final group in _filterMatches) ...[
                // 카테고리 헤더
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(children: [
                    Container(
                      width: 3, height: 14,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.carrot,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(group.categoryLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black)),
                  ]),
                ),
                // 옵션 리스트
                for (final opt in group.options)
                  GestureDetector(
                    onTap: () {
                      final key = '${group.category}:${opt.id}';
                      setState(() {
                        if (_selectedFilterKeys.contains(key)) {
                          _selectedFilterKeys.remove(key);
                        } else {
                          _selectedFilterKeys.add(key);
                        }
                      });
                      _loadPreviewCount();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Row(children: [
                        Icon(
                          _selectedFilterKeys.contains('${group.category}:${opt.id}')
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                          color: _selectedFilterKeys.contains('${group.category}:${opt.id}')
                              ? AppColors.carrot
                              : AppColors.gray300,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(opt.label,
                          style: const TextStyle(fontSize: 14, color: AppColors.gray600))),
                      ]),
                    ),
                  ),
              ],
            ],
          ),
        ),
        // 기존 필터 칩 + 결과보기 버튼
        if (_selectedFilterKeys.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Column(children: [
              // 기존 적용된 필터 칩
              _buildExistingFilterChips(s),
              const SizedBox(height: 12),
              SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => _applyFilters(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.carrot,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isCountLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      )
                    : Text(
                        _filterPreviewCount != null
                          ? '${s.showResults} (${NumberFormat.decimalPattern(ref.read(languageProvider)).format(_filterPreviewCount)})'
                          : s.showResults as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
            ]),
          ),
      ],
    );
  }

  Widget _buildExistingFilterChips(dynamic s) {
    final filter = ref.watch(filterStateProvider);
    if (filter.isEmpty) return const SizedBox.shrink();

    final chips = <String>[];

    // 비자
    final visaOpts = ref.read(visaOptionsProvider).valueOrNull ?? [];
    for (final id in filter.visaIds) {
      final opt = visaOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }
    // 직종
    final catOpts = ref.read(categoryOptionsProvider).valueOrNull ?? [];
    for (final id in filter.categoryIds) {
      final opt = catOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }
    // 지역
    if (filter.regionIds.isNotEmpty) {
      final allRegions = JobRepository.allRegionsCacheSync;
      if (allRegions != null) {
        final siNames = <String>{};
        for (final id in filter.regionIds) {
          final r = allRegions.where((e) => e['id'] == id).firstOrNull;
          if (r != null) siNames.add(r['si_name'] as String);
        }
        final langCode = ref.read(languageProvider);
        for (final si in siNames) {
          chips.add(RegionMapper.getLocalizedName(si, langCode));
        }
      }
    }
    // 고용형태
    final etOpts = ref.read(employmentTypeOptionsProvider).valueOrNull ?? [];
    for (final id in filter.employmentTypeIds) {
      final opt = etOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }
    // 급여유형
    for (final st in filter.salaryTypes) {
      final label = switch (st) {
        'hourly' => s.salaryHourly,
        'daily' => s.salaryDaily,
        'weekly' => s.salaryWeekly,
        'monthly' => s.salaryMonthly,
        'annual' => s.salaryAnnual,
        'negotiable' => s.salaryNegotiable,
        _ => st,
      };
      chips.add(label);
    }
    // 근무요일
    final wsOpts = ref.read(workScheduleOptionsProvider).valueOrNull ?? [];
    for (final id in filter.workScheduleIds) {
      final opt = wsOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }
    // 한국어능력
    final klOpts = ref.read(koreanLevelOptionsProvider).valueOrNull ?? [];
    for (final id in filter.koreanLevelIds) {
      final opt = klOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }
    // 복리후생
    final benefitOpts = ref.read(benefitOptionsProvider).valueOrNull ?? [];
    for (final id in filter.benefitIds) {
      final opt = benefitOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }
    // 성별
    if (filter.gender != null) {
      final genderLabel = switch (filter.gender) {
        'male' => s.genderMale,
        'female' => s.genderFemale,
        'any' => s.genderAny,
        _ => filter.gender!,
      };
      chips.add(genderLabel);
    }
    // 학력
    for (final edu in filter.educations) {
      chips.add(s.educationLabel(edu));
    }
    // 경력
    for (final exp in filter.experiences) {
      chips.add(s.experienceLabel(exp));
    }
    // 비자지원
    if (filter.visaSponsorship != null) {
      chips.add(s.tabVisaSponsorship);
    }
    // 언어
    final langOpts = ref.read(languageOptionsProvider).valueOrNull ?? [];
    for (final id in filter.languageIds) {
      final opt = langOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }
    // 사이트
    final siteOpts = ref.read(siteOptionsProvider).valueOrNull ?? [];
    for (final id in filter.siteIds) {
      final opt = siteOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }
    // 국가
    final countryOpts = ref.read(countryOptionsProvider).valueOrNull ?? [];
    for (final id in filter.countryIds) {
      final opt = countryOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(opt.label);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD4B3)),
          ),
          child: Text(chips[i],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.carrot)),
        ),
      ),
    );
  }

  Future<void> _loadPreviewCount() async {
    if (_selectedFilterKeys.isEmpty) {
      setState(() { _filterPreviewCount = null; _isCountLoading = false; });
      return;
    }
    setState(() => _isCountLoading = true);

    // 현재 FilterState를 복사하고 선택한 항목 추가
    final current = ref.read(filterStateProvider);
    var visaIds = Set<String>.from(current.visaIds);
    var regionIds = Set<int>.from(current.regionIds);
    var categoryIds = Set<String>.from(current.categoryIds);
    var employmentTypeIds = Set<String>.from(current.employmentTypeIds);
    var koreanLevelIds = Set<int>.from(current.koreanLevelIds);

    final repo = ref.read(jobRepositoryProvider);
    for (final key in _selectedFilterKeys) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      switch (parts[0]) {
        case 'visa': visaIds.add(parts[1]);
        case 'region':
          // 시/도 이름으로 구/군 전체 ID 가져오기
          final ids = await repo.getRegionIdsForSiDo(parts[1]);
          regionIds.addAll(ids);
        case 'category': categoryIds.add(parts[1]);
        case 'employmentType': employmentTypeIds.add(parts[1]);
        case 'koreanLevel':
          final id = int.tryParse(parts[1]);
          if (id != null) koreanLevelIds.add(id);
      }
    }

    final tempFilter = current.copyWith(
      visaIds: visaIds,
      regionIds: regionIds,
      categoryIds: categoryIds,
      employmentTypeIds: employmentTypeIds,
      koreanLevelIds: koreanLevelIds,
    );

    try {
      final langCode = ref.read(languageProvider);
      final count = await ref.read(jobRepositoryProvider).getJobCount(filter: tempFilter, langCode: langCode);
      if (mounted) setState(() { _filterPreviewCount = count; _isCountLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isCountLoading = false);
    }
  }

  Future<void> _applyFilters() async {
    final notifier = ref.read(filterStateProvider.notifier);
    final repo = ref.read(jobRepositoryProvider);
    for (final key in _selectedFilterKeys) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final category = parts[0];
      final id = parts[1];
      switch (category) {
        case 'visa':
          notifier.toggleVisa(id);
        case 'region':
          // 시/도 이름으로 구/군 전체 ID 토글
          final ids = await repo.getRegionIdsForSiDo(id);
          for (final regionId in ids) {
            notifier.toggleRegionId(regionId);
          }
        case 'category':
          notifier.toggleCategory(id);
        case 'employmentType':
          notifier.toggleEmploymentType(id);
        case 'koreanLevel':
          final klId = int.tryParse(id);
          if (klId != null) notifier.toggleKoreanLevel(klId);
      }
    }
    context.go('/home');
  }

  void _changeSort(String sortBy) {
    if (_sortBy == sortBy) return;
    analytics.searchSortChanged(sortBy);
    setState(() {
      _sortBy = sortBy;
      _searchJobs.clear();
      _searchPage = 0;
      _hasMore = true;
    });
    ref.read(searchSortProvider.notifier).state = sortBy;
    ref.invalidate(searchResultProvider);
  }

  void _showSortSheet(BuildContext context, dynamic s) {
    showSortOptionsSheet(
      context,
      title: s.sortBy,
      options: [
        SortSheetOption(
          label: s.sortAccuracy,
          selected: _sortBy == 'relevance',
          onSelect: () => _changeSort('relevance'),
        ),
        SortSheetOption(
          label: s.sortLatest,
          selected: _sortBy == 'latest',
          onSelect: () => _changeSort('latest'),
        ),
        SortSheetOption(
          label: s.sortSalaryHigh,
          selected: _sortBy == 'salary_desc',
          onSelect: () => _changeSort('salary_desc'),
        ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SuggestionTile({
    required this.icon,
    required this.text,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gray300),
            const SizedBox(width: 14),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.black)),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.gray200),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String hint;
  const _EmptyState({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 72, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          Text(hint,
              style:
                  const TextStyle(fontSize: 16, color: AppColors.gray400)),
        ],
      ),
    );
  }
}

class _NoResults extends ConsumerWidget {
  final String title;
  final String subtitle;
  const _NoResults({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return EmptyPlaceholder(
      icon: Icons.search_off,
      title: title,
      subtitle: subtitle,
      buttonLabel: s.useFilter,
      onButton: () {
        context.go('/home');
        context.push('/filter');
      },
    );
  }
}
