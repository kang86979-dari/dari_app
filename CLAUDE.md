# Dari — Claude Code 컨텍스트

## 작업 규칙
- **작업 현황 실시간 저장**: 코드 수정, 버그 발견, 작업 완료, 새 결정 등 상태 변경 시마다 memory/project_todo.md를 즉시 업데이트할 것. 사용자가 "저장해"라고 말할 때까지 기다리지 않는다. 언제 재부팅될지 모르기 때문.

## 프로젝트 개요
한국 거주 외국인 구직자를 위한 구인정보 앱.
- 앱 이름: Dari
- 플랫폼: Android 우선 (Flutter)
- 메인 컬러: #FF6F0F

## 기술 스택
- 상태관리: flutter_riverpod ^2.5.1 + riverpod_annotation ^2.3.5
- 라우팅: go_router ^13.2.0
- DB: supabase_flutter ^2.3.4
- 다국어: flutter_localizations + intl ^0.20.2
- 위치: geolocator ^11.0.0
- 로컬 저장: shared_preferences ^2.2.3
- 환경변수: flutter_dotenv ^5.1.0
- URL 열기: url_launcher ^6.2.6
- 광고: google_mobile_ads ^5.3.0
- HTML 렌더링: flutter_html ^3.0.0-beta.2 + cached_network_image ^3.3.1

## 폴더 구조 (feature-first)
```
lib/
├── main.dart
├── app.dart                  GoRouter + ProviderScope + Localizations
├── core/
│   ├── constants/
│   │   └── colors.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── l10n/
│   │   ├── app_strings.dart  런타임 다국어 문자열 (28개 언어 전체 번역 완료)
│   │   ├── l10n_provider.dart
│   │   └── arb/              .arb 파일 + 생성된 app_localizations
│   └── utils/
│       ├── region_mapper.dart
│       └── salary_formatter.dart
├── data/
│   ├── models/
│   │   ├── job.dart          jsonb 번역 5종 + 조인 모델 8종 + SalaryType enum
│   │   └── filter_state.dart 14종 필터 + FilterOption + FilterCounts (RPC)
│   ├── repositories/
│   │   └── job_repository.dart  조인 쿼리 + AND 필터 + 유사도 검색 + 전체 건수
│   └── services/
│       └── location_service.dart
├── providers/
│   ├── job_provider.dart     FilterStateNotifier (SharedPreferences 영속) + 프로바이더
│   ├── search_provider.dart  검색 + 최근 검색어 (SharedPreferences)
│   ├── favorite_provider.dart 즐겨찾기 (SharedPreferences)
│   └── language_provider.dart 28개 언어
└── features/
    ├── splash/
    │   └── splash_screen.dart
    ├── onboarding/
    │   ├── language_select_screen.dart
    │   ├── visa_select_screen.dart
    │   └── location_permission_screen.dart
    ├── home/
    │   ├── home_screen.dart        무한 스크롤 + 읽기전용 필터칩 + 전체 건수
    │   └── widgets/
    │       ├── job_card.dart       즐겨찾기 하트 + 가로 스크롤 태그 + 다국어 급여
    │       ├── skeleton_card.dart
    │       └── ad_banner.dart
    ├── filter/
    │   └── filter_screen.dart      좌우 2패널 + 9종 그룹 필터 + 비자 그룹핑
    ├── favorites/
    │   └── favorites_screen.dart   정렬(마감일/등록순) + 편집 삭제
    ├── search/
    │   └── search_screen.dart      최근검색어 + 추천 + 유사도 검색 + 무한 스크롤
    └── job_detail/
        └── job_detail_screen.dart  즐겨찾기 하트 + 번역 설명 + 주소 한/영 토글
```

## 라우팅 (GoRouter)
```
/splash
/onboarding/language
/onboarding/visa
/onboarding/location
/home
/favorites
/search
/filter
/job/:id
```

## 번역 방식
- 서버(크롤러)에서 Google Translate API로 번역 후 DB에 jsonb로 저장
- jobs 테이블 번역 컬럼 5종:
  - title_translations, job_type_translations, description_translations, address_translations, work_model_translations (jsonb)
- 주소 번역: ko/en만 지원, 그 외 언어는 en 폴백
- 앱에서 job.getTitle(langCode) → translations[langCode] ?? translations['en'] ?? 원문 폴백
- description/description_translations: **sanitize된 HTML** 저장 (백엔드 bleach 처리)
  - 허용 태그: p, br, hr, strong, b, em, i, u, h1-h6, ul, ol, li, table/tr/td/th, img, a, span, div 등
  - 이미지 도메인 화이트리스트: kowork.kr, klik.co.kr, saramin.co.kr, jobploy.kr 등
- getDescription(): plaintext용 (검색 결과 등) — `\n`, `<br>` 등 줄바꿈 변환
- getDescriptionHtml(): HTML 원본 유지 (상세 화면용) — flutter_html로 렌더링
- is_translated=true 인 공고만 표시 (매핑률 100%)
- 앱 UI 문자열: app_strings.dart에서 28개 언어 전체 번역 완료 (92개 문자열)

## 다국어 급여 표시
- DB: salary_type (text), salary_amount (integer) 컬럼
- salary_type 값: hourly, daily, monthly, annual, company_rule, negotiable, NULL
- 앱에서 언어별 포맷팅:
  - ko: 월급 200만원, 시급 10,030원
  - ja: 月給 200万ウォン
  - zh: 月薪 200万韩元
  - de/fr/pt/es 등: ₩2.000.000 / Monatlich (마침표 천단위)
  - hi/ne/bn: ₩20,00,000 (인도식)
  - 그 외: ₩2,000,000 / Monthly

## 지원 언어 (28개)
ko, en, fr, de, zh, zh-yue, hi, it, ja, pl, pt, es,
th, vi, ar, bn, ru, id, tr, he, ms, ne, km, my, fil, uz, mn, kk

## DB 테이블 구조
```
jobs
  ├── title, description, job_type, address_detail (원문 한국어)
  ├── title_translations, job_type_translations, description_translations, address_translations, work_model_translations (jsonb)
  ├── salary_type (text: hourly/daily/monthly/annual/company_rule/negotiable)
  ├── salary_amount (integer: 원 단위)
  ├── gender (text: male/female/any)
  ├── education (text: none/middle_school/high_school/college/bachelor/master/doctor)
  ├── experience (text: none/newcomer/1y/3y/5y/10y)
  ├── region_id bigint FK → regions (id, si_name, gu_name)
  ├── work_schedule_id bigint FK → work_schedules (id, code, name_ko, name_en, sort_order)
  ├── work_start_time, work_end_time (time)
  ├── korean_level_id bigint FK → korean_levels (id, code, name_ko, name_en, sort_order)
  ├── job_category_id uuid FK → job_categories (id, name_ko, name_en)
  ├── employment_type_id uuid FK → employment_types (id, name_ko, name_en)
  ├── visa_sponsorship (boolean)
  ├── is_active, is_duplicate, is_translated (boolean)
  ├── job_visas (job_id, visa_id) → visa_master (id, code, name_ko, name_en)
  │   └── code='ANY' → 비자 무관 (비자 정보 없는 공고에 자동 연결)
  ├── job_benefits (job_id, benefit_id) → benefits (id, name_ko, name_en)
  └── job_languages (job_id, language_id, proficiency) → languages (id, code, name_ko, name_en)

sites
  ├── name (사이트 이름)
  └── url (사이트 홈페이지)

analytics_events
  ├── session_id, event_name, event_data (jsonb)
  ├── lang_code, app_version, platform
  └── created_at

RPC:
  - get_filter_counts() → 필터 옵션별 공고 건수 (gender, salary_type, education, experience 포함)
  - search_jobs_fuzzy(search_query, lang_code, result_limit, result_offset)
    → pg_trgm 유사도 검색, 오타 허용, 다국어 지원

정렬: crawled_at DESC (크롤링일 기준 최신순 — posted_at이 NULL인 공고 있어서 crawled_at 사용)
```

## 데이터 모델 (Job)
```dart
class Job {
  // 기본 필드
  final String id, siteId;
  final String? siteName, siteUrl, title, company, location, addressDetail;
  final String? salary, salaryTypeRaw, workDays, workTime, workModel, jobType, description, url;
  final int? salaryAmount;
  final bool isActive;
  final String? expiresAt, crawledAt, postedAt;
  final bool? housingProvided, drivingLicense, visaSponsorship;
  final List<String> nationalityRestrictions;

  // jsonb 번역 5종
  final Map<String, dynamic> titleTranslations;
  final Map<String, dynamic> jobTypeTranslations;
  final Map<String, dynamic> descriptionTranslations;
  final Map<String, dynamic> addressTranslations;
  final Map<String, dynamic> workModelTranslations;

  // FK 필드 (uuid)
  final String? jobCategoryId, employmentTypeId;

  // FK 필드 (bigint)
  final int? regionId, workScheduleId, koreanLevelId;
  final String? workStartTime, workEndTime;

  // 조인된 관계 데이터
  final List<VisaInfo> visas;
  final CategoryInfo? jobCategory;
  final EmploymentTypeInfo? employmentType;
  final List<BenefitInfo> benefits;
  final RegionInfo? region;
  final KoreanLevelInfo? koreanLevel;
  final WorkScheduleInfo? workSchedule;
  final List<JobLanguageInfo> jobLanguages;

  // 헬퍼
  String getTitle(String langCode);
  String getDescription(String langCode);   // plaintext용 (줄바꿈 변환)
  String getDescriptionHtml(String langCode); // HTML 원본 유지 (상세 화면용)
  String getJobType(String langCode);
  String getEmploymentType(String langCode);
  String getKoreanLevel(String langCode);
  String getWorkSchedule(String langCode);
  String getWorkModel(String langCode);     // work_model_translations 기반
  String getAddress(String langCode);       // ko/en만 지원, 그 외 en 폴백
  String getShortLocation(String langCode); // 카드용: ko→앞2개 / en→뒤2개 콤마 기준
  String get displayWorkTime;
  SalaryType get salaryType;                // DB salary_type 우선, 없으면 텍스트 파싱
}

enum SalaryType { hourly, daily, monthly, annual, companyRule, negotiable, unknown }
```

## 상태관리 구조 (Riverpod)
```
filterStateProvider (StateNotifier<FilterState>) — SharedPreferences 영속
  └── jobListProvider (FutureProvider.family) — AND 필터, 페이지네이션
  └── jobTotalCountProvider (FutureProvider) — 전체 건수

searchQueryProvider (StateProvider<String>)
  └── searchResultProvider (FutureProvider) — search_jobs_fuzzy RPC

recentSearchProvider (StateNotifier) — 최근 검색어 5개, SharedPreferences

favoriteProvider (StateNotifier<List<FavoriteItem>>) — SharedPreferences
  └── isFavoriteProvider (Provider.family<bool, String>)

jobDetailProvider (FutureProvider.family) — id → JobDetailScreen

languageProvider (StateNotifier) — SharedPreferences

// [DEV] 사이트 필터
selectedSiteIdProvider (StateProvider<String?>) — 홈 화면 사이트 탭
siteOptionsProvider → sites 테이블

// 필터 옵션 (DB 동적 로드)
visaOptionsProvider, categoryOptionsProvider, employmentTypeOptionsProvider,
benefitOptionsProvider, regionOptionsProvider, koreanLevelOptionsProvider,
workScheduleOptionsProvider

// 필터 카운트 (RPC)
filterCountsProvider → get_filter_counts()
```

## 온보딩 플로우
앱 실행 → 스플래시(1.5초) → 최초실행: 언어선택 → 비자선택 → 위치권한 → 홈
재실행: 앱 오픈 광고(하루 1회) → 홈 (저장된 필터 유지)

- 비자선택: visa_master에서 목록 로드, 복수선택 → FilterState에 저장
- 위치권한: GPS 허용 시 지역명을 FilterState에 저장
- 선택된 비자+지역이 SharedPreferences에 영속

## 필터 구성 (9탭 그룹, 14종 필터, AND 연산)
좌우 2패널 레이아웃: 왼쪽 카테고리 목록(9개) + 오른쪽 상세 옵션
같은 카테고리 내: OR / 다른 카테고리 간: AND

### 왼쪽 탭 → 오른쪽 패널 구성
| # | 탭 | 오른쪽 패널 |
|---|-----|-----------|
| 0 | 비자 | 비자 그룹(E/H/F/D/C별 접두어 구분) + 비자지원 토글 |
| 1 | 직종 | 직종 칩 (DB 동적) |
| 2 | 고용형태 | 고용형태 칩 (DB 동적) |
| 3 | 지역 | 지역 칩 (DB 동적) |
| 4 | 급여 | 급여유형 칩 (시급/일급/월급/연봉) |
| 5 | 근무요일 | 3그룹: 협의·주말 / 월~금·월~토·월~일 / 주6일~주1일 |
| 6 | 지원자격 | 성별(단일선택) + 학력(고정코드 다국어) + 경력(고정코드 다국어) |
| 7 | 한국어 | 한국어능력 칩 (DB 동적) |
| 8 | 복리후생 | 복리후생 칩 (DB 동적) |

### 필터 상세
- 비자: visa_master (visaIds) — E/H/F/D/C 그룹별 표시, 'ANY' = 비자 무관
- 비자지원: boolean 토글 (visaSponsorship)
- 직종: job_categories (categoryIds)
- 고용형태: employment_types (employmentTypeIds)
- 지역: regions 시/도 레벨 (regionNames)
- 급여유형: salaryTypes (hourly/daily/monthly/annual)
- 근무요일: work_schedules (workScheduleIds)
- 성별: gender (male/female/any, 단일선택)
- 학력: educations (none/middle_school/high_school/college/bachelor/master/doctor, 앱 다국어)
- 경력: experiences (none/newcomer/1y/3y/5y/10y, 앱 다국어)
- 한국어능력: korean_levels (koreanLevelIds)
- 복리후생: benefits (benefitIds)

선택된 필터: 결과보기 버튼 위에 칩 표시 (× 개별 해제)
결과보기: jobTotalCountProvider로 전체 건수 표시
광고 배너: 필터 헤더 아래에 배치

## 홈 화면
- [DEV] 사이트 필터: 검색바 아래 가로 스크롤 탭 (All + 각 사이트), selectedSiteIdProvider
- 필터 칩: 사이트 필터 아래, × 삭제 가능 (비자/직종/지역/급여/고용형태)
- 필터 버튼: carrot 배경 + 흰색, 활성 시 카운트 뱃지
- 즐겨찾기 아이콘: 언어 버튼 왼쪽, carrot 채움 하트
- Total 건수: 서버에서 전체 건수 조회 (jobTotalCountProvider), carrot 색상 숫자
- 최신순 라벨: Total 오른쪽 (crawled_at 기준 정렬)
- 무한 스크롤: 하단 200px 전에 다음 20개 자동 로드
- 필터/사이트/언어 변경 시 자동 리셋 (ListView key: ValueKey(langCode))
- 마감일 표시: ~M/D 형식 (예: ~4/19), 마감일 없으면 "상시"

## 공고 카드 구조
1. 모집명 (getTitle) + 사이트 뱃지 (회색 톤다운)
2. 회사명 (한 줄)
3. 주소 (getShortLocation, 별도 행)
4. 비자/직종/고용형태 태그 (한 줄 가로 스크롤)
5. 즐겨찾기 하트(왼쪽) + 마감일 ~M/D 형식(gray) + 급여(오른쪽, 다국어 포맷)

## 공고 상세 구조
1. 상단 바: 뒤로가기 + 제목 + 즐겨찾기 하트
2. 광고 배너
3. 모집명 + 회사명 + 비자 칩
4. 핵심 정보 테이블 (급여/근무요일/근무시간/고용형태/직종/마감일/근무지/출처)
   - 근무지: ko→한글, 그 외→영어 + "한글로 번역"/"English" 토글 버튼 (주소 아래 배치)
   - 출처: 사이트 이름 밑줄 + 클릭 시 사이트 홈페이지(sites.url)로 이동
5. 상세내용 (getDescriptionHtml → flutter_html로 HTML 렌더링, plaintext 폴백)
6. 면책고지 (가운데 정렬)
7. 하단: [지원하기] → 전면 광고(Interstitial) → 외부 브라우저
   - [DEV] 전면 광고 비활성화, TODO 주석으로 표시

## 즐겨찾기
- FavoriteProvider: SharedPreferences, jobId + addedAt 저장
- 홈 카드 / 상세 / 검색 결과에서 하트 토글
- 즐겨찾기 화면 (/favorites):
  - 마감일 지나도 표시
  - 정렬: 마감일순 / 등록순 (바텀시트 리스트)
  - 편집 모드: 체크박스 → 다중 삭제

## 검색
- 최근 검색어 5개 (SharedPreferences, 개별/전체 삭제)
- 타이핑 중: 최근 검색어 필터 + "'query' 검색" 옵션
- 검색 실행: 키보드 submit 또는 추천어 탭 (실시간 아님)
- 유사도 검색: search_jobs_fuzzy RPC (pg_trgm, 오타 허용)
  - 검색 대상: title, company, title_translations(lang/en/ko), description_translations(lang)
  - 유사도 높은 순 정렬
- 검색어 최대 50자 제한
- 무한 스크롤 (페이지네이션)
- Total 건수: carrot 색상 숫자 (홈과 동일 스타일)
- 정렬: 정확도순/최신순/급여높은순 (바텀시트 리스트)
- 안내 텍스트: "회사명은 한국어 또는 영어로 검색해주세요" (다국어)

## 광고 (AdMob, 테스트 ID 사용 중)
- 배너 (BannerAd): 홈 최상단+3카드마다, 검색 최상단+3카드마다, 즐겨찾기 최상단, 상세 최상단, 필터 헤더 아래
- 전면 (InterstitialAd): 지원하기 탭 직후 → 닫으면 외부 URL 이동 [DEV: 비활성화]
- 앱 오픈 (AppOpenAd): 재실행 시 스플래시 후 표시 (하루 1회, SharedPreferences) [DEV: 비활성화]
- 출처 사이트 클릭: 전면 광고 → 사이트 홈페이지 이동 [DEV: 비활성화]
- 최초 설치 시: 광고 없음 (온보딩 → 홈)
- 모든 배너 가운데 정렬

## Analytics (Supabase analytics_events 테이블)
- AnalyticsService: 싱글턴, session_id(앱 실행마다 생성)
- 추적 이벤트: screen_view, language_selected, visa_selected, location_permission, job_card_tap, filter_opened/applied/reset, search_executed, job_detail_view, apply_tap, apply_ad_shown, favorite_added/removed, favorites_opened, language_changed, site_filter_tap
- fire-and-forget (실패해도 앱 영향 없음)

## 백키 처리
- 언어선택·홈: 앱 종료
- 비자선택: 언어선택
- 위치권한: 비자선택
- 필터: 닫힘
- 검색·상세·즐겨찾기: 이전 화면

## 현재 구현 상태 (2026-04-19 기준)

### 전체 파일 구현 완료

| 파일 | 요약 |
|------|------|
| `lib/main.dart` | Supabase + MobileAds 초기화 |
| `lib/app.dart` | GoRouter 9개 라우트 + 28 locale |
| `core/constants/colors.dart` | carrot/gray/tag 색상 팔레트 |
| `core/theme/app_theme.dart` | Material3 라이트 테마 |
| `core/l10n/app_strings.dart` | 다국어 문자열 (28개 언어 전체 번역, 급여포맷, 학력/경력 코드 매핑) |
| `core/l10n/l10n_provider.dart` | stringsProvider |
| `data/models/job.dart` | Job + 조인 모델 8종 + SalaryType 7종 + jsonb 번역 5종 + 다국어 급여 + getDescriptionHtml |
| `data/models/filter_state.dart` | 14종 필터 + FilterOption + FilterCounts |
| `data/repositories/job_repository.dart` | 조인 쿼리(sites url 포함) + AND 필터 14종 + 유사도 검색 RPC + 전체 건수 |
| `data/services/location_service.dart` | GPS 권한 + 역지오코딩 |
| `data/services/analytics_service.dart` | 이벤트 추적 (Supabase, session_id) |
| `data/services/app_open_ad_service.dart` | 앱 오픈 광고 (하루 1회) |
| `providers/job_provider.dart` | FilterStateNotifier (14종 필터 영속) + 필터 옵션/카운트/전체건수 프로바이더 |
| `providers/search_provider.dart` | 검색 + 최근 검색어 5개 (영속) |
| `providers/favorite_provider.dart` | 즐겨찾기 toggle/remove/removeMultiple (영속) |
| `providers/language_provider.dart` | 28개 언어 + SharedPreferences |
| `features/splash/splash_screen.dart` | 1.5초 → 온보딩/홈 분기 |
| `features/onboarding/language_select_screen.dart` | 28개 언어 선택 → 비자선택 |
| `features/onboarding/visa_select_screen.dart` | 비자 복수선택 → 위치권한 |
| `features/onboarding/location_permission_screen.dart` | GPS 권한 UI |
| `features/home/home_screen.dart` | 무한 스크롤 + 필터칩(×삭제) + 전체건수 + 즐겨찾기 |
| `features/home/widgets/job_card.dart` | 카드 (하트 + 가로 스크롤 태그 + 사이트 톤다운 + 다국어 급여) |
| `features/home/widgets/skeleton_card.dart` | 로딩 스켈레톤 |
| `features/home/widgets/ad_banner.dart` | AdMob 배너 |
| `features/filter/filter_screen.dart` | 좌우 2패널 9탭 그룹 필터 + 비자 그룹핑 + 급여유형 + 지원자격 + 근무요일 3그룹 + 광고 배너 |
| `features/favorites/favorites_screen.dart` | 정렬(마감일/등록순) + 편집 삭제 + 만료 공고 포함 |
| `features/search/search_screen.dart` | 최근검색어 + 추천 + 유사도 검색 + 무한 스크롤 + carrot 숫자 |
| `features/job_detail/job_detail_screen.dart` | 상세 정보 + 즐겨찾기 하트 + HTML 설명 렌더링 + 주소 한/영 토글 + 출처 사이트 링크 |

### DB 타입 반영 — 전체 완료

| 항목 | Dart 타입 |
|------|-----------|
| `job_category_id` (uuid) | `String?` |
| `employment_type_id` (uuid) | `String?` |
| `region_id` (bigint) | `int?` |
| `korean_level_id` (bigint) | `int?` |
| `work_schedule_id` (bigint) | `int?` |
| `salary_type` (text) | `String?` (salaryTypeRaw) |
| `salary_amount` (integer) | `int?` |
| `gender` (text) | FilterState.gender |
| `education` (text) | FilterState.educations |
| `experience` (text) | FilterState.experiences |
| `job_languages` junction | `JobLanguageInfo(languageId: int, proficiency: String?)` |
| `title_translations` (jsonb) | `Map<String, dynamic>` |
| `job_type_translations` (jsonb) | `Map<String, dynamic>` |
| `description_translations` (jsonb) | `Map<String, dynamic>` |
| `address_translations` (jsonb) | `Map<String, dynamic>` |
| `work_model_translations` (jsonb) | `Map<String, dynamic>` |

### [DEV] 프로덕션 배포 시 복원 필요 (TODO 검색)
- `job_detail_screen.dart`: 지원하기 전면 광고
- `job_detail_screen.dart`: 출처 클릭 전면 광고
- `splash_screen.dart`: 앱 오픈 광고
