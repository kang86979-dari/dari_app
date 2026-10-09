import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../data/services/address_service.dart';

/// 다음(카카오) 우편번호 검색 웹뷰.
/// Daum postcode 위젯을 임베드 → 선택 결과를 [GeoAddress]로 pop.
/// K-HIRE도 동일 postcode.v2.js를 쓰므로 여기서 받은 zipcd/road를 그대로 주입 가능.
class DaumPostcodeScreen extends StatelessWidget {
  final String langCode;
  const DaumPostcodeScreen({super.key, required this.langCode});

  static Future<GeoAddress?> show(BuildContext context, String langCode) {
    return Navigator.of(context).push<GeoAddress>(
      MaterialPageRoute(
        builder: (_) => DaumPostcodeScreen(langCode: langCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(langCode);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: Text(
          s.addressSearchTitle,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: InAppWebView(
        // baseUrl 지정 — about:blank 오리진이면 외부 스크립트/postMessage가
        // 막힐 수 있음(https 오리진 필요).
        initialData: InAppWebViewInitialData(
          data: _html,
          baseUrl: WebUri('https://postcode.map.daum.net'),
        ),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          javaScriptEnabled: true,
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'onComplete',
            callback: (args) {
              final zip = args.isNotEmpty ? '${args[0]}' : '';
              final road = args.length > 1 ? '${args[1]}' : '';
              Navigator.of(context).pop(GeoAddress(zip, road));
              return null;
            },
          );
        },
      ),
    );
  }

  static const String _html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>html,body{margin:0;padding:0;height:100%;}</style>
</head>
<body>
<div id="wrap" style="width:100%;height:100%;"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
  function run(){
    new daum.Postcode({
      oncomplete: function(data){
        var road = data.roadAddress || data.address || data.jibunAddress || '';
        window.flutter_inappwebview.callHandler('onComplete', data.zonecode || '', road);
      },
      width: '100%',
      height: '100%'
    }).embed(document.getElementById('wrap'), { autoClose: true });
  }
  if (window.daum && window.daum.Postcode) { run(); }
  else { window.addEventListener('load', run); }
</script>
</body>
</html>
''';
}
