# Dari 데이터 적합성 검증 보고서

**검증일**: 2026-04-28
**대상**: jobs 테이블 전체 27,629건

---

## 1. 전체 현황

| 구분 | 건수 | 비율 |
|------|-----:|-----:|
| DB 전체 | 27,629 | 100% |
| 활성 (is_active=true) | 27,532 | 99.6% |
| 비활성 (is_active=false) | 97 | 0.4% |
| 중복 (is_duplicate=true) | 0 | 0% |
| 번역 완료 (is_translated=true) | 27,521 | 99.6% |
| 번역 미완 (is_translated=false) | 108 | 0.4% |
| **앱 노출** (활성+비중복+번역완료) | **27,521** | **99.6%** |

### 사이트별 활성 공고 수

| 사이트 | 건수 |
|--------|-----:|
| K-HIRE | 16,379 |
| Jobploy | 7,046 |
| KoMate | 1,597 |
| KLiK | 1,446 |
| WorkVisa | 605 |
| K-Work | 459 |
| Kowork | 0 |
| Foreigner-Jobs | 0 |
| Here-Ro | 0 |
| OKJob | 0 |

---

## 2. 필수 필드 무결성 — PASS

| 필드 | NULL | 빈값 | 판정 |
|------|-----:|-----:|------|
| title | 0 | 0 | PASS |
| company | 0 | 0 | PASS |
| url | 0 | 0 | PASS |
| site_id | 0 | - | PASS |
| crawled_at | 0 | - | PASS |
| description | 0 | - | PASS |
| address_detail | 0 | - | PASS |
| location | 0 | - | PASS |
| region_id | **386** | - | **주의** |

- URL 형식: 전체 http/https로 시작 — PASS
- region_id NULL 386건: 지역 매핑 안 된 공고 (1.4%)

---

## 3. 급여 데이터 적합성

### 3-1. salary_type 분포

| salary_type | 건수 | 비율 |
|-------------|-----:|-----:|
| monthly | 12,481 | 45.2% |
| hourly | 11,025 | 39.9% |
| negotiable | 1,928 | 7.0% |
| annual | 1,397 | 5.1% |
| daily | 714 | 2.6% |
| weekly | 26 | 0.1% |
| company_rule | 0 | 0% |
| **NULL** | **58** | **0.2%** |

### 3-2. 발견된 이슈

| 이슈 | 건수 | 심각도 | 설명 |
|------|-----:|--------|------|
| salary_type NULL (salary도 전부 NULL) | 58 | 낮음 | 급여 정보 없는 공고 |
| monthly + amount NULL | 1 | 중간 | salary="₩0 / month" 파싱 실패 |
| monthly + amount < 30,000 (시급 오분류) | **4** | **높음** | 10,030원~11,000원 → 시급인데 월급으로 매핑 |
| hourly + amount > 50,000 (일급 오분류 의심) | 5 | 중간 | 145,512원, 160,000원 등 일부 일급일 가능성 |

### 3-3. 시급 오분류 상세 (monthly인데 시급 범위)

| ID | title | amount | 실제 |
|----|-------|-------:|------|
| ff303b13... | 방촌잔치국수 연경점 | 11,000 | 시급 |
| 6ee315a1... | 주방보조및간단한조리 포장 | 11,000 | 시급 |
| dbc3105e... | 모바일 가공 단순 생산 | 10,030 | 시급 |
| 41cf9074... | 버거킹 알바 | 10,320 | 시급 |

---

## 4. 번역 데이터 검증

### 4-1. 번역 jsonb 필드 현황

| 필드 | NULL | 판정 |
|------|-----:|------|
| title_translations | 0 | PASS |
| address_translations | 0 | PASS |
| description_translations | **1,275** | 주의 (Lazy 번역 대상) |
| work_time_translations | 2,844 | 허용 (구조화 시간 우선) |
| work_model_translations | 0 | PASS |

### 4-2. 번역 품질

| 이슈 | 건수 | 심각도 |
|------|-----:|--------|
| ja(일본어) 번역에 한글 혼입 | **14** | 중간 |
| en 번역에 한글 혼입 | 0 | PASS |
| title en==ko (원래 영어 공고) | 6 | 정상 |

### 4-3. is_translated 플래그 정합성

| 구분 | 건수 |
|------|-----:|
| is_translated=false (전체) | 108 |
| ㄴ 활성(is_active=true) | 11 |
| ㄴ 부분 번역 있음 | 108 (전부) |
| ㄴ 완전 번역(15개 언어+addr) | 0 |

---

## 5. FK/enum 필드 검증

### 5-1. FK 필드 NULL 현황

| 필드 | NULL | 전체 대비 | 판정 |
|------|-----:|----------:|------|
| region_id | 386 | 1.4% | 주의 |
| job_category_id | 1,217 | 4.4% | 주의 |
| employment_type_id | 416 | 1.5% | 주의 |
| work_schedule_id | 1 | 0% | PASS |
| korean_level_id | 1 | 0% | PASS |

### 5-2. enum 필드 분포

**gender** (유효값: male/female/any)
- any: 327, male: 273, female: 84, **NULL: 26,945 (97.5%)**

**education** (유효값: none~doctor)
- none: 16,998, bachelor: 236, college: 78, high_school: 45, **NULL: 10,272 (37.2%)**

**experience** (유효값: none~10y)
- none: 1,422, **NULL: 26,207 (94.9%)**

### 5-3. 기타 필드

| 필드 | NULL | 비고 |
|------|-----:|------|
| visa_sponsorship | 0 | true: 1,275 / false: 26,354 |
| posted_at | 33 | 허용 |
| expires_at | 16,993 | 61.5% — 상시 채용 공고 |
| duplicate_group_id (NOT NULL) | 45 | 중복 그룹 지정됨 |
| work_start_time | 26,846 | 97.2% NULL — work_time 텍스트 사용 |
| 근무시간 정보 없음 (전부 NULL) | 2,421 | 8.8% |

---

## 6. 날짜 데이터 검증

| 이슈 | 건수 | 심각도 |
|------|-----:|--------|
| 만료됨(expires_at < 오늘)인데 is_active=true | **263** | **중간** |

→ 만료 공고 비활성화 배치 처리 필요

---

## 7. 종합 판정

### 심각도 높음 (수정 권장)
1. **salary_type 오분류 4건** — monthly인데 실제 시급 (10,030~11,000원)
2. **만료 공고 263건 활성 상태** — is_active=false로 전환 필요

### 심각도 중간 (개선 권장)
3. **ja 번역 한글 혼입 14건** — 재번역 필요 (씨유, 쓱 등 고유명사)
4. **hourly + amount > 50,000: 5건** — 일급이 시급으로 잘못 매핑 의심 (확인 필요)
5. **monthly + amount NULL 1건** — salary="₩0 / month" 파싱 실패

### 심각도 낮음 (허용 가능)
6. region_id NULL 386건 (1.4%)
7. job_category_id NULL 1,217건 (4.4%)
8. employment_type_id NULL 416건 (1.5%)
9. salary_type NULL 58건 — 급여 정보 자체가 없는 공고
10. description_translations NULL 1,275건 — Lazy 번역 대상
11. gender NULL 97.5% — 대부분 공고가 성별 무관
12. experience NULL 94.9% — 경력 정보 없는 공고
13. is_translated=false 108건 중 활성 11건만 — 부분 번역 상태

### 데이터 품질 점수

| 항목 | 점수 |
|------|------|
| 필수 필드 무결성 | **100%** (title/company/url/site_id 전부 0건 누락) |
| URL 형식 | **100%** |
| 번역 완성도 | **99.6%** (27,521/27,629) |
| 급여 정합성 | **99.97%** (오분류 9건/27,629) |
| 날짜 정합성 | **99.0%** (만료+활성 263건) |
| **종합** | **매우 양호** |
