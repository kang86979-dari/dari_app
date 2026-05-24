# Dari 테스트 계획서

> 작성일: 2026-04-27
> 상태: 미실행

---

## 트랙 1: Dart 테스트 (코드 로직)

### 1-1. Job 모델 — getTitle() 폴백

| # | title | translations | lang | 기대결과 |
|---|-------|-------------|------|----------|
| 1 | `'한국어제목'` | `{'en':'Eng','vi':'Viet'}` | `'ko'` | `'한국어제목'` |
| 2 | `'한국어제목'` | `{'en':'Eng','vi':'Viet'}` | `'vi'` | `'Viet'` |
| 3 | `'한국어제목'` | `{'en':'Eng','vi':'Viet'}` | `'fr'` | `'Eng'` (en 폴백) |
| 4 | `'한국어'` | `{}` | `'en'` | `'한국어'` (원문 폴백) |
| 5 | `null` | `{}` | `'ko'` | `''` |

### 1-2. Job 모델 — getAddress() 폴백

| # | addressDetail | addressTranslations | region | lang | 기대결과 |
|---|--------------|-------------------|--------|------|----------|
| 1 | `'서울시 강남구'` | - | - | `'ko'` | `'서울시 강남구'` |
| 2 | - | `{'en':'Gangnam, Seoul'}` | - | `'en'` | `'Gangnam, Seoul'` |
| 3 | - | `{}` | `RegionInfo(siName:'서울',guName:'강남구')` | `'en'` | `'강남구, 서울'` |

### 1-3. Job 모델 — getShortLocation()

| # | addressDetail | addressTranslations | lang | 기대결과 |
|---|--------------|-------------------|------|----------|
| 1 | `'경기 성남시 수정구 탄리로'` | - | `'ko'` | `'경기 성남시'` |
| 2 | - | `{'en':'123 Main St, Sujeong, Seongnam, Gyeonggi'}` | `'en'` | `'Seongnam, Gyeonggi'` |
| 3 | - | `{'en':'Seoul'}` | `'en'` | `'Seoul'` |
| 4 | `'서울'` | - | `'ko'` | `'서울'` (1단어) |
| 5 | `null` | `{}` | `'ko'` | `''` (전부 없음) |

### 1-4. Job 모델 — salaryType getter

| # | salaryTypeRaw | salary | 기대결과 |
|---|--------------|--------|----------|
| 1 | `'hourly'` | - | `SalaryType.hourly` |
| 2 | `'monthly'` | - | `SalaryType.monthly` |
| 3 | `'annual'` | - | `SalaryType.annual` |
| 4 | `'daily'` | - | `SalaryType.daily` |
| 5 | `'company_rule'` | - | `SalaryType.companyRule` |
| 6 | `'negotiable'` | - | `SalaryType.negotiable` |
| 7 | `null` | `'시급 10,030원'` | `SalaryType.hourly` |
| 8 | `null` | `'연봉 3000만원'` | `SalaryType.annual` |
| 9 | `null` | `'200만원'` | `SalaryType.monthly` (기본값) |
| 10 | `null` | `null` | `SalaryType.unknown` |

### 1-5. Job 모델 — getDescriptionHtml()

| # | description | descTranslations | lang | 기대결과 |
|---|------------|-----------------|------|----------|
| 1 | `'줄1\n줄2'` | `{}` | `null` | `'줄1<br>줄2'` |
| 2 | `'텍스트'` | `{'en':'<p>Hello</p>'}` | `'en'` | `'<p>Hello</p>'` |
| 3 | `'텍스트\\n줄바꿈'` | `{}` | `'ko'` | `'텍스트<br>줄바꿈'` |
| 4 | `'텍스트'` | `{'en':''}` | `'en'` | `'텍스트'` (빈 번역은 원문) |

### 1-6. Job 모델 — displayWorkTime

| # | workStartTime | workEndTime | workTime | 기대결과 |
|---|--------------|-------------|----------|----------|
| 1 | `'09:00:00'` | `'18:00:00'` | - | `'09:00 - 18:00'` |
| 2 | `null` | `null` | `'주간'` | `'주간'` |
| 3 | `null` | `null` | `null` | `''` |

### 1-7. Job.fromJson() 파싱

| # | 테스트 | 기대결과 |
|---|--------|----------|
| 1 | 전체 필드 JSON | 모든 필드 정상 매핑 |
| 2 | job_visas 조인 | `visas.length == 2`, code 확인 |
| 3 | regions 조인 | `region.siName == '서울'` |
| 4 | 최소 JSON `{'id':'1','site_id':'s1'}` | null 기본값, 빈 리스트 |
| 5 | salary_amount가 String `'10000'` | `int 10000`으로 파싱 |

### 1-8. FilterState

| # | 테스트 | 기대결과 |
|---|--------|----------|
| 1 | `FilterState.empty.isEmpty` | `true` |
| 2 | `FilterState(visaIds:{'v1'}).isEmpty` | `false` |
| 3 | `FilterState(visaIds:{'v1','v2'}, gender:'male').activeCount` | `3` |
| 4 | `copyWith(gender:'female')` | gender 변경, 나머지 유지 |
| 5 | `copyWith(clearGender: true)` | gender → `null` |
| 6 | `copyWith(clearVisaSponsorship: true)` | visaSponsorship → `null` |
| 7 | `toJson()` → `fromJson()` 왕복 | `==` true |
| 8 | 동일 필터 `==` 비교 | `true` |
| 9 | 다른 필터 `==` 비교 | `false` |

### 1-9. RegionMapper

| # | 메서드 | 입력 | 기대결과 |
|---|--------|------|----------|
| 1 | `getLocalizedName` | `'서울', 'ko'` | `'서울'` |
| 2 | `getLocalizedName` | `'서울', 'en'` | `'Seoul'` |
| 3 | `getLocalizedName` | `'경기도', 'en'` | `'Gyeonggi'` |
| 4 | `getLocalizedName` | `'없는지역', 'en'` | `'없는지역'` |
| 5 | `fromCoordinates` | `37.5665, 126.978` | `'서울'` |
| 6 | `fromCoordinates` | `33.499, 126.531` | `'제주'` |
| 7 | `fromLocationText` | `'서울시 강남구'` | `'서울'` |
| 8 | `fromLocationText` | `'대전 서구'` | `'대전·세종'` |
| 9 | `fromLocationText` | `'미국 뉴욕'` | `null` |

### 1-10. 급여 포맷 (AppStrings.formatSalary)

**한국어 (ko)**
| # | salaryTypeRaw | amount | 기대결과 |
|---|--------------|--------|----------|
| 1 | `'monthly'` | `2000000` | `'월급 200만원'` |
| 2 | `'hourly'` | `10030` | `'시급 10,030원'` |
| 3 | `'annual'` | `30000000` | `'연봉 3,000만원'` |
| 4 | `'daily'` | `80000` | `'일급 8만원'` |
| 5 | `'monthly'` | `2500000` | `'월급 2,500,000원'` (만원 안 나눠짐) |
| 6 | `'monthly'` | `0` | `'월급 0원'` (크래시 안 남) |

**일본어 (ja)**
| # | salaryTypeRaw | amount | 기대결과 |
|---|--------------|--------|----------|
| 7 | `'monthly'` | `2000000` | `'月給 200万ウォン'` |
| 8 | `'hourly'` | `10030` | `'時給 10,030ウォン'` |

**중국어 (zh)**
| # | salaryTypeRaw | amount | 기대결과 |
|---|--------------|--------|----------|
| 9 | `'monthly'` | `2000000` | `'月薪 200万韩元'` |

**독일어 (de)**
| # | salaryTypeRaw | amount | 기대결과 |
|---|--------------|--------|----------|
| 10 | `'monthly'` | `2000000` | `'₩2.000.000 / Monatlich'` |

**힌디 (hi)**
| # | salaryTypeRaw | amount | 기대결과 |
|---|--------------|--------|----------|
| 11 | `'monthly'` | `2000000` | `'₩20,00,000 / मासिक'` |

**영어 (en)**
| # | salaryTypeRaw | amount | 기대결과 |
|---|--------------|--------|----------|
| 12 | `'monthly'` | `2000000` | `'₩2,000,000 / Monthly'` |
| 13 | `'hourly'` | `10030` | `'₩10,030 / Hourly'` |

**아랍어 (ar)**
| # | salaryTypeRaw | amount | 기대결과 |
|---|--------------|--------|----------|
| 14 | `'monthly'` | `2000000` | `'شهري ₩2,000,000'` |

### 1-11. 다국어 문자열 검증 (AppStrings)

| # | 테스트 | 기대결과 |
|---|--------|----------|
| 1 | 17개 언어별 주요 키 빈 값 아닌지 (selectLanguage, salaryHourly, infoSalary 등) | `''` 없음 |
| 2 | 미지원 언어 `'xx'` → 아무 문자열 | 영어 fallback |
| 3 | 학력 코드 `'high_school'` → 17개 언어 | 각 언어 번역 반환 |
| 4 | 경력 코드 `'3y'` → 17개 언어 | 각 언어 번역 반환 |
| 5 | 직종/고용형태 번역 함수 → 17개 언어 | 빈 문자열 아님 |

### 1-12. FilterCounts

| # | 테스트 | 기대결과 |
|---|--------|----------|
| 1 | `fromJson()` 정상 파싱 | 각 카테고리 Map 정상 |
| 2 | `getCount('visa', 'v1')` | 해당 건수 반환 |
| 3 | `getCount('visa', '없는id')` | `0` |
| 4 | `fromJson({})` | 모든 Map 빈 상태, visaSponsorship=0 |

---

## 트랙 1-B: 위젯 테스트

### 1-13. JobCard 필드 바인딩

| # | 테스트 | 기대결과 |
|---|--------|----------|
| 1 | 제목 위치에 `getTitle()` 결과 표시 | `find.text('개발자 모집')` 존재 |
| 2 | 회사명 위치에 company 표시 | `find.text('ABC회사')` 존재 |
| 3 | 태그 Row에 직종명 표시 | `find.text('제조업')` 존재 |
| 4 | 태그 Row에 급여 텍스트 없음 | `'월급 200만원'`이 태그 안에 없음 |
| 5 | 하단에 급여 표시 | `find.text('월급 200만원')` 존재 |
| 6 | 비자 태그 표시 | `find.text('E-9')` 존재 |
| 7 | 마감일 포맷 | `find.text('~4/19')` 존재 |
| 8 | jobCategory=null | 직종 태그 안 나옴 |
| 9 | salaryType=companyRule | 하단에 `'회사 내규'`(ko) 표시 |
| 10 | 즐겨찾기 하트 토글 | 탭 시 콜백 호출 |

### 1-14. UI 오버플로우 (7언어 x 4해상도)

**언어**: ko, en, ru, bn, my, ar, km
**해상도**: 320x568, 375x812, 428x926, 768x1024

| # | 대상 화면 | 검증 |
|---|----------|------|
| 1 | JobCard (긴 제목 50자 + 긴 급여) | 28조합 오버플로우 없음 |
| 2 | FilterScreen 탭 텍스트 | 28조합 잘림 없음 |
| 3 | JobDetailScreen 테이블 | 28조합 셀 깨짐 없음 |
| 4 | SearchScreen | 28조합 오버플로우 없음 |

---

## 트랙 2: DB 직접 검증 (Supabase SQL)

### 2-1. 데이터 품질 — salary

| # | SQL 검증 | 이상 기준 |
|---|---------|----------|
| 1 | `salary_type NOT IN ('hourly','daily','monthly','annual','company_rule','negotiable')` | 허용값 외 존재 |
| 2 | `salary_amount < 0` | 음수 |
| 3 | `salary_type='hourly' AND salary_amount > 1000000` | 시급 100만원 이상 (비현실적) |
| 4 | `salary_type IS NOT NULL AND salary_amount IS NULL` (또는 반대) | 짝 불일치 |

### 2-2. 데이터 품질 — 필수값/포맷

| # | SQL 검증 | 이상 기준 |
|---|---------|----------|
| 5 | `is_active=true AND title IS NULL` | 제목 없는 활성 공고 |
| 6 | `is_active=true AND url IS NULL` | 지원 URL 없음 |
| 7 | `gender NOT IN ('male','female','any')` (NULL 제외) | 허용값 외 |
| 8 | `education NOT IN (허용 코드)` (NULL 제외) | 허용값 외 |
| 9 | `experience NOT IN (허용 코드)` (NULL 제외) | 허용값 외 |
| 10 | `expires_at`가 파싱 불가 | 날짜 아닌 문자열 |

### 2-3. 데이터 품질 — FK 정합성

| # | SQL 검증 | 이상 기준 |
|---|---------|----------|
| 11 | `region_id`가 `regions.id`에 없음 | 고아 FK |
| 12 | `job_category_id`가 `job_categories.id`에 없음 | 고아 FK |
| 13 | `employment_type_id`가 `employment_types.id`에 없음 | 고아 FK |
| 14 | `is_active=true`인 공고에 job_visas 없음 | 비자 정보 누락 |

### 2-4. 데이터 품질 — 중복/정합성

| # | SQL 검증 | 이상 기준 |
|---|---------|----------|
| 15 | `is_active=true AND is_duplicate=true` | 중복인데 노출 |
| 16 | `is_active=true AND is_translated=false` | 미번역인데 노출 |

### 2-5. 다국어 번역 — DB jsonb

| # | SQL 검증 | 이상 기준 |
|---|---------|----------|
| 17 | `title_translations`에 17개 언어 키 중 누락 | 특정 언어 번역 없음 |
| 18 | `description_translations` 동일 | 번역 누락 |
| 19 | `address_translations`에 `'en'` 키 없음 | 영어 주소 폴백 실패 |
| 20 | `work_model_translations` 누락 | 근무형태 미번역 |
| 21 | 번역 값이 빈 문자열 `""` | 키만 있고 내용 없음 |
| 22 | 번역 값이 한국어 원문과 동일 | 번역 안 됨 |
| 23 | description_translations HTML 태그 깨짐 (닫는 태그 누락) | `<p>내용</` |

### 2-6. 필터 — 카운트 정합성

| # | SQL 검증 | 이상 기준 |
|---|---------|----------|
| 24 | `get_filter_counts()` 비자별 카운트 vs 실제 `SELECT COUNT` | 불일치 |
| 25 | 전체 활성 공고 수 vs 홈 화면 Total 건수 로직 | 불일치 |
| 26 | 필터 적용 후 건수 vs 쿼리 결과 수 | 불일치 |

### 2-7. 검색 — 유사도/정렬/보안

| # | 검색어 | 기대 |
|---|--------|------|
| 27 | `'삼성'` | 관련 공고 반환 (0건 아님) |
| 28 | `'Samsung'` | 영어 title_translations 매칭 |
| 29 | `'삼선'` (오타) | pg_trgm 유사도로 매칭 |
| 30 | `''` (빈 문자열) | 크래시 없음 |
| 31 | 50자 초과 문자열 | 크래시 없음 |
| 32 | `'<script>alert(1)</script>'` | 인젝션 안 됨, 0건 |
| 33 | 정확도순 정렬 | 유사도 높은 것이 상위 |
| 34 | 최신순 정렬 | crawled_at DESC |
| 35 | 급여높은순 정렬 | salary_amount DESC |

---

## 트랙 1-C: 네비게이션/상태 테스트

### 1-15. 백키 처리

| # | 화면 | 백키 시 | 기대결과 |
|---|------|--------|----------|
| 1 | 언어선택 | `canPop: false` | 화면 유지 (앱 종료 영역) |
| 2 | 비자선택 | → 언어선택 | `/onboarding/language`로 이동 |
| 3 | 위치권한 | → 비자선택 | `/onboarding/visa`로 이동 |
| 4 | 필터 | → 닫힘 | `_cancel()` 호출, 필터 닫힘 |

### 1-16. 언어 변경 — 프로바이더

| # | 테스트 | 기대결과 |
|---|--------|----------|
| 1 | `setLanguage('vi')` → state | `'vi'` |
| 2 | `setLanguage('vi')` → SharedPreferences | `'vi'` 저장됨 |
| 3 | 앱 재시작 시뮬레이션 → `_loadSaved()` | 저장된 `'vi'` 복원 |

### 1-17. 언어 변경 — JobCard 렌더링

| # | 테스트 | 기대결과 |
|---|--------|----------|
| 1 | JobCard `lang='ko'` | 제목: 한국어 원문 |
| 2 | JobCard `lang='en'` | 제목: 영어 번역 |
| 3 | JobCard `lang='vi'` | 제목: 베트남어 번역 |
| 4 | 급여 `lang='ko'` → `'de'` | `'월급 200만원'` → `'₩2.000.000 / Monatlich'` |

### 1-18. 빈 상태 / 엣지 케이스

| # | 상황 | 기대결과 |
|---|------|----------|
| 1 | 검색 결과 0건 | 안내 문구 표시, 크래시 없음 |
| 2 | 즐겨찾기 0건 | 빈 상태 안내 표시 |
| 3 | 필터 결과 0건 | 안내 표시, "결과 0건" |
| 4 | 네트워크 오프라인 | 에러 표시, 크래시 없음 |
| 5 | 지원하기 URL이 null | 크래시 없음, 적절한 처리 |
| 6 | 무한 스크롤 마지막 페이지 | 중복 로드 없음, 로딩 종료 |
| 7 | 만료 공고 — 홈 | 표시 안 됨 |
| 8 | 만료 공고 — 즐겨찾기 | 흐리게 표시 + 만료 라벨 |
| 9 | 광고 로드 실패 | 레이아웃 깨지지 않음 |

### 수동 테스트 (실기기)

| # | 항목 | 확인 방법 |
|---|------|----------|
| 1 | 위치 기반 지역 매핑 | GPS 켜고 실제 위치 확인 |
| 2 | 온보딩 전체 플로우 | 앱 삭제 후 재설치 |
| 3 | 외부 URL 이동 | 지원하기 → 브라우저 열림 |
| 4 | 광고 실제 표시 | 배너/전면/앱오픈 확인 |
| 5 | 언어 변경 → 전체 화면 반영 | 설정 변경 후 홈/검색/필터/상세 눈으로 확인 |

---

## 실행 순서

1. **트랙 2 (DB)** — 데이터가 이상하면 코드 테스트도 의미 없음
2. **트랙 1 유닛 테스트** — Job 모델, FilterState, 급여 포맷, 다국어
3. **트랙 1 위젯 테스트** — JobCard 바인딩 + UI 오버플로우

---

## 요약

| 구분 | 테스트 수 | 방식 |
|------|----------|------|
| 1. 유닛 (모델/로직) | ~50건 | `flutter test` |
| 2. 위젯 (UI 바인딩) | ~10건 | `flutter test` |
| 3. UI 오버플로우 | ~28조합 x 4화면 | `flutter test` (golden) |
| 4. 네비게이션/상태 | ~16건 | `flutter test` |
| 5. 빈 상태/엣지 | ~9건 | `flutter test` |
| 6. DB 데이터 품질 | ~23건 | Supabase SQL |
| 7. 검색/필터 DB | ~12건 | Supabase SQL/RPC |
| 8. 수동 테스트 | ~5건 | 실기기 |
| **합계** | **~125건+** | |
