import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/filter_state.dart';
import '../../providers/job_provider.dart';
import '../../data/services/analytics_service.dart';
import '../../data/repositories/job_repository.dart';

class VisaSelectScreen extends ConsumerStatefulWidget {
  const VisaSelectScreen({super.key});

  @override
  ConsumerState<VisaSelectScreen> createState() => _VisaSelectScreenState();
}

class _VisaSelectScreenState extends ConsumerState<VisaSelectScreen> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    analytics.screenView('visa_select');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final visaOptsAsync = ref.watch(visaOptionsProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.black),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      s.selectVisa,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 비자 목록
              Expanded(
                child: visaOptsAsync.when(
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
                    // 나머지를 알파벳 그룹별로
                    final groups = <String, List<FilterOption>>{};
                    for (final opt in rest) {
                      final code = opt.label;
                      String prefix;
                      if (code.startsWith('C')) {
                        prefix = 'C';
                      } else if (code.startsWith('G') || code.startsWith('H')) {
                        prefix = 'GH';
                      } else {
                        prefix = code[0];
                      }
                      groups.putIfAbsent(prefix, () => []).add(opt);
                    }

                    Widget buildChip(FilterOption opt, {bool showFire = false}) {
                      final isSelected = _selectedIds.contains(opt.id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          isSelected ? _selectedIds.remove(opt.id) : _selectedIds.add(opt.id);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.carrotLight : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.carrot : AppColors.gray100,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showFire) ...[
                                const Text('🔥', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.carrotDark : AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 인기 비자 상단
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: popular.map((opt) => buildChip(opt, showFire: true)).toList(),
                            ),
                          ),
                          // 나머지 한 덩어리
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: rest.map((opt) => buildChip(opt)).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.carrot)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),

              // 하단 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          analytics.visaSelected(_selectedIds.toList());
                          analytics.log('onboarding_visa', {
                            'action': _selectedIds.isEmpty ? 'skip' : 'select',
                            'count': _selectedIds.length,
                          });
                          // 선택된 비자를 필터에 저장
                          if (_selectedIds.isNotEmpty) {
                            final notifier =
                                ref.read(filterStateProvider.notifier);
                            final current = ref.read(filterStateProvider);
                            notifier.setState(
                                current.copyWith(visaIds: _selectedIds));
                          }
                          context.push('/onboarding/location');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          decoration: BoxDecoration(
                            color: _selectedIds.isNotEmpty ? AppColors.carrot : Colors.transparent,
                            border: _selectedIds.isEmpty ? Border.all(color: AppColors.carrot) : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _selectedIds.isNotEmpty ? s.next : s.skip,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _selectedIds.isNotEmpty ? Colors.white : AppColors.carrot,
                            ),
                          ),
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
}
