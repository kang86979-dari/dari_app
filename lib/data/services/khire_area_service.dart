import 'dart:convert';
import 'dart:io';

/// K-HIRE 주소 데이터(공개 JS: _AreaCode.js, _DongCode.js)를 가져와
/// 시/도 코드 ↔ 이름, 구별 읍면동 목록을 제공(2026-10-04).
/// TalkApply 폼과 동일한 데이터 소스라 선택값이 항상 폼 옵션과 일치한다.
/// 메모리 캐시(앱 세션 동안 1회 로드).
class KhireAreaService {
  static const _base = 'https://m.khire.co.kr/rsc/js';

  /// siName(FUNM, 예: 서울특별시) → ARCD(예: 02)
  static Map<String, String>? _siCodeByName;

  /// ARCD → [(GUCD, DOCD)]
  static Map<String, List<(String, String)>>? _dongByArcd;

  static Future<String> _fetch(String path) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse('$_base/$path'));
      final res = await req.close();
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  static Future<void> _ensureLoaded() async {
    if (_siCodeByName != null && _dongByArcd != null) return;

    final area = await _fetch('_AreaCode.js');
    final si = <String, String>{};
    for (final m in RegExp(
            r'ARCD:\s*"([^"]+)",\s*ARNM:\s*"([^"]+)",\s*FUNM:\s*"([^"]+)"')
        .allMatches(area)) {
      si[m.group(3)!] = m.group(1)!; // FUNM(풀네임) → 코드
      si[m.group(2)!] = m.group(1)!; // ARNM(축약) → 코드
    }
    _siCodeByName = si;

    final dong = await _fetch('_DongCode.js');
    final byArcd = <String, List<(String, String)>>{};
    // ARCD_XX 섹션 단위로 분할 후 (GUCD, DOCD) 추출
    final sections = RegExp(r'ARCD_(\w+):\s*\[').allMatches(dong).toList();
    for (var i = 0; i < sections.length; i++) {
      final code = sections[i].group(1)!;
      final start = sections[i].end;
      final end =
          i + 1 < sections.length ? sections[i + 1].start : dong.length;
      final body = dong.substring(start, end);
      final list = <(String, String)>[];
      for (final m in RegExp(r'GUCD:\s*"([^"]+)",\s*DOCD:\s*"([^"]+)"')
          .allMatches(body)) {
        list.add((m.group(1)!, m.group(2)!));
      }
      byArcd[code] = list;
    }
    _dongByArcd = byArcd;
  }

  /// 시/도명(풀네임·축약 모두 허용)과 구명으로 읍면동 목록. 실패 시 빈 리스트.
  static Future<List<String>> dongList(String siName, String guName) async {
    try {
      await _ensureLoaded();
    } catch (_) {
      return [];
    }
    // 정확 일치 → 접미사 제거 토큰 매칭 순
    var code = _siCodeByName![siName];
    if (code == null) {
      final core = siName.replaceAll(
          RegExp(r'(특별자치시|특별자치도|광역시|특별시|통합)'), '');
      for (final e in _siCodeByName!.entries) {
        if (e.key.contains(core) || core.contains(e.key)) {
          code = e.value;
          break;
        }
      }
    }
    if (code == null) return [];
    final rows = _dongByArcd![code] ?? [];
    return [
      for (final r in rows)
        if (r.$1 == guName) r.$2,
    ];
  }
}
