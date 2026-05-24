// segmented_tabs.dart — Dari 검색결과 / 필터 탭 (Card Tabs 스타일)
//
// 디자인: 05 · Card Tabs
// - 베이지 트레이(#FAF7F1) 위에 활성 탭이 흰색 카드처럼 올라옴 (상단 라운드)
// - 활성 탭은 상/좌/우 1px 테두리 + 아래쪽 1px 라인을 가려서
//   콘텐츠 영역과 자연스럽게 이어지는 "탭→페이지" 느낌
// - 카운트 pill: 활성은 주황(#F26B1F) 배경 + 흰 글자, 비활성은 회색
//
// Flutter 3.x · Material 3 호환. 외부 패키지 의존성 없음.

import 'package:flutter/material.dart';

class SegmentedTabItem {
  /// 안정적인 키 (active/onChange 식별용)
  final String key;

  /// 화면에 보이는 라벨
  final String label;

  /// 우측 카운트 pill에 표시할 숫자. null이면 pill 미표시
  final int? count;

  const SegmentedTabItem({
    required this.key,
    required this.label,
    this.count,
  });
}

class SegmentedTabs extends StatelessWidget {
  final List<SegmentedTabItem> tabs;
  final String active;
  final ValueChanged<String> onChange;

  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChange,
  });

  static const _trackBg = Color(0xFFFAF7F1);
  static const _lineColor = Color(0xFFE9E6E0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _trackBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: SizedBox(
              height: 46,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++) ...[
                    Expanded(
                      child: _Tab(
                        item: tabs[i],
                        isActive: tabs[i].key == active,
                        onTap: () => onChange(tabs[i].key),
                      ),
                    ),
                    if (i < tabs.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final SegmentedTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  static const _lineColor = Color(0xFFE9E6E0);
  static const _navy = Color(0xFF0E2461);
  static const _muted = Color(0xFF8B8B95);
  static const _orange = Color(0xFFF26B1F);
  static const _pillOff = Color(0xFFE9E6E0);

  @override
  Widget build(BuildContext context) {
    final label = Text(
      item.label,
      style: TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        color: isActive ? _navy : _muted,
        letterSpacing: -0.15,
      ),
    );

    final pill = item.count == null
        ? null
        : Container(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20, maxHeight: 20),
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            decoration: BoxDecoration(
              color: isActive ? _orange : _pillOff,
              borderRadius: BorderRadius.circular(99),
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.count}',
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : _muted,
              ),
            ),
          );

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        if (pill != null) ...[
          const SizedBox(width: 6),
          pill,
        ],
      ],
    );

    final tabCard = Material(
      color: isActive ? Colors.white : Colors.transparent,
      // 상단만 둥글게 — 콘텐츠와 이어지는 카드 느낌
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Ink(
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
          // 활성 탭만 상/좌/우 1px 테두리
          border: isActive
              ? const Border(
                  top: BorderSide(color: _lineColor),
                  left: BorderSide(color: _lineColor),
                  right: BorderSide(color: _lineColor),
                )
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
          splashColor:
              isActive ? Colors.transparent : const Color(0x14000000),
          highlightColor:
              isActive ? Colors.transparent : const Color(0x0A000000),
          child: Center(child: content),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: isActive,
      label: item.count != null
          ? '${item.label} ${item.count}개'
          : item.label,
      // 활성 탭이 아래쪽 1px 라인을 가리도록 1px 만큼 아래로 튀어나오게.
      // Stack의 clipBehavior: Clip.none + Positioned(bottom: -1)로 처리.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tabCard,
          if (isActive)
            const Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 1,
              child: ColoredBox(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────
   USAGE

   class _MyScreenState extends State<MyScreen> {
     String _active = 'results';

     @override
     Widget build(BuildContext context) {
       return Column(
         children: [
           SegmentedTabs(
             tabs: const [
               SegmentedTabItem(key: 'results', label: '검색결과', count: 6),
               SegmentedTabItem(key: 'filter',  label: '필터',     count: 5),
             ],
             active: _active,
             onChange: (k) => setState(() => _active = k),
           ),
           // ... content (배경은 흰색 권장 — 카드 탭이 자연스럽게 이어짐)
         ],
       );
     }
   }
   ───────────────────────────────────────────────────────────────── */
