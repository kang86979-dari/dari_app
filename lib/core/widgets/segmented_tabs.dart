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
    // 샌드 트레이 + 흰 알약 탭(드래프트 .seg, 2026-10-11).
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _trackBg,
        borderRadius: BorderRadius.circular(12),
      ),
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

  static const _ink = Color(0xFF14161B);
  static const _muted = Color(0xFF8B8B95);
  static const _orange = Color(0xFFFF6F0F); // 브랜드 carrot
  static const _pillOff = Color(0xFFE2E0DB);

  @override
  Widget build(BuildContext context) {
    final label = Text(
      item.label,
      // 긴 번역 대비 — 반폭 탭 안에서 말줄임(2026-10-11).
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        color: isActive ? _ink : _muted,
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
              borderRadius: BorderRadius.circular(8),
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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: isActive,
        label: item.count != null
            ? '${item.label} ${item.count}개'
            : item.label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            // 활성 = 흰 알약 + 미세 그림자, 비활성 = 투명(샌드 트레이 위).
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 3,
                        offset: Offset(0, 1)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              if (pill != null) ...[
                const SizedBox(width: 6),
                pill,
              ],
            ],
          ),
        ),
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
