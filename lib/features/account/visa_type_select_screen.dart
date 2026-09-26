import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/sheet_handle.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/filter_state.dart';
import '../../providers/job_provider.dart';

/// 단일선택 바텀시트. (전체화면이었을 때 시각적으로 부실하다는 피드백으로
/// 바텀시트로 전환, 2026-09-20) — 자주 찾는 비자 구분 없이 전체를 알파벳+
/// 숫자 자연정렬한 단일 목록으로 표시 (2026-09-20 피드백).
final _visaCodeRegex = RegExp(r'^([A-Za-z]+)-?(\d+)?$');

/// "D-2" < "D-10"처럼 접두 알파벳은 알파벳순, 뒤 숫자는 숫자 크기순으로 비교.
/// 형식이 안 맞는 코드(예: ANY)는 일반 문자열 비교로 폴백.
int _visaLabelCompare(String a, String b) {
  final ma = _visaCodeRegex.firstMatch(a);
  final mb = _visaCodeRegex.firstMatch(b);
  if (ma != null && mb != null) {
    final prefixCompare = ma.group(1)!.compareTo(mb.group(1)!);
    if (prefixCompare != 0) return prefixCompare;
    final na = int.tryParse(ma.group(2) ?? '');
    final nb = int.tryParse(mb.group(2) ?? '');
    if (na != null && nb != null) return na.compareTo(nb);
  }
  return a.compareTo(b);
}

Future<({String code, String label})?> showVisaTypeSheet(
  BuildContext context, {
  String? currentCode,
}) {
  return showModalBottomSheet<({String code, String label})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _VisaTypeSheet(currentCode: currentCode),
  );
}

class _VisaTypeSheet extends ConsumerStatefulWidget {
  final String? currentCode;

  const _VisaTypeSheet({this.currentCode});

  @override
  ConsumerState<_VisaTypeSheet> createState() => _VisaTypeSheetState();
}

class _VisaTypeSheetState extends ConsumerState<_VisaTypeSheet> {
  static const _kHeaderH = 6.0;
  static const _kRowH = 46.0;

  final _selectedKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _didScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedOnce(List<FilterOption> all) {
    if (_didScroll || widget.currentCode == null) return;
    _didScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 화면 밖 항목은 아직 레이아웃이 안 돼 있어 ensureVisible이 실패할 수 있음
      // (국적선택 화면과 동일 원인, 2026-09-20) — 인덱스 기반 대략 위치로 먼저
      // 점프한 뒤 ensureVisible로 정확히 보정.
      final index = all.indexWhere((o) => o.label == widget.currentCode);
      if (index < 0) return;
      final offset = _kHeaderH + index * _kRowH;

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
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final optionsAsync = ref.watch(visaOptionsProvider);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Column(
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 10),
                  Text(
                    s.accountFieldVisaType,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.gray100),
            Flexible(
              child: optionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.carrot),
                  ),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Icon(Icons.error_outline, color: AppColors.gray300),
                  ),
                ),
                data: (options) {
                  final sorted = [...options]
                    ..sort((a, b) => _visaLabelCompare(a.label, b.label));
                  _scrollToSelectedOnce(sorted);
                  return ListView(
                    controller: _scrollController,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12, top: 6),
                    children: sorted.map((o) => _visaTile(context, o)).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visaTile(BuildContext context, FilterOption option) {
    final selected = option.label == widget.currentCode;
    return GestureDetector(
      key: selected ? _selectedKey : null,
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          Navigator.of(context).pop((code: option.label, label: option.label)),
      child: Container(
        color: selected ? AppColors.carrotLight : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
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
