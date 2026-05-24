# 공고 조회 서버 필터링 요청

## 현재 문제
비자, 복리후생, 언어, 지역 필터가 **앱 클라이언트에서** 처리되고 있어 페이지네이션이 부정확합니다. 서버에서 100건 가져와 클라이언트에서 걸러내는 방식이라 적중률이 낮으면 결과가 0건 나오고 "더 없음"으로 조기 종료됩니다.

## 요청
아래 4개 필터를 서버 RPC 또는 DB 뷰에서 처리해주세요.

### 1. 비자 필터 (`visa_ids`)
```sql
-- junction 테이블: job_visas (job_id, visa_id)
-- 선택된 visa_id 중 하나라도 있는 공고만
WHERE jobs.id IN (
  SELECT job_id FROM job_visas 
  WHERE visa_id = ANY(visa_ids_param)
)
```

### 2. 복리후생 필터 (`benefit_ids`)
```sql
-- junction 테이블: job_benefits (job_id, benefit_id)
WHERE jobs.id IN (
  SELECT job_id FROM job_benefits 
  WHERE benefit_id = ANY(benefit_ids_param)
)
```

### 3. 언어 필터 (`language_ids`)
```sql
-- junction 테이블: job_languages (job_id, language_id)
WHERE jobs.id IN (
  SELECT job_id FROM job_languages 
  WHERE language_id = ANY(language_ids_param)
)
```

### 4. 지역 필터 (`region_names`)
```sql
-- jobs.region_id → regions.si_name
WHERE jobs.region_id IN (
  SELECT id FROM regions 
  WHERE si_name = ANY(region_names_param)
)
```

## 구현 방식 제안

### 방식 A — RPC 함수
```sql
CREATE OR REPLACE FUNCTION get_filtered_jobs(
  p_visa_ids       BIGINT[]  DEFAULT NULL,
  p_benefit_ids    BIGINT[]  DEFAULT NULL,
  p_language_ids   BIGINT[]  DEFAULT NULL,
  p_region_names   TEXT[]    DEFAULT NULL,
  p_category_ids   UUID[]    DEFAULT NULL,
  p_employment_ids UUID[]    DEFAULT NULL,
  p_korean_level_ids BIGINT[] DEFAULT NULL,
  p_work_schedule_ids BIGINT[] DEFAULT NULL,
  p_salary_types   TEXT[]    DEFAULT NULL,
  p_gender         TEXT      DEFAULT NULL,
  p_education_max  TEXT      DEFAULT NULL,   -- 이하 포함 로직
  p_experience_max TEXT      DEFAULT NULL,   -- 이하 포함 로직
  p_visa_sponsorship BOOLEAN DEFAULT NULL,
  p_site_id        UUID      DEFAULT NULL,
  p_limit          INT       DEFAULT 20,
  p_offset         INT       DEFAULT 0
) RETURNS SETOF jobs
```

### 방식 B — 기존 Supabase REST 유지 + junction 필터만 RPC
```sql
-- 간단 버전: junction 필터만 처리하는 RPC
CREATE OR REPLACE FUNCTION filter_job_ids(
  p_visa_ids     BIGINT[] DEFAULT NULL,
  p_benefit_ids  BIGINT[] DEFAULT NULL,
  p_language_ids BIGINT[] DEFAULT NULL,
  p_region_names TEXT[]   DEFAULT NULL
) RETURNS TABLE(job_id UUID)
```
앱에서 이 RPC로 ID 목록을 받은 뒤 `.inFilter('id', jobIds)`로 조인 쿼리 실행

### 앱 호출 예시 (방식 B)
```dart
// 1. 서버에서 필터된 job_id 목록 조회
final ids = await supabase.rpc('filter_job_ids', params: {
  'p_visa_ids': [1, 5, 12],
  'p_region_names': ['서울특별시', '경기도'],
});

// 2. 기존 쿼리에 ID 필터 추가
query = query.inFilter('id', ids);
```

## 기대 효과
- 페이지네이션 정확 (서버에서 필터 후 LIMIT/OFFSET)
- 클라이언트 5배 overfetch 제거
- Total 건수도 정확
