/// ISO alpha-2 국가코드 → 유니코드 국기 이모지 변환 (Regional Indicator Symbol 조합).
/// 별도 이미지 자산 없이 시스템 폰트로 렌더링됨.
String flagEmoji(String isoCode) {
  if (isoCode.length != 2) return '🏳️';
  final code = isoCode.toUpperCase();
  final base = 0x1F1E6; // Regional Indicator Symbol Letter A
  final first = base + (code.codeUnitAt(0) - 'A'.codeUnitAt(0));
  final second = base + (code.codeUnitAt(1) - 'A'.codeUnitAt(0));
  return String.fromCharCode(first) + String.fromCharCode(second);
}
