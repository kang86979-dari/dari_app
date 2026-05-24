# Dari App Test Specification

## 테스트 범위
- API 기능 테스트 (RPC/REST)
- 다국어 번역 검증 (17개 언어)
- 앱 문자열 완전성 검증
- 데이터 품질 검증
- UI 통합 테스트

## 지원 언어 (17개)
en, zh, vi, th, uz, km, ne, fil, id, my, mn, ja, si, bn, ru, hi, ko

---

## 1. API 기능 테스트

### F-01: 홈 목록 로드
- **RPC**: get_jobs_page(p_lang, p_limit=20, p_offset=0)
- **기대결과**:
  - 응답 배열 길이 > 0, <= 20
  - 각 row에 job_data(jsonb), total_count(bigint) 존재
  - job_data 필수 필드: id, site_id, title, company, salary_type, url
  - total_count > 0
  - total_count가 모든 row에서 동일
- **심각도**: Critical

### F-02: 페이지네이션
- **RPC**: get_jobs_page(p_offset=0) → get_jobs_page(p_offset=20)
- **기대결과**:
  - page 1과 page 2의 job_data.id가 겹치지 않음
  - page 2 결과도 <= 20건
  - crawled_at 기준 page 1 > page 2 (최신순)
- **심각도**: Critical

### F-03: 필터 — 비자 단일
- **RPC**: get_jobs_page(p_visa_ids=['E-9 visa UUID'])
- **기대결과**:
  - 결과 > 0건
  - total_count < 필터 없는 total_count
- **심각도**: High

### F-04: 필터 — 지역
- **RPC**: get_jobs_page(p_region_ids=[서울 region_id])
- **기대결과**:
  - 결과 > 0건
  - 반환된 공고의 region_id가 모두 서울
- **심각도**: High

### F-05: 필터 — 복합 (비자 + 지역)
- **RPC**: get_jobs_page(p_visa_ids=[...], p_region_ids=[...])
- **기대결과**:
  - 결과 건수 <= 비자만 필터 건수
  - 결과 건수 <= 지역만 필터 건수
  - AND 조건 확인
- **심각도**: High

### F-06: 필터 — 급여유형
- **RPC**: get_jobs_page(p_salary_types=['monthly'])
- **기대결과**:
  - 반환된 모든 공고의 salary_type = 'monthly'
- **심각도**: High

### F-07: 필터 — 고용형태
- **RPC**: get_jobs_page(p_employment_ids=[정규직 UUID])
- **기대결과**:
  - 반환된 모든 공고의 employment_type_id = 정규직 UUID
- **심각도**: High

### F-08: 필터 — 사이트
- **RPC**: get_jobs_page(p_site_ids=[Jobploy UUID])
- **기대결과**:
  - 반환된 모든 공고의 site_id = Jobploy UUID
- **심각도**: High

### F-09: 필터 — 빈 결과
- **RPC**: get_jobs_page(p_region_ids=[존재하지않는ID])
- **기대결과**:
  - 결과 0건
  - total_count = 0
- **심각도**: Medium

### F-10: 정렬 — 최신순
- **RPC**: get_jobs_page(p_sort_by='latest')
- **기대결과**:
  - 결과의 crawled_at이 내림차순 (첫 번째 > 마지막)
- **심각도**: High

### F-11: 정렬 — 급여순
- **RPC**: get_jobs_page(p_sort_by='salary_desc')
- **기대결과**:
  - salary_amount가 내림차순 (NULL은 마지막)
- **심각도**: Medium

### F-12: 검색 — 한국어
- **RPC**: search_jobs_fuzzy(search_query='용접', lang_code='ko')
- **기대결과**:
  - 결과 > 0건
  - job_data.title 또는 job_data.company에 '용접' 포함
- **심각도**: Critical

### F-13: 검색 — 영어
- **RPC**: search_jobs_fuzzy(search_query='welding', lang_code='en')
- **기대결과**:
  - 결과 > 0건
  - title_translations->>'en'에 'weld' 포함 (부분 매칭)
- **심각도**: Critical

### F-14: 검색 — 결과 없음
- **RPC**: search_jobs_fuzzy(search_query='zzzzxxxxxyyyyy', lang_code='ko')
- **기대결과**:
  - 결과 = 0건
- **심각도**: Low

### F-15: 검색 — 정렬
- **RPC**: search_jobs_fuzzy(sort_by='latest') vs search_jobs_fuzzy(sort_by='relevance')
- **기대결과**:
  - latest: posted_at/crawled_at 내림차순
  - relevance: score 내림차순
- **심각도**: Medium

### F-16: 상세 조회
- **REST**: jobs?select=*,...&id=eq.[valid_id]
- **기대결과**:
  - 1건 반환
  - description 필드 존재 (null 아님)
  - title_translations, description_translations 존재
  - 조인 데이터 (sites, regions, visas 등) 포함
- **심각도**: Critical

### F-17: 상세 — 존재하지 않는 ID
- **REST**: jobs?id=eq.[fake_uuid]
- **기대결과**:
  - 0건 또는 null
- **심각도**: Low

### F-18: 즐겨찾기 조회
- **REST**: jobs?select=*,...&id=in.([id1, id2])
- **기대결과**:
  - 요청한 ID만큼 반환
  - 만료된 공고도 포함 (is_active 무관)
- **심각도**: High

### F-19: 중복 출처 조회
- **REST**: jobs?duplicate_group_id=eq.[group_id]&is_active=eq.true
- **기대결과**:
  - 2건 이상 반환
  - 각 공고의 site_id가 서로 다름
- **심각도**: Medium

### F-20: Total Count 일관성
- **RPC**: get_jobs_page(p_limit=1) vs get_jobs_page(p_limit=20)
- **기대결과**:
  - 두 요청의 total_count가 동일
- **심각도**: High

### F-21: Edge Function — 번역
- **POST**: /functions/v1/translate-description
- **Body**: { "job_id": "[valid_id]", "lang": "ja" }
- **기대결과**:
  - status 200
  - description 필드 존재, 비어있지 않음
  - cached: true 또는 false
- **심각도**: High

---

## 2. 다국어 번역 검증

### 문자 감지 규칙
| 언어 | 유니코드 범위 | 검증 방식 |
|------|-------------|----------|
| ko | \uAC00-\uD7AF (한글) | 한글 포함 여부 |
| ja | \u3040-\u30FF (히라가나/카타카나) | 히라/카타 포함 |
| zh | \u4E00-\u9FFF (한자) + ko 아닌 것 | 한자 포함, 히라 미포함 |
| th | \u0E00-\u0E7F | 태국 문자 포함 |
| vi | \u00C0-\u024F (라틴 확장) | 베트남 특수문자 포함 (ă, ơ, ư 등) |
| ru | \u0400-\u04FF | 키릴 문자 포함 |
| hi | \u0900-\u097F | 데바나가리 포함 |
| bn | \u0980-\u09FF | 벵골 문자 포함 |
| ne | \u0900-\u097F | 데바나가리 포함 (hi와 동일 범위) |
| km | \u1780-\u17FF | 크메르 문자 포함 |
| my | \u1000-\u109F | 미얀마 문자 포함 |
| mn | \u0400-\u04FF | 키릴 문자 포함 (ru와 동일) |
| si | \u0D80-\u0DFF | 싱할라 문자 포함 |
| uz | 라틴 문자 | 라틴 알파벳 |
| fil | 라틴 문자 | 라틴 알파벳 |
| id | 라틴 문자 | 라틴 알파벳 |
| en | 라틴 문자 | 라틴 알파벳 |

### L-01: 홈 목록 타이틀 번역 (언어별)
- **대상**: 17개 언어 각각
- **RPC**: get_jobs_page(p_lang=[lang], p_limit=20)
- **기대결과**:
  - ko: title_translated = NULL, title(원문) 한글 포함
  - 기타: title_translated != NULL
  - title_translated에 해당 언어 문자 포함 (위 규칙 적용)
  - title_translated에 한국어(한글)만 있으면 실패
  - title_translated가 다른 언어이면 실패 (ja인데 베트남어 등)
- **허용 예외**: 원문이 영어인 공고 (예: "K-pop Content Intern")
- **심각도**: Critical
- **테스트 수**: 17개 언어 × 20건 = 340건

### L-02: 주소 번역
- **RPC**: get_jobs_page(p_lang=[lang])
- **기대결과**:
  - ko: address_translated = NULL
  - 기타: address_en != NULL (영어 주소)
  - address_translated 또는 address_en 중 하나 존재
- **허용 예외**: address_detail이 비어있는 공고
- **심각도**: High

### L-03: 근무시간 번역
- **RPC**: get_jobs_page(p_lang=[lang])
- **기대결과**:
  - 숫자 패턴 (09:00~18:00)은 번역 불필요
  - 한국어 텍스트가 포함된 work_time은 번역 필요
  - work_time_translated 존재 시 해당 언어 문자 포함
- **심각도**: Medium

### L-04: 검색어 번역 매칭 (12개 키워드 × 17개 언어)
- **대상**: 용접, 공장, 배달, 청소, 식당, 개발자, 삼성, CU, 삼성SDI, 부산, 일용직, 비자
- **기대결과**:
  - ko: 모든 키워드 > 0건
  - 기타: 주요 키워드 (공장, 청소, 식당) > 0건
  - 결과 0건이면 실패 (CU, 삼성SDI 제외 — 브랜드명은 번역 한계)
- **심각도**: High
- **테스트 수**: 12 × 17 = 204건

### L-05: 고정 번역 — 직종 (job_categories)
- **대상**: 11개 직종 × 17개 언어
- **검증**: AppStrings.translateJobCategory(nameEn) 호출 시
  - 반환값 != nameEn (번역됨) 또는 langCode == 'en'
  - 해당 언어 문자 포함
- **심각도**: High

### L-06: 고정 번역 — 고용형태 (employment_types)
- **대상**: 8개 × 17개 언어
- **검증**: 동일
- **심각도**: High

### L-07: 고정 번역 — 근무요일 (work_schedules)
- **대상**: 9개 × 17개 언어
- **심각도**: High

### L-08: 고정 번역 — 한국어능력 (korean_levels)
- **대상**: 5개 × 17개 언어
- **심각도**: High

### L-09: 고정 번역 — 복리후생 (benefits)
- **대상**: 5개 × 17개 언어
- **심각도**: High

### L-10: ko 언어 — 원문 표시
- **RPC**: get_jobs_page(p_lang='ko')
- **기대결과**:
  - title_translated = NULL
  - address_translated = NULL
  - description_translated = NULL
  - work_time_translated = NULL
  - title(원문)이 한글 포함
- **심각도**: Critical

### L-11: en fallback
- **RPC**: get_jobs_page(p_lang='si') (번역 커버리지 낮은 언어)
- **기대결과**:
  - title_translated가 NULL이면 title_en이 존재
  - title_en이 영어 문자 포함
- **심각도**: High

---

## 3. 앱 문자열 완전성 검증

### S-01: app_strings.dart 모든 getter 검증
- **검증**: 각 _t({...}) 호출에 17개 언어 키 전부 존재
- **기대결과**:
  - 빠진 언어 키 = 0개
  - 빈 문자열 = 0개
- **심각도**: Critical

### S-02: translateJobCategory 완전성
- **검증**: 11개 항목 × 17개 언어 = 187개 번역
- **기대결과**: 모든 조합에서 번역 존재 (nameEn 반환 아닌 것)
- **심각도**: High

### S-03: translateEmploymentType 완전성
- **검증**: 8개 × 17개 = 136개
- **심각도**: High

### S-04: translateWorkSchedule 완전성
- **검증**: 9개 × 17개 = 153개
- **심각도**: High

### S-05: translateKoreanLevel 완전성
- **검증**: 5개 × 17개 = 85개
- **심각도**: High

### S-06: translateBenefit 완전성
- **검증**: 5개 × 17개 = 85개
- **심각도**: High

---

## 4. 데이터 품질 검증

### D-01: job_type에 급여 정보 혼입
- **쿼리**: job_type ILIKE '%연봉%' OR '%월급%' OR '%시급%' OR '%만원%' OR '%원/%'
- **기대결과**: 0건
- **심각도**: High

### D-02: job_type 길이 초과
- **쿼리**: length(job_type) > 50
- **기대결과**: 0건 (카드 칩에 표시 불가)
- **심각도**: Medium

### D-03: title 빈값
- **쿼리**: title IS NULL OR title = '' (is_active=true)
- **기대결과**: 0건
- **심각도**: Critical

### D-04: salary_amount 이상값
- **쿼리**: salary_amount <= 0 OR salary_amount > 100000000
- **기대결과**: 0건
- **심각도**: Medium

### D-05: 원문이 한국어가 아닌 공고
- **쿼리**: title에 한글(\uAC00-\uD7AF) 미포함 + is_active=true
- **기대결과**: 해당 공고 목록 (0건이 이상적)
- **심각도**: Medium

### D-06: job_category_id 미매핑
- **쿼리**: job_category_id IS NULL AND is_active=true
- **기대결과**: 해당 공고 수 집계 (0건이 이상적)
- **심각도**: High

### D-07: address_detail 빈값
- **쿼리**: (address_detail IS NULL OR address_detail = '') AND is_active=true
- **기대결과**: 해당 공고 수 집계
- **심각도**: Medium

### D-08: 번역 언어 불일치
- **검증**: 각 언어별 title_translations->>[lang]에 해당 언어 문자 포함 여부
- **샘플**: 언어별 100건
- **기대결과**: 불일치 비율 < 5%
- **심각도**: High

### D-09: 만료 공고 활성 상태
- **쿼리**: expires_at < CURRENT_DATE AND is_active=true
- **기대결과**: 0건
- **심각도**: High

### D-10: 중복 그룹 단일 공고
- **쿼리**: duplicate_group_id별 count = 1인 그룹
- **기대결과**: 0건 (그룹이면 2건 이상이어야)
- **심각도**: Medium

### D-11: work_time 형식 검증
- **검증**: 숫자가 아닌 한국어만 포함된 work_time
- **기대결과**: 해당 공고에 work_time_translations 존재
- **심각도**: Medium

### D-12: salary_type 유효값
- **쿼리**: salary_type NOT IN ('hourly','daily','monthly','annual','company_rule','negotiable') AND salary_type IS NOT NULL
- **기대결과**: 0건
- **심각도**: Medium

### D-13: site_id 유효성
- **쿼리**: site_id NOT IN (SELECT id FROM sites)
- **기대결과**: 0건
- **심각도**: High

---

## 테스트 요약

| 카테고리 | 테스트 수 | Critical | High | Medium | Low |
|---------|----------|----------|------|--------|-----|
| API 기능 | 21 | 5 | 10 | 4 | 2 |
| 다국어 번역 | 11 (×17언어) | 2 | 7 | 1 | 0 |
| 앱 문자열 | 6 | 1 | 5 | 0 | 0 |
| 데이터 품질 | 13 | 1 | 5 | 6 | 0 |
| **합계** | **51** | **9** | **27** | **11** | **2** |

실제 테스트 케이스 수 (언어/키워드 조합 포함): **약 1,000건+**
