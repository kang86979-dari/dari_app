/// 다리 계정에 딸린 지원자 프로필.
/// 비자 발급/만료일·주소는 문자 지원(K-HIRE)에서 just-in-time 수집·저장되는 값이라
/// [toJson]에 넣지 않는다 — 가입/개인정보수정 upsert가 이 값들을 덮지 않도록 분리.
/// 저장은 account_provider의 전용 메서드로 해당 컬럼만 update.
class ApplicantProfile {
  final String snsProvider; // 'google' | 'apple' | 'facebook'
  final String email; // 소셜 계정 이메일, 수정 가능
  final String name;
  final String birthDate; // 8자리, 예: 19950314
  final String gender; // 'male' | 'female'
  final String nationalityCode; // ISO alpha-2
  final String nationalityLabel; // 표시용 (현재 언어 기준)
  final String visaCode; // K-HIRE visacd와 1:1 동일
  final String visaLabel; // 표시용
  final String phone; // 010-1234-5678 형식

  // 문자 지원용 확장 필드 (nullable, toJson 미포함)
  final String? visaIssuedAt; // YYYYMMDD 8자리, 예: 20260201
  final String? visaExpiresAt; // YYYYMMDD 8자리, 영주권이면 null
  final bool visaNoExpiry; // F-5 영주권 "만료일 없음"
  final String? addrSido; // 시/도 명칭 (K-HIRE select 텍스트 매칭용)
  final String? addrSigungu; // 시/군/구
  final String? addrDong; // 읍/면/동

  // 우편번호 기반 주소 (이력서/간편지원 Daum 주입용, nullable, toJson 미포함)
  final String? addrZipcd; // 우편번호 (#zipcd)
  final String? addrRoad; // 도로명/지번 주소, 동까지 (#addr1)
  final String? addrDetail; // 상세주소 (#addr2)

  const ApplicantProfile({
    required this.snsProvider,
    required this.email,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.nationalityCode,
    required this.nationalityLabel,
    required this.visaCode,
    required this.visaLabel,
    required this.phone,
    this.visaIssuedAt,
    this.visaExpiresAt,
    this.visaNoExpiry = false,
    this.addrSido,
    this.addrSigungu,
    this.addrDong,
    this.addrZipcd,
    this.addrRoad,
    this.addrDetail,
  });

  /// 서버(applicant_profiles) 행 → 모델. 컬럼은 snake_case.
  factory ApplicantProfile.fromJson(Map<String, dynamic> json) {
    return ApplicantProfile(
      snsProvider: json['sns_provider'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: json['birth_date'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      nationalityCode: json['nationality_code'] as String? ?? '',
      nationalityLabel: json['nationality_label'] as String? ?? '',
      visaCode: json['visa_code'] as String? ?? '',
      visaLabel: json['visa_label'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      visaIssuedAt: _dateToYmd(json['visa_issued_at'] as String?),
      visaExpiresAt: _dateToYmd(json['visa_expires_at'] as String?),
      visaNoExpiry: json['visa_no_expiry'] as bool? ?? false,
      addrSido: json['addr_sido'] as String?,
      addrSigungu: json['addr_sigungu'] as String?,
      addrDong: json['addr_dong'] as String?,
      addrZipcd: json['addr_zipcd'] as String?,
      addrRoad: json['addr_road'] as String?,
      addrDetail: json['addr_detail'] as String?,
    );
  }

  /// 모델 → 서버 행 (user_id는 호출부에서 auth.uid로 추가).
  /// 비자기간·주소는 의도적으로 제외 (문서 상단 주석 참고).
  Map<String, dynamic> toJson() {
    return {
      'sns_provider': snsProvider,
      'email': email,
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
      'nationality_code': nationalityCode,
      'nationality_label': nationalityLabel,
      'visa_code': visaCode,
      'visa_label': visaLabel,
      'phone': phone,
    };
  }

  /// DB date('2026-02-01') → YYYYMMDD('20260201'). null·빈값은 null.
  static String? _dateToYmd(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return null;
    final d = isoDate.split('T').first; // '2026-02-01' 형태 가정
    return d.replaceAll('-', '');
  }

  /// YYYYMMDD('20260201') → DB date('2026-02-01'). 8자리 아니면 null.
  static String? ymdToDate(String? ymd) {
    if (ymd == null || ymd.length != 8) return null;
    return '${ymd.substring(0, 4)}-${ymd.substring(4, 6)}-${ymd.substring(6, 8)}';
  }

  ApplicantProfile copyWith({
    String? snsProvider,
    String? email,
    String? name,
    String? birthDate,
    String? gender,
    String? nationalityCode,
    String? nationalityLabel,
    String? visaCode,
    String? visaLabel,
    String? phone,
    String? visaIssuedAt,
    String? visaExpiresAt,
    bool? visaNoExpiry,
    String? addrSido,
    String? addrSigungu,
    String? addrDong,
    String? addrZipcd,
    String? addrRoad,
    String? addrDetail,
  }) {
    return ApplicantProfile(
      snsProvider: snsProvider ?? this.snsProvider,
      email: email ?? this.email,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      nationalityCode: nationalityCode ?? this.nationalityCode,
      nationalityLabel: nationalityLabel ?? this.nationalityLabel,
      visaCode: visaCode ?? this.visaCode,
      visaLabel: visaLabel ?? this.visaLabel,
      phone: phone ?? this.phone,
      visaIssuedAt: visaIssuedAt ?? this.visaIssuedAt,
      visaExpiresAt: visaExpiresAt ?? this.visaExpiresAt,
      visaNoExpiry: visaNoExpiry ?? this.visaNoExpiry,
      addrSido: addrSido ?? this.addrSido,
      addrSigungu: addrSigungu ?? this.addrSigungu,
      addrDong: addrDong ?? this.addrDong,
      addrZipcd: addrZipcd ?? this.addrZipcd,
      addrRoad: addrRoad ?? this.addrRoad,
      addrDetail: addrDetail ?? this.addrDetail,
    );
  }
}
