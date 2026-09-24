/// 다리 계정에 딸린 지원자 프로필. 비자 발급일·만료일은 이번 단계 제외(추후 검토).
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
    );
  }

  /// 모델 → 서버 행 (user_id는 호출부에서 auth.uid로 추가).
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
    );
  }
}
