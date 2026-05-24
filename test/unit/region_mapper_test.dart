import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/core/utils/region_mapper.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════
  // getLocalizedName
  // ════════════════════════════════════════════════════════════════════
  group('getLocalizedName', () {
    test('ko returns original Korean name', () {
      expect(RegionMapper.getLocalizedName('서울', 'ko'), '서울');
    });

    test('en returns English name for 서울', () {
      expect(RegionMapper.getLocalizedName('서울', 'en'), 'Seoul');
    });

    test('en returns English name for 경기도', () {
      expect(RegionMapper.getLocalizedName('경기도', 'en'), 'Gyeonggi');
    });

    test('unknown region returns original name', () {
      expect(RegionMapper.getLocalizedName('없는지역', 'en'), '없는지역');
    });

    test('en returns English for other regions', () {
      expect(RegionMapper.getLocalizedName('부산', 'en'), 'Busan');
      expect(RegionMapper.getLocalizedName('제주', 'en'), 'Jeju');
      expect(RegionMapper.getLocalizedName('인천', 'en'), 'Incheon');
    });

    test('full official name also works', () {
      expect(RegionMapper.getLocalizedName('서울특별시', 'en'), 'Seoul');
      expect(RegionMapper.getLocalizedName('부산광역시', 'en'), 'Busan');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // fromLocationText
  // ════════════════════════════════════════════════════════════════════
  group('fromLocationText', () {
    test('서울시 강남구 matches 서울', () {
      expect(RegionMapper.fromLocationText('서울시 강남구'), '서울');
    });

    test('대전 서구 matches 대전', () {
      expect(RegionMapper.fromLocationText('대전 서구'), '대전');
    });

    test('미국 뉴욕 returns null (no match)', () {
      expect(RegionMapper.fromLocationText('미국 뉴욕'), isNull);
    });

    test('부산 해운대 matches 부산', () {
      expect(RegionMapper.fromLocationText('부산 해운대'), '부산');
    });

    test('제주 서귀포 matches 제주', () {
      expect(RegionMapper.fromLocationText('제주 서귀포'), '제주');
    });
  });
}
