import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  static final ConsentService _instance = ConsentService._();
  factory ConsentService() => _instance;
  ConsentService._();

  /// UMP 동의 요청 후 광고 요청 가능 여부 반환
  /// MobileAds.instance.initialize() 전에 호출해야 함
  Future<bool> requestConsent() async {
    final completer = Completer<bool>();

    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // 동의 정보 업데이트 성공
        ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) {
            debugPrint('ConsentForm error: ${formError.message}');
          }
          final canRequest = ConsentInformation.instance.canRequestAds();
          completer.complete(canRequest);
        });
      },
      (FormError error) {
        // 실패 시에도 광고 초기화 진행 (fail-open)
        debugPrint('ConsentInfo update error: ${error.message}');
        completer.complete(true);
      },
    );

    return completer.future;
  }
}

final consentService = ConsentService();
