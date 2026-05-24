import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/data/models/job.dart';

/// Helper to create a Job with sensible defaults so tests stay concise.
Job _makeJob({
  String id = 'test-id',
  String siteId = 'site-1',
  String? siteName,
  String? siteUrl,
  String? title,
  String? company,
  String? location,
  String? addressDetail,
  String? salary,
  String? salaryTypeRaw,
  int? salaryAmount,
  String? workDays,
  String? workTime,
  String? workModel,
  String? jobType,
  String? description,
  String? url,
  bool isActive = true,
  String? expiresAt,
  String? crawledAt,
  String? postedAt,
  bool? housingProvided,
  bool? drivingLicense,
  List<String> nationalityRestrictions = const [],
  Map<String, dynamic> titleTranslations = const {},
  Map<String, dynamic> jobTypeTranslations = const {},
  Map<String, dynamic> descriptionTranslations = const {},
  Map<String, dynamic> addressTranslations = const {},
  Map<String, dynamic> workModelTranslations = const {},
  Map<String, dynamic> workTimeTranslations = const {},
  String? jobCategoryId,
  String? employmentTypeId,
  int? regionId,
  int? workScheduleId,
  String? workStartTime,
  String? workEndTime,
  int? koreanLevelId,
  bool? visaSponsorship,
  List<VisaInfo> visas = const [],
  CategoryInfo? jobCategory,
  EmploymentTypeInfo? employmentType,
  List<BenefitInfo> benefits = const [],
  RegionInfo? region,
  KoreanLevelInfo? koreanLevel,
  WorkScheduleInfo? workSchedule,
  List<JobLanguageInfo> jobLanguages = const [],
}) {
  return Job(
    id: id,
    siteId: siteId,
    siteName: siteName,
    siteUrl: siteUrl,
    title: title,
    company: company,
    location: location,
    addressDetail: addressDetail,
    salary: salary,
    salaryTypeRaw: salaryTypeRaw,
    salaryAmount: salaryAmount,
    workDays: workDays,
    workTime: workTime,
    workModel: workModel,
    jobType: jobType,
    description: description,
    url: url,
    isActive: isActive,
    expiresAt: expiresAt,
    crawledAt: crawledAt,
    postedAt: postedAt,
    housingProvided: housingProvided,
    drivingLicense: drivingLicense,
    nationalityRestrictions: nationalityRestrictions,
    titleTranslations: titleTranslations,
    jobTypeTranslations: jobTypeTranslations,
    descriptionTranslations: descriptionTranslations,
    addressTranslations: addressTranslations,
    workModelTranslations: workModelTranslations,
    workTimeTranslations: workTimeTranslations,
    jobCategoryId: jobCategoryId,
    employmentTypeId: employmentTypeId,
    regionId: regionId,
    workScheduleId: workScheduleId,
    workStartTime: workStartTime,
    workEndTime: workEndTime,
    koreanLevelId: koreanLevelId,
    visaSponsorship: visaSponsorship,
    visas: visas,
    jobCategory: jobCategory,
    employmentType: employmentType,
    benefits: benefits,
    region: region,
    koreanLevel: koreanLevel,
    workSchedule: workSchedule,
    jobLanguages: jobLanguages,
  );
}

void main() {
  // ════════════════════════════════════════════════════════════════════
  // getTitle
  // ════════════════════════════════════════════════════════════════════
  group('getTitle', () {
    test('ko returns original title (raw preferred)', () {
      final job = _makeJob(
        title: '한국어 제목',
        titleTranslations: {'ko': '번역된 한국어', 'en': 'English Title'},
      );
      // ko: title ?? translations['ko']
      // title is non-null, so it returns title
      expect(job.getTitle('ko'), '한국어 제목');
    });

    test('vi with vi translation returns Vietnamese', () {
      final job = _makeJob(
        title: '한국어 제목',
        titleTranslations: {'vi': 'Viet', 'en': 'English'},
      );
      expect(job.getTitle('vi'), 'Viet');
    });

    test('fr with only en translation falls back to en', () {
      final job = _makeJob(
        title: '한국어 제목',
        titleTranslations: {'en': 'English Title'},
      );
      expect(job.getTitle('fr'), 'English Title');
    });

    test('en with no translations returns original title', () {
      final job = _makeJob(title: '한국어 제목');
      expect(job.getTitle('en'), '한국어 제목');
    });

    test('null title + empty translations + ko returns empty string', () {
      final job = _makeJob(title: null, titleTranslations: {});
      expect(job.getTitle('ko'), '');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // getAddress
  // ════════════════════════════════════════════════════════════════════
  group('getAddress', () {
    test('ko returns addressDetail', () {
      final job = _makeJob(
        addressDetail: '경기 성남시 수정구 탄리로',
        addressTranslations: {'en': '123 Main St, Seongnam'},
      );
      expect(job.getAddress('ko'), '경기 성남시 수정구 탄리로');
    });

    test('en with en translation returns translation', () {
      final job = _makeJob(
        addressDetail: '경기 성남시',
        addressTranslations: {'en': '123 Main St, Seongnam'},
      );
      expect(job.getAddress('en'), '123 Main St, Seongnam');
    });

    test('en without translations but with region returns region displayName', () {
      final job = _makeJob(
        addressDetail: '경기 성남시',
        region: const RegionInfo(id: 1, siName: '경기', guName: '성남시'),
      );
      expect(job.getAddress('en'), '성남시, 경기');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // getShortLocation
  // ════════════════════════════════════════════════════════════════════
  group('getShortLocation', () {
    test('ko: first 2 words from addressDetail', () {
      final job = _makeJob(addressDetail: '경기 성남시 수정구 탄리로');
      expect(job.getShortLocation('ko'), '경기 성남시');
    });

    test('en: last 2 comma parts from translation', () {
      final job = _makeJob(
        addressTranslations: {
          'en': '123 Main St, Sujeong, Seongnam, Gyeonggi',
        },
      );
      expect(job.getShortLocation('en'), 'Seongnam, Gyeonggi');
    });

    test('en: single part translation returns as-is', () {
      final job = _makeJob(addressTranslations: {'en': 'Seoul'});
      expect(job.getShortLocation('en'), 'Seoul');
    });

    test('ko: single word addressDetail returns as-is', () {
      final job = _makeJob(addressDetail: '서울');
      expect(job.getShortLocation('ko'), '서울');
    });

    test('ko: null addressDetail + no region returns empty string', () {
      final job = _makeJob();
      expect(job.getShortLocation('ko'), '');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // salaryType getter
  // ════════════════════════════════════════════════════════════════════
  group('salaryType', () {
    test('salaryTypeRaw=hourly', () {
      expect(_makeJob(salaryTypeRaw: 'hourly').salaryType, SalaryType.hourly);
    });

    test('salaryTypeRaw=monthly', () {
      expect(_makeJob(salaryTypeRaw: 'monthly').salaryType, SalaryType.monthly);
    });

    test('salaryTypeRaw=annual', () {
      expect(_makeJob(salaryTypeRaw: 'annual').salaryType, SalaryType.annual);
    });

    test('salaryTypeRaw=daily', () {
      expect(_makeJob(salaryTypeRaw: 'daily').salaryType, SalaryType.daily);
    });

    test('salaryTypeRaw=company_rule', () {
      expect(
        _makeJob(salaryTypeRaw: 'company_rule').salaryType,
        SalaryType.companyRule,
      );
    });

    test('salaryTypeRaw=negotiable', () {
      expect(
        _makeJob(salaryTypeRaw: 'negotiable').salaryType,
        SalaryType.negotiable,
      );
    });

    test('null salaryTypeRaw, salary text with 시급 => hourly', () {
      expect(
        _makeJob(salary: '시급 10,030원').salaryType,
        SalaryType.hourly,
      );
    });

    test('null salaryTypeRaw, salary text with 연봉 => annual', () {
      expect(
        _makeJob(salary: '연봉 3000만원').salaryType,
        SalaryType.annual,
      );
    });

    test('null salaryTypeRaw, salary text 200만원 => monthly (default)', () {
      expect(
        _makeJob(salary: '200만원').salaryType,
        SalaryType.monthly,
      );
    });

    test('null salaryTypeRaw, null salary => unknown', () {
      expect(_makeJob().salaryType, SalaryType.unknown);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // getDescriptionHtml
  // ════════════════════════════════════════════════════════════════════
  group('getDescriptionHtml', () {
    test('korean description with newlines converts to <br>', () {
      final job = _makeJob(description: '줄1\n줄2');
      expect(job.getDescriptionHtml(), '줄1<br>줄2');
    });

    test('with lang=en and en translation returns translation HTML', () {
      final job = _makeJob(
        description: '한국어 설명',
        descriptionTranslations: {'en': '<p>Hello</p>'},
      );
      expect(job.getDescriptionHtml('en'), '<p>Hello</p>');
    });

    test('empty en translation falls back to korean original', () {
      final job = _makeJob(
        description: '한국어 설명',
        descriptionTranslations: {'en': ''},
      );
      expect(job.getDescriptionHtml('en'), '한국어 설명');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // displayWorkTime
  // ════════════════════════════════════════════════════════════════════
  group('displayWorkTime', () {
    test('with workStartTime and workEndTime formats HH:MM - HH:MM', () {
      final job = _makeJob(workStartTime: '09:00:00', workEndTime: '18:00:00');
      expect(job.displayWorkTime, '09:00 - 18:00');
    });

    test('null times with workTime returns workTime', () {
      final job = _makeJob(workTime: '주간');
      expect(job.displayWorkTime, '주간');
    });

    test('null everything returns empty string', () {
      expect(_makeJob().displayWorkTime, '');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Job.fromJson
  // ════════════════════════════════════════════════════════════════════
  group('Job.fromJson', () {
    test('parses full JSON including joins', () {
      final json = {
        'id': 'job-123',
        'site_id': 'site-1',
        'title': '음식점 서빙',
        'company': '맛있는 식당',
        'location': '서울',
        'address_detail': '서울 강남구 역삼동',
        'salary': '월급 200만원',
        'salary_type': 'monthly',
        'salary_amount': 2000000,
        'work_days': '월~금',
        'work_time': '주간',
        'work_model': '현장',
        'job_type': '서빙',
        'description': '<p>상세설명</p>',
        'url': 'https://example.com/job/123',
        'is_active': true,
        'expires_at': '2026-05-01',
        'crawled_at': '2026-04-20T12:00:00',
        'posted_at': '2026-04-19',
        'housing_provided': true,
        'driving_license': false,
        'visa_sponsorship': true,
        'nationality_restrictions': ['KR', 'US'],
        'title_translations': {'en': 'Restaurant Server', 'vi': 'Phuc vu'},
        'job_type_translations': {'en': 'Serving'},
        'description_translations': {'en': '<p>Details</p>'},
        'address_translations': {'en': 'Yeoksam, Gangnam, Seoul'},
        'work_model_translations': {'en': 'On-site'},
        'work_time_translations': {'en': 'Daytime'},
        'job_category_id': 'cat-1',
        'employment_type_id': 'et-1',
        'region_id': 10,
        'work_schedule_id': 3,
        'work_start_time': '09:00:00',
        'work_end_time': '18:00:00',
        'korean_level_id': 2,
        'sites': {'name': 'JobKorea', 'url': 'https://jobkorea.co.kr'},
        'job_visas': [
          {
            'visa_master': {
              'id': 'v1',
              'code': 'E-9',
              'name_ko': '비전문취업',
              'name_en': 'Non-professional Employment',
            },
          },
        ],
        'job_categories': {
          'id': 'cat-1',
          'name_ko': '서빙',
          'name_en': 'Serving',
        },
        'employment_types': {
          'id': 'et-1',
          'name_ko': '정규직',
          'name_en': 'Full-time',
        },
        'job_benefits': [
          {
            'benefits': {
              'id': 'b1',
              'name_ko': '식대',
              'name_en': 'Meals',
            },
          },
        ],
        'regions': {'id': 10, 'si_name': '서울', 'gu_name': '강남구'},
        'korean_levels': {
          'id': 2,
          'code': 'intermediate',
          'name_ko': '중급',
          'name_en': 'Intermediate',
        },
        'work_schedules': {
          'id': 3,
          'code': 'mon_fri',
          'name_ko': '월~금',
          'name_en': 'Mon-Fri',
        },
        'job_languages': [
          {
            'language_id': 5,
            'proficiency': 'basic',
            'languages': {
              'code': 'en',
              'name_ko': '영어',
              'name_en': 'English',
            },
          },
        ],
      };

      final job = Job.fromJson(json);

      expect(job.id, 'job-123');
      expect(job.siteId, 'site-1');
      expect(job.siteName, 'JobKorea');
      expect(job.siteUrl, 'https://jobkorea.co.kr');
      expect(job.title, '음식점 서빙');
      expect(job.company, '맛있는 식당');
      expect(job.salaryTypeRaw, 'monthly');
      expect(job.salaryAmount, 2000000);
      expect(job.isActive, true);
      expect(job.housingProvided, true);
      expect(job.drivingLicense, false);
      expect(job.visaSponsorship, true);
      expect(job.nationalityRestrictions, ['KR', 'US']);

      // Translations
      expect(job.titleTranslations['en'], 'Restaurant Server');
      expect(job.addressTranslations['en'], 'Yeoksam, Gangnam, Seoul');

      // Visas
      expect(job.visas.length, 1);
      expect(job.visas.first.code, 'E-9');
      expect(job.visas.first.nameEn, 'Non-professional Employment');

      // Category
      expect(job.jobCategory, isNotNull);
      expect(job.jobCategory!.getName('en'), 'Serving');

      // Employment type
      expect(job.employmentType, isNotNull);
      expect(job.employmentType!.getName('en'), 'Full-time');

      // Benefits
      expect(job.benefits.length, 1);
      expect(job.benefits.first.getName('en'), 'Meals');

      // Region
      expect(job.region, isNotNull);
      expect(job.region!.siName, '서울');
      expect(job.region!.guName, '강남구');
      expect(job.region!.displayName, '강남구, 서울');

      // Korean level
      expect(job.koreanLevel, isNotNull);
      expect(job.koreanLevel!.getName('en'), 'Intermediate');

      // Work schedule
      expect(job.workSchedule, isNotNull);
      expect(job.workSchedule!.getName('en'), 'Mon-Fri');

      // Job languages
      expect(job.jobLanguages.length, 1);
      expect(job.jobLanguages.first.langCode, 'en');
      expect(job.jobLanguages.first.proficiency, 'basic');

      // Work time
      expect(job.displayWorkTime, '09:00 - 18:00');
    });

    test('parses minimal JSON without joins', () {
      final json = {
        'id': 'job-min',
        'site_id': 'site-2',
        'is_active': false,
      };

      final job = Job.fromJson(json);
      expect(job.id, 'job-min');
      expect(job.isActive, false);
      expect(job.visas, isEmpty);
      expect(job.benefits, isEmpty);
      expect(job.jobCategory, isNull);
      expect(job.region, isNull);
    });
  });
}
