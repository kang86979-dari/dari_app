import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../core/utils/region_mapper.dart';
import '../../providers/job_provider.dart';
import '../../providers/language_provider.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/push_service.dart';

class LocationSelectScreen extends ConsumerStatefulWidget {
  const LocationSelectScreen({super.key});

  @override
  ConsumerState<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends ConsumerState<LocationSelectScreen> {
  final Set<String> _selectedSiDos = {};
  bool _tracked = false;

  Future<void> _finish() async {
    if (_selectedSiDos.isEmpty) {
      analytics.locationPermission(false);
      analytics.log('onboarding_location', {'action': 'skip', 'count': 0});
    } else {
      analytics.locationPermission(true);
      analytics.log('onboarding_location', {
        'action': 'select',
        'count': _selectedSiDos.length,
        'regions': _selectedSiDos.join(', '),
      });
      final repo = ref.read(jobRepositoryProvider);
      final notifier = ref.read(filterStateProvider.notifier);
      final allIds = <int>{};
      for (final siDo in _selectedSiDos) {
        final ids = await repo.getRegionIdsForSiDo(siDo);
        allIds.addAll(ids);
      }
      notifier.setRegionIds(allIds);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);

    // 온보딩에서 필터 설정했으면 푸시 구독 등록
    final filter = ref.read(filterStateProvider);
    if (!filter.isEmpty) {
      final langCode = ref.read(languageProvider);
      await pushService.upsertSubscription(filter: filter, langCode: langCode);
    }

    if (mounted) context.go('/home');
  }

  String _siDoLabel(String siName, String langCode) {
    if (langCode == 'ko') return siName;
    final en = RegionMapper.getLocalizedName(siName, 'en');
    return '$en ($siName)';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);

    if (!_tracked) {
      _tracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        analytics.screenView('location_select');
      });
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 24, 14),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.black),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      s.locationSelectTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildSiDoList(langCode)),
              // 하단 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _finish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: AppColors.carrot,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        s.getStarted,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSiDoList(String langCode) {
    final siDoAsync = ref.watch(siDoOptionsProvider);
    return siDoAsync.when(
      data: (options) => ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, index) {
          final opt = options[index];
          final isSelected = _selectedSiDos.contains(opt.id);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedSiDos.remove(opt.id);
                } else {
                  _selectedSiDos.add(opt.id);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.gray100, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _siDoLabel(opt.id, langCode),
                      style: TextStyle(
                        fontSize: 15,
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
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.carrot)),
      error: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.carrot)),
    );
  }
}
