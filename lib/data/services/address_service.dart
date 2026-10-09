import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// 역지오코딩 결과 (우편번호 기반 주소).
class GeoAddress {
  final String zipcd; // 우편번호 (없을 수 있음)
  final String road; // 도로명/지번 주소 (동까지)
  const GeoAddress(this.zipcd, this.road);
  bool get isEmpty => zipcd.isEmpty && road.isEmpty;
}

/// GPS 현재 위치 → 우편번호+주소 역지오코딩.
/// 이력서/간편지원 주소 입력에서 "현재 위치로 찾기"에 사용.
/// 실패 사유를 구분해 호출부에서 안내할 수 있게 예외를 던진다.
class AddressService {
  AddressService._();

  /// 위치 권한 확인·요청. 거부/영구거부 시 false.
  static Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AddressException(AddressError.serviceOff);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      throw const AddressException(AddressError.deniedForever);
    }
    if (perm == LocationPermission.denied) {
      throw const AddressException(AddressError.denied);
    }
    return true;
  }

  /// 현재 위치 역지오코딩. localeIdentifier 'ko_KR'로 한글 주소 확보
  /// (K-HIRE 주소 필드는 한글이라야 주입·검색이 맞음).
  static Future<GeoAddress> currentAddress() async {
    await _ensurePermission();
    // timeLimit: 실내 등 GPS 불량 시 무한 대기 방지 — 초과하면
    // TimeoutException → 호출부 catch에서 notFound 안내.
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    // 한글 주소 확보 (K-HIRE 주소 필드는 한글이라야 주입·검색이 맞음).
    await setLocaleIdentifier('ko_KR');
    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (placemarks.isEmpty) {
      throw const AddressException(AddressError.notFound);
    }
    final p = placemarks.first;
    final zip = (p.postalCode ?? '').replaceAll(RegExp('[^0-9]'), '');
    // 한글 주소 조립: 시도 시군구 동 도로명 건물번호 (중복/공백 정리).
    final parts = <String?>[
      p.administrativeArea, // 시/도
      p.subAdministrativeArea, // 시/군 (중복될 수 있음)
      p.locality, // 시/구
      p.subLocality, // 동/읍/면
      p.thoroughfare, // 도로명
      p.subThoroughfare, // 건물번호
    ];
    final seen = <String>{};
    final road = parts
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .where(seen.add) // 연속·중복 토큰 제거
        .join(' ');
    return GeoAddress(zip, road);
  }
}

enum AddressError { serviceOff, denied, deniedForever, notFound }

class AddressException implements Exception {
  final AddressError error;
  const AddressException(this.error);
}
