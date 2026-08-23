/// 광고 배치 관련 설정값. 추후 Firebase Remote Config로 이전해 A/B 테스트 예정.
class AdConfig {
  AdConfig._();

  /// 리스트 인-리스트 광고 간격: 공고 N개마다 네이티브 광고 1개.
  static const int listAdInterval = 5;

  /// 한 화면에서 동시에 살아 있는 NativeAd 인스턴스 상한.
  /// 초과 시 화면 밖으로 벗어난 오래된 것부터 dispose (메모리·무효노출 방지).
  static const int maxLiveNativeAds = 5;
}
