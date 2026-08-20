// 필터 화면 (개편안 A — 2026-08 handoff 기반)
//
// 구조: 헤더 / 그룹 pill 탭(가로 스크롤, 본문과 양방향 연동) / 칩 그리드 본문 /
//       선택 트레이(선택 있을 때만) / 하단 바(초기화 + 결과 N건 보기)
// 지역: 시·도 칩 → 시·군·구 바텀시트 드릴다운 ("전지역" 배타 선택)
//
// 확정 사항(2026-08-14): 색은 앱 팔레트(carrot/navy) 사용, hot은 정적,
// 비자 그룹핑 없이 hot+더보기, 광고 배너 없음, 풀스크린 유지.
// 상태는 기존 패턴 유지 — filterStateProvider를 실시간 변경 + 진입 시 스냅샷,
// X/백키로 나가면 변경 여부 확인 다이얼로그(적용/되돌리기).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/filter_state.dart';
import '../../providers/job_provider.dart';
import '../../providers/language_provider.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/push_service.dart';
import '../../core/utils/region_mapper.dart';
import '../../core/utils/district_names.dart';
import '../../data/repositories/job_repository.dart';

// ── 디자인 토큰 (handoff tokens.json — 색만 앱 팔레트로 치환) ──
class _T {
  static const orange = AppColors.carrot; // #FF6F0F
  static const orangeSoft = AppColors.carrotLight; // #FFF3EB
  static const navy = AppColors.navy; // #003478
  static const ink = Color(0xFF17171C);
  static const text = Color(0xFF2B2B33);
  static const muted = Color(0xFF8E8E98);
  static const line = Color(0xFFECE9E4);
}

// 그룹 키 (탭 순서 = 기존 initialTab 인덱스와 호환)
const _kGroups = [
  'visa', 'category', 'employ', 'region', 'salary',
  'schedule', 'korean', 'benefit', 'country', 'site',
];
const _kRegion = 'region';

/// 시·도 데이터 (regions 캐시에서 구성)
class _SidoData {
  final String si;
  final int? siRowId; // gu_name == null 인 시·도 행
  final List<({int id, String gu})> gus;
  const _SidoData({required this.si, this.siRowId, required this.gus});

  Set<int> get allIds =>
      {if (siRowId != null) siRowId!, ...gus.map((g) => g.id)};
}

class FilterScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const FilterScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late FilterState _snapshot;

  final _scroll = ScrollController();
  final _tabScroll = ScrollController();
  final Map<String, GlobalKey> _secKeys = {for (final k in _kGroups) k: GlobalKey()};
  final Map<String, GlobalKey> _tabKeys = {for (final k in _kGroups) k: GlobalKey()};
  final Set<String> _expanded = {};
  String _active = _kGroups.first;
  bool _lockSpy = false;
  bool _tabsOpen = false; // ∨ 아이콘 탭/스와이프 → 전체 탭 펼침

  List<_SidoData>? _sidos; // regions 캐시에서 1회 구성

  @override
  void initState() {
    super.initState();
    _snapshot = ref.read(filterStateProvider);
    analytics.filterOpened(_snapshot.activeCount);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverFailedFilterData();
      _loadRegions();
      // initialTab: 기존 라우팅 파라미터(인덱스) 호환 — 해당 그룹으로 점프
      if (widget.initialTab > 0 && widget.initialTab < _kGroups.length) {
        _jump(_kGroups[widget.initialTab]);
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _tabScroll.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    final rows = JobRepository.allRegionsCacheSync ??
        await ref.read(jobRepositoryProvider).getAllRegionsPublic();
    if (!mounted) return;
    final map = <String, ({int? siId, List<({int id, String gu})> gus})>{};
    for (final r in rows) {
      final si = r['si_name'] as String? ?? '';
      if (si.isEmpty) continue;
      final cur = map[si] ?? (siId: null, gus: <({int id, String gu})>[]);
      if (r['gu_name'] == null) {
        map[si] = (siId: r['id'] as int, gus: cur.gus);
      } else {
        cur.gus.add((id: r['id'] as int, gu: r['gu_name'] as String));
        map[si] = (siId: cur.siId, gus: cur.gus);
      }
    }
    setState(() {
      _sidos = [
        for (final e in map.entries)
          _SidoData(si: e.key, siRowId: e.value.siId, gus: e.value.gus),
      ];
    });
  }

  /// 에러/실패값으로 캐시된 필터 프로바이더만 재조회 (기존 Fix A 유지)
  void _recoverFailedFilterData() {
    if (!mounted) return;
    final optionProviders = <FutureProvider<List<FilterOption>>>[
      visaOptionsProvider,
      categoryOptionsProvider,
      employmentTypeOptionsProvider,
      workScheduleOptionsProvider,
      koreanLevelOptionsProvider,
      benefitOptionsProvider,
      countryOptionsProvider,
      siteOptionsProvider,
      siDoOptionsProvider,
    ];
    for (final p in optionProviders) {
      if (ref.read(p).hasError) ref.invalidate(p);
    }
    if (ref.read(filterCountsProvider).hasError) {
      ref.invalidate(filterCountsProvider);
    }
    final total = ref.read(jobTotalCountProvider);
    if (total.hasError || total.valueOrNull == -1) {
      ref.invalidate(jobTotalCountProvider);
    }
  }

  // ── 나가기 (스냅샷 복원 확인) ──
  void _cancel() {
    final current = ref.read(filterStateProvider);
    if (current != _snapshot) {
      _showExitDialog();
    } else {
      context.pop();
    }
  }

  void _showExitDialog() {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(s.filterExitConfirm,
            style: const TextStyle(fontSize: 15, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(filterStateProvider.notifier).setState(_snapshot);
              context.pop();
            },
            child: Text(s.filterExitLeave,
                style: const TextStyle(color: Color(0xFF999999))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _apply();
            },
            child: Text(s.filterExitApply,
                style: const TextStyle(
                    color: _T.orange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _apply() {
    final filter = ref.read(filterStateProvider);
    analytics.filterApplied({'active_count': filter.activeCount});
    analytics.filterAppliedDetail(
      visaIds: filter.visaIds,
      categoryIds: filter.categoryIds,
      employmentTypeIds: filter.employmentTypeIds,
      regionNames: filter.regionIds.map((e) => e.toString()).toSet(),
      salaryTypes: filter.salaryTypes,
      workScheduleIds: filter.workScheduleIds,
      gender: filter.gender,
      educations: filter.educations,
      experiences: filter.experiences,
      koreanLevelIds: filter.koreanLevelIds,
      benefitIds: filter.benefitIds,
      countryIds: filter.countryIds,
      siteIds: filter.siteIds,
      visaSponsorship: filter.visaSponsorship,
    );
    final langCode = ref.read(languageProvider);
    if (filter.isEmpty) {
      pushService.deleteSubscription();
    } else {
      pushService.upsertSubscription(filter: filter, langCode: langCode);
    }
    context.pop();
  }

  // ── 탭 ↔ 본문 스크롤 연동 ──
  double? _sectionOffset(String key) {
    final ctx = _secKeys[key]?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    final viewport =
        _scroll.position.context.storageContext.findRenderObject() as RenderBox?;
    if (box == null || viewport == null) return null;
    final dy = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    return _scroll.offset + dy;
  }

  Future<void> _jump(String key) async {
    setState(() {
      _active = key;
      _lockSpy = true;
    });
    // 펼침→접힘 직후엔 탭 키가 다음 프레임에 생기므로 rebuild 후 reveal
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealTab(key));
    final target = _sectionOffset(key);
    if (target != null && _scroll.hasClients) {
      await _scroll.animateTo(
        (target - 6).clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(() => _lockSpy = false);
  }

  void _onScroll() {
    if (_lockSpy) return;
    final y = _scroll.offset + 24;
    String cur = _kGroups.first;
    for (final k in _kGroups) {
      final top = _sectionOffset(k);
      if (top != null && top <= y) cur = k;
    }
    if (cur != _active) {
      setState(() => _active = cur);
      _revealTab(cur);
    }
  }

  void _revealTab(String key) {
    final ctx = _tabKeys[key]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: 0.4,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut);
  }

  // ── 지역 선택 상태 (regionIds ↔ 시·도/구 파생) ──
  bool _sidoIsAll(_SidoData s, Set<int> ids) =>
      s.allIds.isNotEmpty && ids.containsAll(s.allIds);

  List<({int id, String gu})> _sidoPickedGus(_SidoData s, Set<int> ids) =>
      s.gus.where((g) => ids.contains(g.id)).toList();

  int _regionCount(Set<int> ids) {
    final sidos = _sidos;
    if (sidos == null) return ids.isEmpty ? 0 : 1;
    int n = 0;
    for (final s in sidos) {
      if (_sidoIsAll(s, ids)) {
        n += 1; // 전지역 = 1개로 집계
      } else {
        n += _sidoPickedGus(s, ids).length;
      }
    }
    return n;
  }

  void _setSidoAll(_SidoData s) {
    final notifier = ref.read(filterStateProvider.notifier);
    final ids = Set<int>.from(ref.read(filterStateProvider).regionIds)
      ..addAll(s.allIds);
    notifier.setRegionIds(ids);
  }

  void _clearSido(_SidoData s) {
    final notifier = ref.read(filterStateProvider.notifier);
    final ids = Set<int>.from(ref.read(filterStateProvider).regionIds)
      ..removeAll(s.allIds);
    notifier.setRegionIds(ids);
  }

  void _toggleGu(_SidoData s, int guId) {
    final notifier = ref.read(filterStateProvider.notifier);
    final ids = Set<int>.from(ref.read(filterStateProvider).regionIds);
    if (_sidoIsAll(s, ids)) {
      // 전지역 → 해당 구만 해제한 부분 선택으로 전환
      ids.removeAll(s.allIds);
      ids.addAll(s.gus.map((g) => g.id).where((id) => id != guId));
    } else if (ids.contains(guId)) {
      ids.remove(guId);
    } else {
      ids.add(guId);
      // 전부 고르면 전지역으로 승격 (시·도 행 포함 → 시 단위 공고도 매칭)
      if (ids.containsAll(s.gus.map((g) => g.id))) ids.addAll(s.allIds);
    }
    notifier.setRegionIds(ids);
  }

  // ── 빌드 ──
  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterStateProvider);
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _header(s),
              _tabs(filter, s),
              Expanded(child: _body(filter, s, langCode)),
              if (_total(filter) > 0) _tray(filter, s, langCode),
              _bottomBar(filter, s, langCode),
            ],
          ),
        ),
      ),
    );
  }

  int _total(FilterState f) =>
      f.visaIds.length +
      (f.visaSponsorship != null ? 1 : 0) +
      f.categoryIds.length +
      f.employmentTypeIds.length +
      _regionCount(f.regionIds) +
      f.salaryTypes.length +
      f.workScheduleIds.length +
      f.koreanLevelIds.length +
      f.benefitIds.length +
      f.countryIds.length +
      f.siteIds.length;

  int _countOf(String key, FilterState f) => switch (key) {
        'visa' => f.visaIds.length + (f.visaSponsorship != null ? 1 : 0),
        'category' => f.categoryIds.length,
        'employ' => f.employmentTypeIds.length,
        'region' => _regionCount(f.regionIds),
        'salary' => f.salaryTypes.length,
        'schedule' => f.workScheduleIds.length,
        'korean' => f.koreanLevelIds.length,
        'benefit' => f.benefitIds.length,
        'country' => f.countryIds.length,
        'site' => f.siteIds.length,
        _ => 0,
      };

  String _labelOf(String key, dynamic s) => switch (key) {
        'visa' => s.tabVisa as String,
        'category' => s.tabJobType as String,
        'employ' => s.tabEmployType as String,
        'region' => s.tabRegion as String,
        'salary' => s.tabSalary as String,
        'schedule' => s.tabWorkSchedule as String,
        'korean' => s.tabKoreanLevel as String,
        'benefit' => s.tabBenefits as String,
        'country' => s.tabCountry as String,
        'site' => s.tabSite as String,
        _ => '',
      };

  Widget _header(dynamic s) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 10, 14),
        child: Row(
          children: [
            Text(s.filterTitle as String,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: _T.ink)),
            const Spacer(),
            IconButton(
              onPressed: _cancel,
              icon: const Icon(Icons.close, size: 22, color: _T.muted),
              splashRadius: 22,
            ),
          ],
        ),
      );

  Widget _tabs(FilterState filter, dynamic s) {
    void toggle() => setState(() => _tabsOpen = !_tabsOpen);

    // 펼침/접힘 화살표 버튼 — 탭 또는 세로 스와이프로 토글
    final toggleBtn = GestureDetector(
      onTap: toggle,
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 80 && !_tabsOpen) setState(() => _tabsOpen = true);
        if (v < -80 && _tabsOpen) setState(() => _tabsOpen = false);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 38,
        alignment: Alignment.center,
        child: Icon(_tabsOpen ? Icons.expand_less : Icons.expand_more,
            size: 22, color: _T.navy),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _T.line)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _tabsOpen
                ? Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final k in _kGroups)
                        _GroupTab(
                          label: _labelOf(k, s),
                          count: _countOf(k, filter),
                          active: k == _active,
                          onTap: () {
                            setState(() => _tabsOpen = false);
                            _jump(k);
                          },
                        ),
                    ],
                  )
                : SingleChildScrollView(
                    controller: _tabScroll,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final k in _kGroups) ...[
                          _GroupTab(
                            key: _tabKeys[k],
                            label: _labelOf(k, s),
                            count: _countOf(k, filter),
                            active: k == _active,
                            onTap: () => _jump(k),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
          ),
          toggleBtn,
        ],
      ),
    );
  }

  // SingleChildScrollView: 전체 섹션을 항상 빌드 — 탭 점프/스크롤 스파이가
  // GlobalKey 위치를 언제나 계산할 수 있어야 함 (ListView는 화면 밖 미빌드)
  Widget _body(FilterState filter, dynamic s, String langCode) => Container(
        color: const Color(0xFFF2F3F5),
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              for (final k in _kGroups)
                Container(
                  key: _secKeys[k],
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: k == _kRegion
                      ? _regionSection(filter, s, langCode)
                      : _chipSection(k, filter, s),
                ),
            ],
          ),
        ),
      );

  Widget _sectionTitle(String label, int count, {String? hint}) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // 시안: 제목 왼쪽 주황 세로 바
              Container(
                width: 4,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _T.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: _T.ink)),
              if (count > 0) ...[
                const SizedBox(width: 8),
                _Badge(text: '$count'),
              ],
            ]),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint,
                  style: const TextStyle(fontSize: 12.5, color: _T.muted)),
            ],
          ],
        ),
      );

  // ── 그룹별 옵션 데이터 (hot = 정적) ──
  static const _visaHot = {'E-9', 'E-7', 'H-2', 'F-2', 'F-4', 'F-5', 'F-6'};
  static const _hotN = 8; // hot 지정이 없는 그룹은 앞 8개

  (AsyncValue<List<FilterOption>>, Set<String>, void Function(String))
      _groupData(String key, FilterState f, dynamic s) {
    final n = ref.read(filterStateProvider.notifier);
    switch (key) {
      case 'visa':
        return (ref.watch(visaOptionsProvider), f.visaIds, n.toggleVisa);
      case 'category':
        return (ref.watch(categoryOptionsProvider), f.categoryIds, n.toggleCategory);
      case 'employ':
        return (
          ref.watch(employmentTypeOptionsProvider),
          f.employmentTypeIds,
          n.toggleEmploymentType
        );
      case 'salary':
        final opts = [
          FilterOption(id: 'hourly', label: s.salaryHourly as String),
          FilterOption(id: 'daily', label: s.salaryDaily as String),
          FilterOption(id: 'weekly', label: s.salaryWeekly as String),
          FilterOption(id: 'monthly', label: s.salaryMonthly as String),
          FilterOption(id: 'annual', label: s.salaryAnnual as String),
        ];
        return (AsyncValue.data(opts), f.salaryTypes, n.toggleSalaryType);
      case 'schedule':
        return (
          ref.watch(workScheduleOptionsProvider),
          f.workScheduleIds.map((e) => e.toString()).toSet(),
          (id) => n.toggleWorkSchedule(int.parse(id))
        );
      case 'korean':
        return (
          ref.watch(koreanLevelOptionsProvider),
          f.koreanLevelIds.map((e) => e.toString()).toSet(),
          (id) => n.toggleKoreanLevel(int.parse(id))
        );
      case 'benefit':
        return (ref.watch(benefitOptionsProvider), f.benefitIds, n.toggleBenefit);
      case 'country':
        return (ref.watch(countryOptionsProvider), f.countryIds, n.toggleCountry);
      case 'site':
        return (ref.watch(siteOptionsProvider), f.siteIds, n.toggleSite);
      default:
        return (const AsyncValue.data([]), const {}, (_) {});
    }
  }

  Widget _chipSection(String key, FilterState filter, dynamic s) {
    final (optionsAsync, selected, onToggle) = _groupData(key, filter, s);
    final title = _labelOf(key, s);
    final count = _countOf(key, filter);

    return optionsAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, count),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _T.orange),
            ),
          ),
        ],
      ),
      error: (_, __) => _sectionTitle(title, count),
      data: (options) {
        // hot/rest 분할 — 비자는 코드 화이트리스트, 그 외는 앞 N개
        List<FilterOption> hot, rest;
        if (key == 'visa') {
          hot = options.where((o) => _visaHot.contains(o.label)).toList();
          rest = options.where((o) => !_visaHot.contains(o.label)).toList();
        } else if (options.length <= _hotN + 2) {
          hot = options;
          rest = const [];
        } else {
          hot = options.take(_hotN).toList();
          rest = options.skip(_hotN).toList();
        }
        final open = _expanded.contains(key);
        // 접힘 상태: more 안에서 선택된 항목은 앞으로 승격해 항상 표시
        final promoted =
            rest.where((o) => selected.contains(o.id)).toList();
        final hiddenCount = rest.length - promoted.length;
        final shown = open ? [...hot, ...rest] : [...hot, ...promoted];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(title, count),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 비자지원 토글 — 비자 그룹 맨 앞 특수 칩
                if (key == 'visa')
                  _Chip(
                    label: s.tabVisaSponsorship as String,
                    selected: filter.visaSponsorship == true,
                    onTap: () => ref
                        .read(filterStateProvider.notifier)
                        .setVisaSponsorship(
                            filter.visaSponsorship == true ? null : true),
                  ),
                for (final o in shown)
                  _Chip(
                    label: o.label,
                    selected: selected.contains(o.id),
                    onTap: () => onToggle(o.id),
                  ),
                if (open || hiddenCount > 0)
                  _MoreChip(
                    label: open
                        ? s.filterCollapse as String
                        : s.filterMoreN(hiddenCount) as String,
                    onTap: () => setState(() =>
                        open ? _expanded.remove(key) : _expanded.add(key)),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── 지역 섹션 ──
  Widget _regionSection(FilterState filter, dynamic s, String langCode) {
    final sidos = _sidos;
    final title = _labelOf(_kRegion, s);
    final count = _countOf(_kRegion, filter);
    if (sidos == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, count, hint: s.filterRegionHint as String),
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _T.orange),
          ),
        ],
      );
    }
    final open = _expanded.contains(_kRegion);
    // 접힘 상태: 7번째 이후 시·도 중 선택된 것은 승격해 항상 표시
    bool sidoSelected(_SidoData sd) =>
        _sidoIsAll(sd, filter.regionIds) ||
        _sidoPickedGus(sd, filter.regionIds).isNotEmpty;
    final promotedSidos = sidos.skip(6).where(sidoSelected).toList();
    final hiddenCount = sidos.length - 6 - promotedSidos.length;
    final shown =
        open ? sidos : [...sidos.take(6), ...promotedSidos];
    String siLabel(String si) =>
        langCode == 'ko' ? si : RegionMapper.getLocalizedName(si, 'en');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, count, hint: s.filterRegionHint as String),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final sd in shown)
              Builder(builder: (context) {
                final ids = filter.regionIds;
                final all = _sidoIsAll(sd, ids);
                final picked = _sidoPickedGus(sd, ids);
                return _Chip(
                  label: siLabel(sd.si),
                  // 비한국어: 윗줄 영어 / 아랫줄 (한글)
                  subLabel: langCode == 'ko' ? null : '(${sd.si})',
                  selected: all || picked.isNotEmpty,
                  badge: all
                      ? '✓'
                      : picked.isNotEmpty
                          ? '${picked.length}'
                          : null,
                  onTap: () => _openSido(sd, langCode),
                );
              }),
            if (open || hiddenCount > 0)
              _MoreChip(
                label: open
                    ? s.filterCollapse as String
                    : s.filterMoreN(hiddenCount) as String,
                onTap: () => setState(() => open
                    ? _expanded.remove(_kRegion)
                    : _expanded.add(_kRegion)),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _openSido(_SidoData sd, String langCode) async {
    final s = ref.read(stringsProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: _T.navy.withValues(alpha: 0.28),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final ids = ref.read(filterStateProvider).regionIds;
          final all = _sidoIsAll(sd, ids);
          final picked = _sidoPickedGus(sd, ids).map((g) => g.id).toSet();
          final siName =
              langCode == 'ko' ? sd.si : RegionMapper.getLocalizedName(sd.si, 'en');
          // 비한국어: '영어 (한글)' 병기 (구버전 표기)
          String guLabel(String gu) => langCode == 'ko'
              ? gu
              : '${DistrictNames.getLocalizedGuName(gu, sd.si, langCode)} ($gu)';
          return _SidoSheet(
            title: langCode == 'ko' ? sd.si : '$siName (${sd.si})',
            allLabel: s.filterAllRegion(siName),
            sigunguLabel: s.filterSigungu,
            gus: [for (final g in sd.gus) (id: g.id, label: guLabel(g.gu))],
            isAll: all,
            pickedIds: picked,
            onAll: () {
              all ? _clearSido(sd) : _setSidoAll(sd);
              setSheet(() {});
              setState(() {});
            },
            onToggleGu: (id) {
              _toggleGu(sd, id);
              setSheet(() {});
              setState(() {});
            },
            applyLabel: all
                ? s.filterAllRegion(siName)
                : picked.isNotEmpty
                    ? s.filterApplyPlaces(picked.length)
                    : s.close,
            onClose: () => Navigator.of(ctx).pop(),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  // ── 선택 트레이 ──
  Widget _tray(FilterState f, dynamic s, String langCode) {
    final chips = <Widget>[];
    final n = ref.read(filterStateProvider.notifier);

    void addFromOptions(AsyncValue<List<FilterOption>> async, Set<String> sel,
        void Function(String) onToggle) {
      final options = async.valueOrNull ?? const <FilterOption>[];
      for (final id in sel) {
        final label =
            options.where((o) => o.id == id).firstOrNull?.label ?? id;
        chips.add(_RemovableChip(label: label, onRemove: () => onToggle(id)));
      }
    }

    if (f.visaSponsorship == true) {
      chips.add(_RemovableChip(
          label: s.tabVisaSponsorship as String,
          onRemove: () => n.setVisaSponsorship(null)));
    }
    addFromOptions(ref.watch(visaOptionsProvider), f.visaIds, n.toggleVisa);
    addFromOptions(
        ref.watch(categoryOptionsProvider), f.categoryIds, n.toggleCategory);
    addFromOptions(ref.watch(employmentTypeOptionsProvider),
        f.employmentTypeIds, n.toggleEmploymentType);
    // 지역
    // 구버전과 동일: 시/도 전체=지역명(앱 언어), 구/군 개별=구 이름만
    final sidos = _sidos ?? const <_SidoData>[];
    for (final sd in sidos) {
      final all = _sidoIsAll(sd, f.regionIds);
      if (all) {
        chips.add(_RemovableChip(
            label: RegionMapper.getLocalizedName(sd.si, langCode),
            onRemove: () => _clearSido(sd)));
      } else {
        for (final g in _sidoPickedGus(sd, f.regionIds)) {
          final guLabel = langCode == 'ko'
              ? g.gu
              : DistrictNames.getLocalizedGuName(g.gu, sd.si, langCode);
          chips.add(_RemovableChip(
              label: guLabel, onRemove: () => _toggleGu(sd, g.id)));
        }
      }
    }
    // 급여
    for (final st in f.salaryTypes) {
      final label = switch (st) {
        'hourly' => s.salaryHourly as String,
        'daily' => s.salaryDaily as String,
        'weekly' => s.salaryWeekly as String,
        'monthly' => s.salaryMonthly as String,
        'annual' => s.salaryAnnual as String,
        'negotiable' => s.salaryNegotiable as String,
        _ => st,
      };
      chips.add(
          _RemovableChip(label: label, onRemove: () => n.toggleSalaryType(st)));
    }
    addFromOptions(
        ref.watch(workScheduleOptionsProvider),
        f.workScheduleIds.map((e) => e.toString()).toSet(),
        (id) => n.toggleWorkSchedule(int.parse(id)));
    addFromOptions(
        ref.watch(koreanLevelOptionsProvider),
        f.koreanLevelIds.map((e) => e.toString()).toSet(),
        (id) => n.toggleKoreanLevel(int.parse(id)));
    addFromOptions(ref.watch(benefitOptionsProvider), f.benefitIds, n.toggleBenefit);
    addFromOptions(ref.watch(countryOptionsProvider), f.countryIds, n.toggleCountry);
    addFromOptions(ref.watch(siteOptionsProvider), f.siteIds, n.toggleSite);

    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _T.line)),
      ),
      // 칩 위 14 / 아래 6 + 하단바 위 8 = 14/14 균형 (세로 가운데, 여유 있게)
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => Align(child: chips[i]),
        ),
      ),
    );
  }

  // ── 하단 바 ── (트레이 아래 언더라인 제거 — 상단 보더 없음)
  Widget _bottomBar(FilterState f, dynamic s, String langCode) {
    final total = _total(f);
    final countAsync = ref.watch(jobTotalCountProvider);
    return Container(
      // SafeArea가 홈 인디케이터 여백을 이미 확보 — 아래 패딩 최소화
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: total > 0
                  ? () {
                      analytics.filterReset();
                      ref.read(filterStateProvider.notifier).reset();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _T.line),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                foregroundColor: _T.text,
                disabledForegroundColor: _T.muted,
              ),
              child: Text(s.reset as String,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: _T.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: countAsync.when(
                        data: (count) {
                          final formatted = count < 0
                              ? '...'
                              : NumberFormat.decimalPattern(langCode)
                                  .format(count);
                          return Text('${s.showResults} ($formatted)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: Colors.white));
                        },
                        loading: () => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(s.showResults as String,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                        error: (_, __) => Text(s.showResults as String,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 부품

class _GroupTab extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _GroupTab({
    super.key,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        // 선택 탭 = 남색 (본문이 주황 위주라 가독성 위해 대비색)
        color: active ? _T.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.2,
                      color: active ? Colors.white : _T.ink,
                    )),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // 활성 탭 위에서도 또렷하게 — 흰 배경 + 남색 숫자
                      color: active ? Colors.white : _T.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: active ? _T.navy : Colors.white,
                        )),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 20),
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _T.orange,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: Colors.white)),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final String? subLabel; // 지역 등 2줄 표기 (윗줄 영어 / 아랫줄 한글)
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subLabel,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.carrotLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // 선택 시 테두리 없음 (홈 칩과 동일) — 크기 유지 위해 투명 보더
              border: Border.all(
                color: selected ? Colors.transparent : AppColors.gray100,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? AppColors.carrotDark
                              : AppColors.gray600,
                        )),
                    if (subLabel != null)
                      Text(subLabel!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? AppColors.carrotDark
                                : AppColors.gray600,
                          )),
                  ],
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _T.orange,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MoreChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray100, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _T.muted)),
            ],
          ),
        ),
      );
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _RemovableChip({required this.label, required this.onRemove});

  @override
  // 홈 화면 필터 칩과 동일 스타일 (테두리 없음)
  Widget build(BuildContext context) => Material(
        color: AppColors.carrotLight,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding:
                const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.carrotDark)),
                const SizedBox(width: 4),
                const Icon(Icons.close, size: 14, color: AppColors.carrot),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// 지역 2단계 바텀시트
/// 바텀시트 리스트 행 — 체크박스 + 라벨 (전지역 행과 동일 스타일)
class _SheetRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SheetRow(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? _T.orangeSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _T.orange : _T.line),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected ? _T.orange : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color:
                          selected ? _T.orange : const Color(0xFFD6D2CB),
                      width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.carrotDark
                            : _T.text)),
              ),
            ],
          ),
        ),
      );
}

class _SidoSheet extends StatelessWidget {
  final String title;
  final String allLabel;
  final String sigunguLabel;
  final List<({int id, String label})> gus;
  final bool isAll;
  final Set<int> pickedIds;
  final VoidCallback onAll;
  final void Function(int id) onToggleGu;
  final String applyLabel;
  final VoidCallback onClose;

  const _SidoSheet({
    required this.title,
    required this.allLabel,
    required this.sigunguLabel,
    required this.gus,
    required this.isAll,
    required this.pickedIds,
    required this.onAll,
    required this.onToggleGu,
    required this.applyLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.78;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 18, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.chevron_left,
                      size: 24, color: _T.muted),
                  splashRadius: 20,
                ),
                Expanded(
                  child: Text(title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: _T.ink)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: InkWell(
              onTap: onAll,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isAll ? _T.orangeSoft : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: isAll ? _T.orange : _T.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isAll ? _T.orange : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: isAll
                                ? _T.orange
                                : const Color(0xFFD6D2CB),
                            width: 1.5),
                      ),
                      child: isAll
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(allLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isAll ? AppColors.carrotDark : _T.text)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(sigunguLabel,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: _T.muted)),
                  ),
                  // 구/군 — 리스트 행 형태 (구버전 방식)
                  Column(
                    children: [
                      for (final g in gus)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SheetRow(
                            label: g.label,
                            selected: isAll || pickedIds.contains(g.id),
                            onTap: () => onToggleGu(g.id),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _T.line)),
            ),
            // 홈 인디케이터 안전영역만큼 버튼을 위로 (바닥에 안 붙게)
            padding: EdgeInsets.fromLTRB(
                18, 12, 18, 14 + MediaQuery.of(context).viewPadding.bottom),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  backgroundColor: _T.navy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(applyLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
