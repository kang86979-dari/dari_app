class RegionMapper {
  RegionMapper._();

  /// 시/도 한→영 매핑 (DB si_name 기준)
  static const regionNameEn = {
    '서울': 'Seoul',
    '부산': 'Busan',
    '대구': 'Daegu',
    '인천': 'Incheon',
    '광주': 'Gwangju',
    '대전': 'Daejeon',
    '울산': 'Ulsan',
    '세종': 'Sejong',
    '경기': 'Gyeonggi',
    '강원': 'Gangwon',
    '충북': 'Chungbuk',
    '충남': 'Chungnam',
    '전북': 'Jeonbuk',
    '전남': 'Jeonnam',
    '경북': 'Gyeongbuk',
    '경남': 'Gyeongnam',
    '제주': 'Jeju',
    // 정식 명칭도 호환
    '서울특별시': 'Seoul',
    '부산광역시': 'Busan',
    '대구광역시': 'Daegu',
    '인천광역시': 'Incheon',
    '광주광역시': 'Gwangju',
    '대전광역시': 'Daejeon',
    '울산광역시': 'Ulsan',
    '세종특별자치시': 'Sejong',
    '경기도': 'Gyeonggi',
    '강원특별자치도': 'Gangwon',
    '충청북도': 'Chungbuk',
    '충청남도': 'Chungnam',
    '전북특별자치도': 'Jeonbuk',
    '전라남도': 'Jeonnam',
    '경상북도': 'Gyeongbuk',
    '경상남도': 'Gyeongnam',
    '제주특별자치도': 'Jeju',
  };

  /// 언어 코드에 따라 지역명 반환 (ko→한글, 그 외→영어)
  static String getLocalizedName(String siName, String langCode) {
    if (langCode == 'ko') return siName;
    return regionNameEn[siName] ?? siName;
  }

  /// 시/도 이름 목록 (fromLocationText 매칭용)
  static const _regionNames = [
    '서울', '경기', '인천', '강원', '충북', '충남',
    '대전', '세종', '전북', '전남', '광주',
    '경북', '대구', '경남', '울산', '부산', '제주',
  ];

  /// location 문자열 → 필터 지역명 매핑
  static String? fromLocationText(String location) {
    for (final region in _regionNames) {
      if (location.contains(region)) return region;
    }
    return null;
  }
}
