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
import '../home/widgets/ad_banner.dart';
import '../../core/widgets/error_retry.dart';
import '../../core/utils/region_mapper.dart';
import '../../core/utils/district_names.dart';
import '../../data/repositories/job_repository.dart';

class FilterScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const FilterScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late FilterState _snapshot;
  late int _selectedIndex;
  final _regionKey = GlobalKey<_RegionSelectPanelState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _snapshot = ref.read(filterStateProvider);
    analytics.filterOpened(_snapshot.activeCount);
  }

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
        content: Text(
          s.filterExitConfirm,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
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
              context.pop();
            },
            child: Text(s.filterExitApply,
                style: const TextStyle(
                    color: AppColors.carrot, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterStateProvider);
    final notifier = ref.read(filterStateProvider.notifier);
    final s = ref.watch(stringsProvider);
    final categories = [
      _CatItem(s.tabVisa, _hasSelection(filter, 0), _selectionCount(filter, 0)),
      _CatItem(s.tabJobType, _hasSelection(filter, 1), _selectionCount(filter, 1)),
      _CatItem(s.tabEmployType, _hasSelection(filter, 2), _selectionCount(filter, 2)),
      _CatItem(s.tabRegion, _hasSelection(filter, 3), _selectionCount(filter, 3)),
      _CatItem(s.tabSalary, _hasSelection(filter, 4), _selectionCount(filter, 4)),
      _CatItem(s.tabWorkSchedule, _hasSelection(filter, 5), _selectionCount(filter, 5)),
      _CatItem(s.tabKoreanLevel, _hasSelection(filter, 6), _selectionCount(filter, 6)),
      _CatItem(s.tabBenefits, _hasSelection(filter, 7), _selectionCount(filter, 7)),
      _CatItem(s.tabCountry, _hasSelection(filter, 8), _selectionCount(filter, 8)),
      _CatItem(s.tabSite, _hasSelection(filter, 9), _selectionCount(filter, 9)),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final regionState = _regionKey.currentState;
        if (regionState != null && regionState._selectedSiDo != null) {
          regionState.setState(() => regionState._selectedSiDo = null);
          return;
        }
        _cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.filter,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black)),
                    GestureDetector(
                      onTap: _cancel,
                      child: const SizedBox(
                        width: 36, height: 36,
                        child: Center(
                            child: Text('×',
                                style: TextStyle(
                                    fontSize: 24, color: AppColors.gray300))),
                      ),
                    ),
                  ],
                ),
              ),

              // 광고 배너
              const AdBanner(),

              // 좌우 2패널 + 칩
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // 왼쪽: 카테고리 목록
                          SizedBox(
                            width: 120,
                            child: Container(
                              color: const Color(0xFFF9F9F9),
                              child: ListView.builder(
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final cat = categories[index];
                                  final isSelected = index == _selectedIndex;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedIndex = index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        border: Border(
                                          left: BorderSide(
                                            color: isSelected ? AppColors.carrot : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cat.label,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.carrot
                                                    : AppColors.gray400,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (cat.count > 0)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.carrot,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${cat.count}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // 오른쪽: 상세 필터 옵션
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: _buildDetailPanel(filter, notifier, s),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 선택된 필터 칩
                    if (!filter.isEmpty)
                      _SelectedFilterChips(
                  filter: filter,
                  notifier: notifier,
                  visaOpts: ref.watch(visaOptionsProvider).valueOrNull ?? [],
                  catOpts: ref.watch(categoryOptionsProvider).valueOrNull ?? [],
                  etOpts: ref.watch(employmentTypeOptionsProvider).valueOrNull ?? [],
                  benefitOpts: ref.watch(benefitOptionsProvider).valueOrNull ?? [],
                  klOpts: ref.watch(koreanLevelOptionsProvider).valueOrNull ?? [],
                  wsOpts: ref.watch(workScheduleOptionsProvider).valueOrNull ?? [],
                  langOpts: ref.watch(languageOptionsProvider).valueOrNull ?? [],
                  siteOpts: ref.watch(siteOptionsProvider).valueOrNull ?? [],
                  countryOpts: ref.watch(countryOptionsProvider).valueOrNull ?? [],
                  s: s,
                ),
                  ],
                ),
              ),

              // 하단 버튼
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          analytics.filterReset();
                          notifier.reset();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFDDDDDD), width: 1.5),
                          ),
                          child: Text(s.reset,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray400)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
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
                          // 푸시 구독 업데이트
                          final langCode = ref.read(languageProvider);
                          if (filter.isEmpty) {
                            pushService.deleteSubscription();
                          } else {
                            pushService.upsertSubscription(
                              filter: filter,
                              langCode: langCode,
                            );
                          }
                          context.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.carrot,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _ShowResultsText(s: s),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(FilterState filter, FilterStateNotifier notifier, dynamic s) {
    switch (_selectedIndex) {
      case 0: // 비자 + 비자지원
        return _VisaListPanel(
          optionsAsync: ref.watch(visaOptionsProvider),
          selected: filter.visaIds,
          onToggle: notifier.toggleVisa,
          visaSponsorship: filter.visaSponsorship,
          onVisaSponsorshipChanged: notifier.setVisaSponsorship,
          s: s,
        );
      case 1: // 직종
        return _AsyncListPanel(
          optionsAsync: ref.watch(categoryOptionsProvider),
          selected: filter.categoryIds,
          onToggle: notifier.toggleCategory,
        );
      case 2: // 고용형태
        return _AsyncListPanel(
          optionsAsync: ref.watch(employmentTypeOptionsProvider),
          selected: filter.employmentTypeIds,
          onToggle: notifier.toggleEmploymentType,
        );
      case 3: // 지역
        return _RegionSelectPanel(
          key: _regionKey,
          ref: ref,
          filter: filter,
          notifier: notifier,
          langCode: ref.watch(languageProvider),
        );
      case 4: // 급여
        return _SalaryListPanel(
          filter: filter,
          notifier: notifier,
          s: s,
        );
      case 5: // 근무요일
        return _WorkScheduleListPanel(
          optionsAsync: ref.watch(workScheduleOptionsProvider),
          selected: filter.workScheduleIds,
          onToggle: notifier.toggleWorkSchedule,
        );
      case 6: // 한국어능력
        return _AsyncIntListPanel(
          optionsAsync: ref.watch(koreanLevelOptionsProvider),
          selected: filter.koreanLevelIds,
          onToggle: notifier.toggleKoreanLevel,
        );
      case 7: // 복리후생
        return _AsyncListPanel(
          optionsAsync: ref.watch(benefitOptionsProvider),
          selected: filter.benefitIds,
          onToggle: notifier.toggleBenefit,
        );
      case 8: // 국가
        return _AsyncListPanel(
          optionsAsync: ref.watch(countryOptionsProvider),
          selected: filter.countryIds,
          onToggle: notifier.toggleCountry,
        );
      case 9: // 채용사이트
        return _AsyncListPanel(
          optionsAsync: ref.watch(siteOptionsProvider),
          selected: filter.siteIds,
          onToggle: notifier.toggleSite,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  bool _hasSelection(FilterState f, int i) {
    switch (i) {
      case 0: return f.visaIds.isNotEmpty || f.visaSponsorship != null;
      case 1: return f.categoryIds.isNotEmpty;
      case 2: return f.employmentTypeIds.isNotEmpty;
      case 3: return f.regionIds.isNotEmpty;
      case 4: return f.salaryTypes.isNotEmpty || (f.salaryRange != null && f.salaryRange!.isNotEmpty);
      case 5: return f.workScheduleIds.isNotEmpty;
      case 6: return f.koreanLevelIds.isNotEmpty;
      case 7: return f.benefitIds.isNotEmpty;
      case 8: return f.countryIds.isNotEmpty;
      case 9: return f.siteIds.isNotEmpty;
      default: return false;
    }
  }

  int _selectionCount(FilterState f, int i) {
    switch (i) {
      case 0: return f.visaIds.length + (f.visaSponsorship != null ? 1 : 0);
      case 1: return f.categoryIds.length;
      case 2: return f.employmentTypeIds.length;
      case 3: {
        // 시/도 전체=1, 구/군 개별=구/군 수
        final allRegions = JobRepository.allRegionsCacheSync;
        if (allRegions == null || f.regionIds.isEmpty) return f.regionIds.isEmpty ? 0 : 1;
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
        for (final id in f.regionIds) {
          final r = allRegions.where((e) => e['id'] == id).firstOrNull;
          if (r != null) {
            final si = r['si_name'] as String;
            if (r['gu_name'] != null || !(siDoHasGuGun[si] ?? false)) {
              siDoGroups.putIfAbsent(si, () => []).add(id);
            }
          }
        }
        int count = 0;
        for (final entry in siDoGroups.entries) {
          final hasGuGun = siDoHasGuGun[entry.key] ?? false;
          final total = hasGuGun ? (siDoTotals[entry.key] ?? 0) : entry.value.length;
          count += entry.value.length >= total ? 1 : entry.value.length;
        }
        return count;
      }
      case 4: return f.salaryTypes.length + (f.salaryRange != null && f.salaryRange!.isNotEmpty ? 1 : 0);
      case 5: return f.workScheduleIds.length;
      case 6: return f.koreanLevelIds.length;
      case 7: return f.benefitIds.length;
      case 8: return f.countryIds.length;
      case 9: return f.siteIds.length;
      default: return 0;
    }
  }
}

class _ShowResultsText extends ConsumerWidget {
  final dynamic s;
  const _ShowResultsText({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(jobTotalCountProvider);
    return countAsync.when(
      data: (count) {
        final langCode = ref.watch(languageProvider);
        final formatted = count < 0 ? '...' : NumberFormat.decimalPattern(langCode).format(count);
        return Text(
          '${s.showResults} ($formatted)',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        );
      },
      loading: () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(s.showResults as String,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
      error: (_, __) => Text(
        s.showResults as String,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _SelectedFilterChips extends StatelessWidget {
  final FilterState filter;
  final FilterStateNotifier notifier;
  final List<FilterOption> visaOpts;
  final List<FilterOption> catOpts;
  final List<FilterOption> etOpts;
  final List<FilterOption> benefitOpts;
  final List<FilterOption> klOpts;
  final List<FilterOption> wsOpts;
  final List<FilterOption> langOpts;
  final List<FilterOption> siteOpts;
  final List<FilterOption> countryOpts;
  final dynamic s;

  const _SelectedFilterChips({
    required this.filter,
    required this.notifier,
    required this.visaOpts,
    required this.catOpts,
    required this.etOpts,
    required this.benefitOpts,
    required this.klOpts,
    required this.wsOpts,
    required this.langOpts,
    required this.siteOpts,
    required this.countryOpts,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <_ChipData>[];

    for (final id in filter.visaIds) {
      final opt = visaOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleVisa(id)));
    }
    for (final id in filter.categoryIds) {
      final opt = catOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleCategory(id)));
    }
    // 지역: 시/도 전체면 시/도명, 구/군 개별이면 구/군별 칩
    if (filter.regionIds.isNotEmpty) {
      final allRegions = JobRepository.allRegionsCacheSync;
      if (allRegions != null) {
        final langCode = s.locale;
        final siDoGroups = <String, List<int>>{};
        final siDoTotals = <String, int>{}; // 구/군 수 (gu_name != null만)
        final siDoHasGuGun = <String, bool>{}; // 구/군 존재 여부
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
            final hasGuGun = siDoHasGuGun[si] ?? false;
            // 구/군 있는 시/도 → gu_name null 제외 / 세종 등 → 포함
            if (r['gu_name'] != null || !hasGuGun) {
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
            // 시/도 전체 → 1개 칩 (gu_name=null 행 포함 모든 ID 제거)
            final allSiDoIds = allRegions
                .where((r) => r['si_name'] == si)
                .map((r) => r['id'] as int)
                .toSet();
            chips.add(_ChipData(
              RegionMapper.getLocalizedName(si, langCode),
              () { final u = Set<int>.from(filter.regionIds); u.removeAll(allSiDoIds); notifier.setRegionIds(u); },
            ));
          } else {
            // 구/군 개별 → 각각 칩
            for (final id in ids) {
              final r = allRegions.where((e) => e['id'] == id).firstOrNull;
              if (r != null && r['gu_name'] != null) {
                final gu = r['gu_name'] as String;
                final label = langCode == 'ko' ? gu : DistrictNames.getLocalizedGuName(gu, si, langCode);
                chips.add(_ChipData(label, () => notifier.toggleRegionId(id)));
              }
            }
          }
        }
      }
    }
    if (filter.salaryRange != null && filter.salaryRange!.isNotEmpty) {
      chips.add(_ChipData(filter.salaryRange!, () => notifier.setSalary(null)));
    }
    for (final id in filter.employmentTypeIds) {
      final opt = etOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleEmploymentType(id)));
    }
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
      chips.add(_ChipData(label, () => notifier.toggleSalaryType(st)));
    }
    for (final id in filter.workScheduleIds) {
      final opt = wsOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleWorkSchedule(id)));
    }
    for (final id in filter.koreanLevelIds) {
      final opt = klOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleKoreanLevel(id)));
    }
    for (final id in filter.benefitIds) {
      final opt = benefitOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleBenefit(id)));
    }
    if (filter.visaSponsorship != null) {
      chips.add(_ChipData(
        s.tabVisaSponsorship,
        () => notifier.setVisaSponsorship(null),
      ));
    }
    for (final id in filter.languageIds) {
      final opt = langOpts.where((o) => o.id == id.toString()).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleLanguage(id)));
    }
    for (final id in filter.countryIds) {
      final opt = countryOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleCountry(id)));
    }
    for (final id in filter.siteIds) {
      final opt = siteOpts.where((o) => o.id == id).firstOrNull;
      if (opt != null) chips.add(_ChipData(opt.label, () => notifier.toggleSite(id)));
    }


    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final chip = chips[i];
            return Container(
              padding: const EdgeInsets.only(left: 10, right: 6),
              decoration: BoxDecoration(
                color: AppColors.carrotLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD4B3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chip.label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.carrotDark)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: chip.onRemove,
                    child: const Icon(Icons.close, size: 14, color: AppColors.carrot),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final VoidCallback onRemove;
  const _ChipData(this.label, this.onRemove);
}

class _CatItem {
  final String label;
  final bool hasSelection;
  final int count;
  const _CatItem(this.label, this.hasSelection, [this.count = 0]);
}

// ── String ID 칩 패널 ──

// ── 지역 패널 (현재 위치 버튼 포함) ──

class _RegionSelectPanel extends StatefulWidget {
  final WidgetRef ref;
  final FilterState filter;
  final FilterStateNotifier notifier;
  final String langCode;

  const _RegionSelectPanel({
    super.key,
    required this.ref,
    required this.filter,
    required this.notifier,
    required this.langCode,
  });

  @override
  State<_RegionSelectPanel> createState() => _RegionSelectPanelState();
}

class _RegionSelectPanelState extends State<_RegionSelectPanel> {
  String? _selectedSiDo;
  double _siDoScrollOffset = 0;

  /// 선택된 regionIds에 포함된 시/도 목록
  Set<String> get _selectedSiDoSet {
    final allRegions = JobRepository.allRegionsCacheSync;
    if (allRegions == null || widget.filter.regionIds.isEmpty) return {};
    final result = <String>{};
    for (final id in widget.filter.regionIds) {
      final r = allRegions.where((e) => e['id'] == id).firstOrNull;
      if (r != null) result.add(r['si_name'] as String);
    }
    return result;
  }

  /// 구/군 선택 — 다중 시/도 합산
  void _selectGuGun(int id, String siDo) {
    widget.notifier.toggleRegionId(id);
  }

  Future<void> _toggleSiDoAll(String siDo) async {
    final repo = widget.ref.read(jobRepositoryProvider);
    final allIds = await repo.getRegionIdsForSiDo(siDo);
    final current = Set<int>.from(widget.filter.regionIds);
    if (allIds.every(current.contains)) {
      current.removeAll(allIds);
    } else {
      current.addAll(allIds);
    }
    widget.notifier.setRegionIds(current);
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSiDo == null) {
      return _buildSiDoList();
    }
    return _buildGuGunList(_selectedSiDo!);
  }

  Widget _buildSiDoList() {
    final siDoAsync = widget.ref.watch(siDoOptionsProvider);
    final lang = widget.langCode;
    return siDoAsync.when(
      data: (options) {
        final selectedSiDos = _selectedSiDoSet;
        final controller = ScrollController(initialScrollOffset: _siDoScrollOffset);
        controller.addListener(() => _siDoScrollOffset = controller.offset);
        return ListView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 48),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            final isCurrent = selectedSiDos.contains(opt.id);
            final label = lang == 'ko'
                ? opt.id
                : '${RegionMapper.getLocalizedName(opt.id, 'en')} (${opt.id})';

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final repo = widget.ref.read(jobRepositoryProvider);
                final guGuns = await repo.getGuGunOptions(opt.id, lang);
                if (guGuns.isEmpty) {
                  _toggleSiDoAll(opt.id);
                } else {
                  setState(() => _selectedSiDo = opt.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.gray100, width: 0.5)),
                ),
                child: Row(
                  children: [
                    if (isCurrent)
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.carrot),
                      ),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isCurrent ? AppColors.carrot : AppColors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.gray300),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGuGunList(String siDo) {
    final guGunAsync = widget.ref.watch(guGunOptionsProvider(siDo));
    final lang = widget.langCode;
    return guGunAsync.when(
      data: (options) {
        return Column(
          children: [
            // 뒤로가기 (고정)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedSiDo = null),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.carrot),
                    const SizedBox(width: 4),
                    Text(
                      lang == 'ko' ? siDo : '${RegionMapper.getLocalizedName(siDo, 'en')} ($siDo)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.carrot),
                    ),
                  ],
                ),
              ),
            ),
            // 스크롤 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 48),
                itemCount: options.length + 1, // All Districts + 구/군
                itemBuilder: (context, index) {
            if (index == 0) {
              // All Districts
              final allSelected = _isSiDoAllSelected(siDo);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleSiDoAll(siDo),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.gray100, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lang == 'ko' ? '전체' : 'All Districts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: allSelected ? AppColors.carrot : AppColors.black,
                          ),
                        ),
                      ),
                      Icon(
                        allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 20,
                        color: allSelected ? AppColors.carrot : AppColors.gray300,
                      ),
                    ],
                  ),
                ),
              );
            }

            final opt = options[index - 1];
            final id = int.parse(opt.id);
            final isSelected = widget.filter.regionIds.contains(id);
            final guLabel = lang == 'ko'
                ? opt.label
                : '${DistrictNames.getLocalizedGuName(opt.label, siDo, 'en')} (${opt.label})';

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectGuGun(id, siDo),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.gray100, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        guLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isSelected ? AppColors.carrot : AppColors.black,
                        ),
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 20,
                      color: isSelected ? AppColors.carrot : AppColors.gray300,
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
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  bool _isSiDoAllSelected(String siDo) {
    // 해당 시/도의 모든 구/군 id가 선택되어 있는지 확인
    final guGunAsync = widget.ref.read(guGunOptionsProvider(siDo));
    final options = guGunAsync.valueOrNull;
    if (options == null || options.isEmpty) return false;
    return options.every((opt) => widget.filter.regionIds.contains(int.parse(opt.id)));
  }

}

// ── 비자 패널 (리스트 형식, 인기 비자 상단 + 비자지원 토글 포함) ──

class _VisaListPanel extends StatelessWidget {
  final AsyncValue<List<FilterOption>> optionsAsync;
  final Set<String> selected;
  final void Function(String) onToggle;
  final bool? visaSponsorship;
  final void Function(bool?) onVisaSponsorshipChanged;
  final dynamic s;

  const _VisaListPanel({
    required this.optionsAsync,
    required this.selected,
    required this.onToggle,
    required this.visaSponsorship,
    required this.onVisaSponsorshipChanged,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return optionsAsync.when(
      data: (options) {
        final popular = <FilterOption>[];
        final rest = <FilterOption>[];
        for (final opt in options) {
          if (JobRepository.popularVisaCodes.contains(opt.label)) {
            popular.add(opt);
          } else {
            rest.add(opt);
          }
        }
        final allItems = [...popular, ...rest];

        // +2 for visa sponsorship header + Yes row
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 48),
          itemCount: allItems.length + 2,
          itemBuilder: (context, index) {
            if (index < allItems.length) {
              final opt = allItems[index];
              final isPopular = index < popular.length;
              final isSelected = selected.contains(opt.id);
              final label = isPopular ? '\u{1F525} ${opt.label}' : opt.label;
              return _filterListRow(
                label: label,
                isSelected: isSelected,
                onTap: () => onToggle(opt.id),
              );
            }
            // Visa sponsorship section header
            if (index == allItems.length) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text(
                  s.tabVisaSponsorship as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.carrot,
                  ),
                ),
              );
            }
            // Yes
            return _filterListRow(
              label: 'Yes',
              isSelected: visaSponsorship == true,
              onTap: () => onVisaSponsorshipChanged(visaSponsorship == true ? null : true),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (e, _) => const ErrorRetry(onRetry: null),
    );
  }
}

// ── 근무요일 리스트 패널 (플랫 리스트) ──

class _WorkScheduleListPanel extends StatelessWidget {
  final AsyncValue<List<FilterOption>> optionsAsync;
  final Set<int> selected;
  final void Function(int) onToggle;

  const _WorkScheduleListPanel({
    required this.optionsAsync,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return optionsAsync.when(
      data: (options) {
        // 3그룹 분류 후 플랫 리스트로 합침
        final group1 = <FilterOption>[]; // 협의, 주말
        final group2 = <FilterOption>[]; // 월~금, 월~토, 월~일
        final group3 = <FilterOption>[]; // 주N일
        final others = <FilterOption>[];

        for (final opt in options) {
          final l = opt.label.toLowerCase().replaceAll(' ', '');
          if (_isNegotiableOrWeekend(l)) {
            group1.add(opt);
          } else if (_isWeekdayRange(l)) {
            group2.add(opt);
          } else if (_isDayCount(l)) {
            group3.add(opt);
          } else {
            others.add(opt);
          }
        }

        // 주N일은 큰 수부터
        group3.sort((a, b) {
          final na = _extractNumber(a.label);
          final nb = _extractNumber(b.label);
          return nb.compareTo(na);
        });

        final allItems = [...group1, ...group2, ...group3, ...others];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 48),
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            final opt = allItems[index];
            final id = int.tryParse(opt.id) ?? 0;
            final isSelected = selected.contains(id);
            return _filterListRow(
              label: opt.label,
              isSelected: isSelected,
              onTap: () => onToggle(id),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (e, _) => const ErrorRetry(onRetry: null),
    );
  }

  bool _isNegotiableOrWeekend(String l) {
    return l.contains('협의') || l.contains('negotia') ||
        l.contains('주말') || l.contains('weekend');
  }

  bool _isWeekdayRange(String l) {
    return l.contains('월~') || l.contains('월-') ||
        l.contains('mon') || l.contains('weekday');
  }

  bool _isDayCount(String l) {
    return RegExp(r'(주|week)\s*\d').hasMatch(l) ||
        RegExp(r'\d\s*(일|day)').hasMatch(l);
  }

  int _extractNumber(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return match != null ? int.parse(match.group(0)!) : 0;
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 멀티 섹션 패널 (오른쪽 패널에 여러 필터를 섹션별로 표시) ──

class _SectionData {
  final String title;
  final Widget child;
  const _SectionData({required this.title, required this.child});
}

class _MultiSectionPanel extends StatelessWidget {
  final List<_SectionData> sections;
  const _MultiSectionPanel({required this.sections});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (sections[i].title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  sections[i].title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.carrot,
                  ),
                ),
              ),
            sections[i].child,
          ],
        ],
      ),
    );
  }
}

class _AsyncChipPanel extends StatelessWidget {
  final AsyncValue<List<FilterOption>> optionsAsync;
  final Set<String> selected;
  final void Function(String) onToggle;
  const _AsyncChipPanel({
    required this.optionsAsync,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return optionsAsync.when(
      data: (options) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((opt) {
            return _Chip(
              label: opt.label,
              isSelected: selected.contains(opt.id),
              onTap: () => onToggle(opt.id),
            );
          }).toList(),
        ),
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (e, _) => const ErrorRetry(onRetry: null),
    );
  }
}

// ── String ID 리스트 패널 ──

class _AsyncListPanel extends StatelessWidget {
  final AsyncValue<List<FilterOption>> optionsAsync;
  final Set<String> selected;
  final void Function(String) onToggle;
  const _AsyncListPanel({
    required this.optionsAsync,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return optionsAsync.when(
      data: (options) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 48),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final opt = options[index];
          final isSelected = selected.contains(opt.id);
          return _filterListRow(
            label: opt.label,
            isSelected: isSelected,
            onTap: () => onToggle(opt.id),
          );
        },
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (e, _) => const ErrorRetry(onRetry: null),
    );
  }
}

// ── int ID 칩 패널 ──

class _AsyncIntChipPanel extends StatelessWidget {
  final AsyncValue<List<FilterOption>> optionsAsync;
  final Set<int> selected;
  final void Function(int) onToggle;
  const _AsyncIntChipPanel({
    required this.optionsAsync,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return optionsAsync.when(
      data: (options) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((opt) {
            final id = int.tryParse(opt.id) ?? 0;
            return _Chip(
              label: opt.label,
              isSelected: selected.contains(id),
              onTap: () => onToggle(id),
            );
          }).toList(),
        ),
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (e, _) => const ErrorRetry(onRetry: null),
    );
  }
}

// ── int ID 리스트 패널 ──

class _AsyncIntListPanel extends StatelessWidget {
  final AsyncValue<List<FilterOption>> optionsAsync;
  final Set<int> selected;
  final void Function(int) onToggle;
  const _AsyncIntListPanel({
    required this.optionsAsync,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return optionsAsync.when(
      data: (options) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 48),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final opt = options[index];
          final id = int.tryParse(opt.id) ?? 0;
          final isSelected = selected.contains(id);
          return _filterListRow(
            label: opt.label,
            isSelected: isSelected,
            onTap: () => onToggle(id),
          );
        },
      ),
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (e, _) => const ErrorRetry(onRetry: null),
    );
  }
}

// ── 하드코딩 칩 패널 (급여) ──

class _UnifiedSalaryPanel extends StatelessWidget {
  final FilterState filter;
  final FilterStateNotifier notifier;
  final dynamic s;

  const _UnifiedSalaryPanel({
    required this.filter,
    required this.notifier,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      FilterOption(id: 'hourly', label: s.salaryHourly as String),
      FilterOption(id: 'daily', label: s.salaryDaily as String),
      FilterOption(id: 'weekly', label: s.salaryWeekly as String),
      FilterOption(id: 'monthly', label: s.salaryMonthly as String),
      FilterOption(id: 'annual', label: s.salaryAnnual as String),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: options.map((opt) => _Chip(
          label: opt.label,
          isSelected: filter.salaryTypes.contains(opt.id),
          onTap: () => notifier.toggleSalaryType(opt.id),
        )).toList(),
      ),
    );
  }
}

// ── 급여 리스트 패널 ──

class _SalaryListPanel extends StatelessWidget {
  final FilterState filter;
  final FilterStateNotifier notifier;
  final dynamic s;

  const _SalaryListPanel({
    required this.filter,
    required this.notifier,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      FilterOption(id: 'hourly', label: s.salaryHourly as String),
      FilterOption(id: 'daily', label: s.salaryDaily as String),
      FilterOption(id: 'weekly', label: s.salaryWeekly as String),
      FilterOption(id: 'monthly', label: s.salaryMonthly as String),
      FilterOption(id: 'annual', label: s.salaryAnnual as String),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 48),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final opt = options[index];
        final isSelected = filter.salaryTypes.contains(opt.id);
        return _filterListRow(
          label: opt.label,
          isSelected: isSelected,
          onTap: () => notifier.toggleSalaryType(opt.id),
        );
      },
    );
  }
}

class _SalaryPanel extends StatefulWidget {
  final FilterState filter;
  final FilterStateNotifier notifier;
  final dynamic s;

  const _SalaryPanel({
    required this.filter,
    required this.notifier,
    required this.s,
  });

  @override
  State<_SalaryPanel> createState() => _SalaryPanelState();
}

class _SalaryPanelState extends State<_SalaryPanel> {
  String _selectedTab = 'monthly';

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final types = [
      _SalaryTypeItem('monthly', s.salaryMonthly as String),
      _SalaryTypeItem('hourly', s.salaryHourly as String),
      _SalaryTypeItem('annual', s.salaryAnnual as String),
    ];

    List<String> rangeOptions;
    if (_selectedTab == 'hourly') {
      rangeOptions = s.salaryHourlyOptions as List<String>;
    } else if (_selectedTab == 'annual') {
      rangeOptions = s.salaryAnnualOptions as List<String>;
    } else {
      rangeOptions = s.salaryMonthlyOptions as List<String>;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 급여 타입 탭 (로컬 상태, 서버 통신 없음)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: types.map((t) {
                final isSelected = _selectedTab == t.code;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = t.code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                            : null,
                      ),
                      child: Text(
                        t.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.carrot : AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          // 급여 범위 선택
          Wrap(
            spacing: 8, runSpacing: 8,
            children: rangeOptions.map((item) {
              final isSelected = widget.filter.salaryRange == item;
              return _Chip(
                label: item,
                isSelected: isSelected,
                onTap: () => widget.notifier.setSalary(
                    widget.filter.salaryRange == item ? null : item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SalaryTypeItem {
  final String code;
  final String label;
  const _SalaryTypeItem(this.code, this.label);
}

class _StringChipPanel extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _StringChipPanel({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: items.map((item) => _Chip(
          label: item,
          isSelected: selected.contains(item),
          onTap: () => onToggle(item),
        )).toList(),
      ),
    );
  }
}

// ── FilterOption 칩 패널 (id로 선택, label 표시) ──

class _OptionChipPanel extends StatelessWidget {
  final List<FilterOption> options;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _OptionChipPanel({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: options.map((opt) => _Chip(
          label: opt.label,
          isSelected: selected.contains(opt.id),
          onTap: () => onToggle(opt.id),
        )).toList(),
      ),
    );
  }
}

// ── 성별 패널 ──

class _GenderPanel extends StatelessWidget {
  final String? selected;
  final void Function(String?) onChanged;
  final dynamic s;

  const _GenderPanel({
    required this.selected,
    required this.onChanged,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('any', s.genderAny),
      ('male', s.genderMale),
      ('female', s.genderFemale),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: options.map((opt) => _Chip(
          label: opt.$2 as String,
          isSelected: selected == opt.$1,
          onTap: () => onChanged(selected == opt.$1 ? null : opt.$1),
        )).toList(),
      ),
    );
  }
}

// ── get_filter_counts 기반 동적 칩 패널 ──

class _FilterCountChipPanel extends ConsumerWidget {
  final String countsKey;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _FilterCountChipPanel({
    required this.countsKey,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(filterCountsProvider);
    return countsAsync.when(
      data: (counts) {
        final map = countsKey == 'education' ? counts.education
            : countsKey == 'experience' ? counts.experience
            : <String, int>{};
        if (map.isEmpty) {
          return const Center(child: Text('No options'));
        }
        final sorted = map.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: sorted.map((e) => _Chip(
              label: '${e.key} (${e.value})',
              isSelected: selected.contains(e.key),
              onTap: () => onToggle(e.key),
            )).toList(),
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (e, _) => const ErrorRetry(onRetry: null),
    );
  }
}

// ── Boolean 토글 패널 ──

class _TogglePanel extends StatelessWidget {
  final bool? value;
  final void Function(bool?) onChanged;

  const _TogglePanel({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _Chip(
            label: 'Yes',
            isSelected: value == true,
            onTap: () => onChanged(value == true ? null : true),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'No',
            isSelected: value == false,
            onTap: () => onChanged(value == false ? null : false),
          ),
        ],
      ),
    );
  }
}

// ── 공통 리스트 행 (모든 리스트 패널에서 사용) ──

Widget _filterListRow({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isSelected ? AppColors.carrot : AppColors.black,
              ),
            ),
          ),
          Icon(
            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: isSelected ? AppColors.carrot : AppColors.gray300,
          ),
        ],
      ),
    ),
  );
}

// ── 공통 칩 ──

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.carrotLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.carrot : AppColors.gray100,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.carrotDark : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}
