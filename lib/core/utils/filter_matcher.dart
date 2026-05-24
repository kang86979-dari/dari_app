import '../../data/models/filter_state.dart';
import 'filter_synonyms.dart';

/// 필터 매칭 결과 그룹
class FilterMatchGroup {
  final String category; // 'visa', 'region', 'category', 'employmentType', 'koreanLevel', 'benefit', 'salaryType'
  final String categoryLabel; // 다국어 카테고리명
  final List<FilterOption> options;

  const FilterMatchGroup({
    required this.category,
    required this.categoryLabel,
    required this.options,
  });
}

class FilterMatcher {
  /// 검색어와 필터 옵션 매칭
  static List<FilterMatchGroup> match({
    required String query,
    required Map<String, List<FilterOption>> optionsByCategory,
    required Map<String, String> categoryLabels,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final results = <FilterMatchGroup>[];

    for (final entry in optionsByCategory.entries) {
      final category = entry.key;
      final options = entry.value;
      final matched = <FilterOption>[];

      for (final opt in options) {
        if (_isMatch(q, opt.label, category == 'visa')) {
          matched.add(opt);
        }
      }

      // 동의어 매칭 (label로 못 찾은 경우)
      if (matched.isEmpty) {
        final synonymMap = switch (category) {
          'category' => filterSynonyms,
          'employmentType' => employmentSynonyms,
          'benefit' => benefitSynonyms,
          _ => null,
        };
        if (synonymMap != null) {
          final synonymCat = _findSynonymCategoryIn(q, synonymMap);
          if (synonymCat != null) {
            for (final opt in options) {
              if (opt.label.contains(synonymCat)) {
                matched.add(opt);
              }
            }
            if (matched.isEmpty) {
              final synonyms = synonymMap[synonymCat] ?? [];
              for (final opt in options) {
                final labelLower = opt.label.toLowerCase();
                if (synonyms.any((s) => labelLower.contains(s.toLowerCase()) || s.toLowerCase().contains(labelLower))) {
                  matched.add(opt);
                }
              }
            }
          }
        }
      }

      if (matched.isNotEmpty) {
        results.add(FilterMatchGroup(
          category: category,
          categoryLabel: categoryLabels[category] ?? category,
          options: matched,
        ));
      }
    }

    return results;
  }

  static bool _isMatch(String query, String label, bool isVisa) {
    final labelLower = label.toLowerCase();

    // 정확 매칭 (포함)
    if (labelLower.contains(query) || query.contains(labelLower)) return true;

    // 하이픈 무시 매칭 (E9 → E-9, F2 → F-2)
    final queryNoHyphen = query.replaceAll('-', '');
    final labelNoHyphen = labelLower.replaceAll('-', '');
    if (labelNoHyphen.contains(queryNoHyphen) || queryNoHyphen.contains(labelNoHyphen)) return true;

    // 비자: 접두어 매칭 (E-9 → E-9, E-9-1, E-9-2 but not E-90)
    if (isVisa) {
      if (labelLower.startsWith(query) &&
          (labelLower.length == query.length ||
           labelLower[query.length] == '-' ||
           labelLower[query.length] == '/')) {
        return true;
      }
      // 하이픈 무시 접두어 (E9 → E-9, E-9-1 등)
      if (labelNoHyphen.startsWith(queryNoHyphen) &&
          (labelNoHyphen.length == queryNoHyphen.length ||
           labelNoHyphen.length > queryNoHyphen.length)) {
        return true;
      }
    }

    // 오타 허용: Levenshtein 거리 2 이내 (짧은 문자열만)
    if (query.length >= 2 && label.length <= 20) {
      final dist = _levenshtein(query, labelLower);
      final threshold = query.length <= 3 ? 1 : 2;
      if (dist <= threshold) return true;
    }

    // 단어 단위 매칭 (label에 공백이 있을 때)
    final words = labelLower.split(RegExp(r'[\s,/]+'));
    for (final word in words) {
      if (word == query) return true;
      if (word.length >= 2 && query.length >= 2) {
        final dist = _levenshtein(query, word);
        if (dist <= 1) return true;
      }
    }

    return false;
  }

  /// query가 동의어에 매칭되는 카테고리 name_ko를 반환
  static String? _findSynonymCategoryIn(String query, Map<String, List<String>> synonymMap) {
    for (final entry in synonymMap.entries) {
      for (final synonym in entry.value) {
        final synLower = synonym.toLowerCase();
        if (synLower == query) return entry.key;
        if (synLower.contains(query) || query.contains(synLower)) return entry.key;
        if (query.length >= 3 && synonym.length >= 3) {
          final dist = _levenshtein(query, synLower);
          final maxDist = (query.length <= 3 || synonym.length <= 3) ? 1 : 2;
          if (dist <= maxDist) return entry.key;
        }
      }
    }
    return null;
  }


  static int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final m = a.length;
    final n = b.length;
    var prev = List.generate(n + 1, (i) => i);
    var curr = List.filled(n + 1, 0);

    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      for (int j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1,
          curr[j - 1] + 1,
          prev[j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }
}
