import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../core/utils/flag_emoji.dart';
import '../../data/constants/world_countries.dart';
import '../../providers/language_provider.dart';
import 'widgets/account_app_bar.dart';

/// 한국에 거주하는 외국인 다수를 차지하는 국가(=앱이 이미 16개 언어로 번역해 둔 국가) 우선 노출.
/// 이 코드들은 app_strings.countryName()이 다국어로 커버하는 것과 동일 세트.
const _priorityCodes = {
  'VN',
  'TH',
  'KH',
  'NP',
  'UZ',
  'PH',
  'CN',
  'ID',
  'MM',
  'MN',
  'LK',
  'PK',
  'BD',
  'KG',
  'TJ',
  'TM',
  'IN',
  'JP',
  'RU',
  'KZ',
};

class NationalitySelectScreen extends ConsumerStatefulWidget {
  final String? currentCode;

  const NationalitySelectScreen({super.key, this.currentCode});

  @override
  ConsumerState<NationalitySelectScreen> createState() =>
      _NationalitySelectScreenState();
}

class _NationalitySelectScreenState
    extends ConsumerState<NationalitySelectScreen> {
  static const _kHeaderH = 40.0;
  static const _kRowH = 50.0;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _selectedKey = GlobalKey();
  String _query = '';

  String _labelFor(String code, String en, String ko) {
    final s = ref.read(stringsProvider);
    final langCode = ref.read(languageProvider);
    if (_priorityCodes.contains(code)) return s.countryName(code);
    return langCode == 'ko' ? ko : en;
  }

  @override
  void initState() {
    super.initState();
    final code = widget.currentCode;
    if (code == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final all = worldCountries
          .map((c) => (code: c.$1, label: _labelFor(c.$1, c.$2, c.$3)))
          .toList();
      final priority =
          all.where((c) => _priorityCodes.contains(c.code)).toList()
            ..sort((a, b) => a.label.compareTo(b.label));
      final rest = all.where((c) => !_priorityCodes.contains(c.code)).toList()
        ..sort((a, b) => a.label.compareTo(b.label));

      // 화면 밖 항목은 아직 레이아웃이 안 돼 있어 ensureVisible이 바로 실패함
      // (2026-09-20 실기기 확인) — 인덱스 기반으로 대략적인 위치까지 먼저 점프한 뒤
      // 그 근방이 레이아웃되면 ensureVisible로 정확히 보정하는 2단계 방식.
      double offset;
      final priIndex = priority.indexWhere((c) => c.code == code);
      if (priIndex >= 0) {
        offset = _kHeaderH + priIndex * _kRowH;
      } else {
        final restIndex = rest.indexWhere((c) => c.code == code);
        if (restIndex < 0) return;
        offset =
            _kHeaderH +
            priority.length * _kRowH +
            _kHeaderH +
            restIndex * _kRowH;
      }

      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(offset.clamp(0, maxScroll));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _selectedKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.3,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    ref.watch(languageProvider);

    final all = worldCountries
        .map((c) => (code: c.$1, label: _labelFor(c.$1, c.$2, c.$3)))
        .toList();

    final query = _query.toLowerCase();
    final filtered = query.isEmpty
        ? all
        : all.where((c) => c.label.toLowerCase().contains(query)).toList();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AccountAppBar(title: s.accountFieldNationality),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: s.accountNationalitySearchHint,
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.gray400,
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (query.isNotEmpty) {
                      final sorted = [...filtered]
                        ..sort((a, b) => a.label.compareTo(b.label));
                      return _buildList(sorted);
                    }

                    final priority =
                        filtered
                            .where((c) => _priorityCodes.contains(c.code))
                            .toList()
                          ..sort((a, b) => a.label.compareTo(b.label));
                    final rest =
                        filtered
                            .where((c) => !_priorityCodes.contains(c.code))
                            .toList()
                          ..sort((a, b) => a.label.compareTo(b.label));

                    return ListView(
                      controller: _scrollController,
                      children: [
                        _sectionHeader(s.accountNationalityPriority),
                        ...priority.map((c) => _countryTile(c.code, c.label)),
                        _sectionHeader(s.accountNationalityAll),
                        ...rest.map((c) => _countryTile(c.code, c.label)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<({String code, String label})> items) {
    return ListView(
      children: items.map((c) => _countryTile(c.code, c.label)).toList(),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.gray400,
      ),
    ),
  );

  Widget _countryTile(String code, String label) {
    final selected = code == widget.currentCode;
    return GestureDetector(
      key: selected ? _selectedKey : null,
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop((code: code, label: label)),
      child: Container(
        color: selected ? AppColors.carrotLight : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Text(flagEmoji(code), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14.5, color: AppColors.black),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: AppColors.carrot),
          ],
        ),
      ),
    );
  }
}
