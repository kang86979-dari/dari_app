import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/district_names.dart';
import '../../../core/utils/region_mapper.dart';

/// 공용 리스트 픽커 바텀시트 — 한글 원본 값 반환, [display]로 표기만 변환.
/// 읍면동 선택(사이트에서 읽은 목록)에도 재사용.
Future<String?> showKhireListPicker(
  BuildContext context, {
  required String title,
  required List<String> items,
  String? selected,
  String Function(String)? display,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black)),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.gray50),
                itemBuilder: (_, i) {
                  final isSel = items[i] == selected;
                  return ListTile(
                    dense: true,
                    title: Text(display?.call(items[i]) ?? items[i],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? AppColors.carrot : AppColors.black,
                        )),
                    trailing: isSel
                        ? const Icon(Icons.check,
                            size: 18, color: AppColors.carrot)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(items[i]),
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

/// JIT 시트 결과 — 시/도·시군구·읍면동 한 팝업에서 전부 선택(2026-10-04 확정).
class KhireJitResult {
  final String sido;
  final String? sigungu;
  final String? dong;
  const KhireJitResult({required this.sido, this.sigungu, this.dong});
}

/// TalkApply 폼에 주소가 비어 있을 때만 띄우는 주소 선택 시트.
/// 시/도 → 시군구 → 읍면동 3단 리스트. 시군구를 고르는 순간 [loadDongs]로
/// 뒤의 페이지에 즉시 주입해 사이트가 만든 동 목록을 읽어와 채운다.
Future<KhireJitResult?> showKhireJitSheet(
  BuildContext context, {
  required String langCode,
  required List<Map<String, dynamic>> regions,
  required Future<List<String>> Function(String sido, String? sigungu)
      loadDongs,
  String? defaultSido,
  String? defaultSigungu,
}) {
  return showModalBottomSheet<KhireJitResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _KhireJitSheet(
      langCode: langCode,
      regions: regions,
      loadDongs: loadDongs,
      defaultSido: defaultSido,
      defaultSigungu: defaultSigungu,
    ),
  );
}

class _KhireJitSheet extends StatefulWidget {
  final String langCode;
  final List<Map<String, dynamic>> regions;
  final Future<List<String>> Function(String, String?) loadDongs;
  final String? defaultSido;
  final String? defaultSigungu;
  const _KhireJitSheet({
    required this.langCode,
    required this.regions,
    required this.loadDongs,
    this.defaultSido,
    this.defaultSigungu,
  });

  @override
  State<_KhireJitSheet> createState() => _KhireJitSheetState();
}

class _KhireJitSheetState extends State<_KhireJitSheet> {
  // 필터에 지역이 설정돼 있으면 그걸 기본 선택(2026-10-04 확정).
  late String? _sido = widget.defaultSido;
  late String? _sigungu = widget.defaultSigungu;
  String? _dong;
  List<String> _dongs = [];
  bool _loadingDongs = false;

  @override
  void initState() {
    super.initState();
    // 기본값(프로필/필터)으로 시·구가 이미 선택돼 있으면 동 목록 미리 로드.
    if (_sido != null && _sigungu != null) _fetchDongs();
  }

  /// 시군구 확정 시점에 페이지에 주입 → 사이트가 만든 동 목록을 읽어온다.
  Future<void> _fetchDongs() async {
    if (_sido == null) return;
    setState(() {
      _loadingDongs = true;
      _dongs = [];
      _dong = null;
    });
    final list = await widget.loadDongs(_sido!, _sigungu);
    if (!mounted) return;
    setState(() {
      _dongs = list;
      _loadingDongs = false;
    });
  }

  /// 표시용 — 앱 언어가 ko가 아니면 "영어 (한글)" 병기(2026-10-04 확정).
  /// 내부 값·주입은 항상 한글 원본.
  String _sidoLabel(String si) {
    if (widget.langCode == 'ko') return si;
    final en = RegionMapper.getLocalizedName(si, widget.langCode);
    return en == si ? si : '$en ($si)';
  }

  String _guLabel(String gu) {
    if (widget.langCode == 'ko') return gu;
    final en =
        DistrictNames.getLocalizedGuName(gu, _sido ?? '', widget.langCode);
    return en == gu ? gu : '$en ($gu)';
  }

  List<String> get _sidoList {
    final seen = <String>{};
    final out = <String>[];
    for (final r in widget.regions) {
      final si = r['si_name'] as String?;
      if (si != null && seen.add(si)) out.add(si);
    }
    return out;
  }

  List<String> _sigunguList(String sido) {
    final out = <String>[];
    for (final r in widget.regions) {
      if (r['si_name'] == sido) {
        final gu = r['gu_name'] as String?;
        if (gu != null && gu.isNotEmpty) out.add(gu);
      }
    }
    return out;
  }

  Future<void> _pickFromList({
    required String title,
    required List<String> items,
    required String? selected,
    required void Function(String) onPicked,
    String Function(String)? display,
  }) async {
    final picked = await showKhireListPicker(
      context,
      title: title,
      items: items,
      selected: selected,
      display: display,
    );
    if (picked != null) onPicked(picked);
  }

  bool get _canSubmit =>
      _sido != null &&
      _sigungu != null &&
      (_dong != null || (_dongs.isEmpty && !_loadingDongs));

  void _submit() {
    if (!_canSubmit) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
        KhireJitResult(sido: _sido!, sigungu: _sigungu, dong: _dong));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(widget.langCode);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(s.smsAddressLabel,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black)),
            const SizedBox(height: 12),
            _SelectRow(
              value: _sido == null ? null : _sidoLabel(_sido!),
              hint: '시/도',
              onTap: () => _pickFromList(
                title: '시/도',
                items: _sidoList,
                selected: _sido,
                display: _sidoLabel,
                onPicked: (v) {
                  setState(() {
                    _sido = v;
                    _sigungu = null; // 상위 변경 시 하위 초기화
                    _dong = null;
                    _dongs = [];
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            _SelectRow(
              value: _sigungu == null ? null : _guLabel(_sigungu!),
              hint: '시/군/구',
              enabled: _sido != null,
              onTap: _sido == null
                  ? null
                  : () => _pickFromList(
                        title: '시/군/구',
                        items: _sigunguList(_sido!),
                        selected: _sigungu,
                        display: _guLabel,
                        onPicked: (v) {
                          setState(() => _sigungu = v);
                          _fetchDongs(); // 페이지 주입 → 동 목록 로드
                        },
                      ),
            ),
            const SizedBox(height: 8),
            // 읍/면/동 — 시군구 선택 시 페이지에서 읽어온 목록(한글).
            _SelectRow(
              value: _dong,
              hint: _loadingDongs ? '...' : '읍/면/동',
              enabled: _dongs.isNotEmpty,
              onTap: _dongs.isEmpty
                  ? null
                  : () => _pickFromList(
                        title: '읍/면/동',
                        items: _dongs,
                        selected: _dong,
                        onPicked: (v) => setState(() => _dong = v),
                      ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: !_canSubmit ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.carrot,
                  disabledBackgroundColor: AppColors.gray200,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(s.confirm,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final String? value;
  final String hint;
  final bool enabled;
  final VoidCallback? onTap;
  const _SelectRow({
    required this.value,
    required this.hint,
    this.enabled = true,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.gray50 : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? hint,
              style: TextStyle(
                fontSize: 14,
                fontWeight: value != null ? FontWeight.w700 : FontWeight.w500,
                color: value != null ? AppColors.black : AppColors.gray400,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
