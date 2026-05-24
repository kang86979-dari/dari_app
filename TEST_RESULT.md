# Dari 테스트 결과 보고서

> 실행일: 2026-04-27
> 총 테스트: 192건 (자동화 157건 + DB 검증 35건)

---

## 요약

| 구분 | 총 건수 | PASS | FAIL | WARNING |
|------|--------|------|------|---------|
| 트랙 1: 유닛 테스트 | 143 | **143** | 0 | 0 |
| 트랙 1-B: 위젯 테스트 (바인딩) | 14 | **14** | 0 | 0 |
| 트랙 1-C: 엣지 케이스 | 9 | **9** | 0 | 0 |
| 트랙 1-C: UI 오버플로우 | 21 | 6 | **15** | 0 |
| 트랙 2: DB 데이터 품질 | 22 | 16 | **2** | **4** |
| 트랙 2: DB 번역 품질 | 5 | **5** | 0 | 0 |
| 트랙 2: 검색/필터 | 12 | **12** | 0 | 0 |
| **합계** | **226** | **205** | **17** | **4** |

**PASS율: 90.7% (205/226)**

---

## FAIL 항목 상세

### FAIL-1. salary_type='weekly' 미처리 (DB)

- **건수**: 활성 공고 42건
- **영향**: 앱 SalaryType enum에 weekly 없음 → SalaryType.unknown 처리 → 급여 표시 안 됨
- **수정 방안**: 
  - (A) SalaryType에 weekly 추가 + formatSalary에 주급 번역 추가
  - (B) 크롤러에서 weekly → daily로 변환 (주급÷근무일수)
- **우선순위**: 중간

### FAIL-2. salary_type + salary_amount 짝 불일치 (DB)

- **건수**: 2건 (monthly인데 amount NULL)
- **영향**: formatSalary 호출 안 됨, salary 원문 텍스트로 폴백
- **수정 방안**: DB에서 해당 2건 수정 또는 크롤러 파싱 로직 보완
- **우선순위**: 낮음 (2건, 폴백 작동)

### FAIL-3. JobCard 하단 Row 오버플로우 (UI)

- **건수**: 21개 조합 중 15건 FAIL
- **영향**: 급여 텍스트가 긴 언어에서 하단 Row 넘침 (RenderFlex overflow)
- **실제 영향**: 실기기에서는 테스트 모드보다 화면이 넓어 일부 완화되지만, 소형 기기에서는 발생 가능
- **오버플로우 상세**:

| 언어 | 320px | 375px | 428px | 급여 텍스트 예시 |
|------|-------|-------|-------|---------------|
| ko | PASS | PASS | PASS | 월급 200만원 |
| en | -139px | -84px | -31px | ₩2,000,000 / Monthly |
| ru | FAIL | FAIL | FAIL | ₩2.000.000 / Ежемесячная |
| bn | FAIL | FAIL | PASS | ₩20,00,000 / মাসিক |
| my | FAIL | FAIL | PASS | ₩2,000,000 / လစဉ် |
| ar | FAIL | FAIL | PASS | Monthly ₩2,000,000 |
| km | -154px | -99px | -46px | ₩2,000,000 / ប្រចាំខែ |

- **수정 방안**: job_card.dart 하단 Row에서 급여 Text에 `Flexible` + `overflow: TextOverflow.ellipsis` 적용
- **우선순위**: 높음 (사용자에게 보이는 UI 버그)

---

## WARNING 항목

### WARN-1. is_duplicate=true + is_active=true (62건)

- **영향 없음**: 앱에서 `is_duplicate=false` 조건으로 필터하므로 노출되지 않음
- **확인 사항**: duplicate_group_id가 NULL인 건 62건 → 중복 감지 후 그룹핑이 안 된 것
- **조치**: 크롤러 중복 처리 로직 확인

### WARN-2. is_translated=false + is_active=true (29,168건)

- **영향 없음**: 앱에서 `is_translated=true` 조건으로 필터
- **참고**: 전체 활성 공고 대비 번역된 공고 비율 = 11,713 / (11,713+29,168) = 28.6%

### WARN-3. 번역 15개 언어 (fil 키 없음)

- **영향 없음**: fil(필리핀어) 언어 제거 결정 (2026-04-27)
- **현재 번역 언어**: en, zh, vi, th, uz, km, ne, id, my, mn, ja, si, bn, ru, hi (15개)
- **ko 키 없음**: 원문이 한국어이므로 정상

### WARN-4. 필터 카운트에 weekly 포함 (22건)

- **영향**: 필터 UI에 weekly 옵션이 없어서 사용자가 weekly 공고를 필터로 볼 수 없음
- **연관**: FAIL-1과 동일 이슈

---

## PASS 항목 요약

### 유닛 테스트 (143건 전체 PASS)

- Job.getTitle() 폴백: 5건 PASS (ko/vi/fr/en/null)
- Job.getAddress() 폴백: 3건 PASS
- Job.getShortLocation(): 5건 PASS
- Job.salaryType getter: 10건 PASS
- Job.getDescriptionHtml(): 3건 PASS
- Job.displayWorkTime: 3건 PASS
- Job.fromJson() 파싱: 2건 PASS
- FilterState: 15건 PASS (isEmpty/activeCount/copyWith/toJson-fromJson/equality)
- RegionMapper: 14건 PASS
- 급여 포맷 (7개 언어): 15건 PASS
- 다국어 문자열 (17개 언어): 63건 PASS
- FilterCounts: 7건 PASS

### 위젯 테스트 (14건 전체 PASS)

- JobCard 필드 바인딩: 10건 PASS (제목/회사/태그/급여/비자/마감일/하트)
- 언어 변경 렌더링: 4건 PASS (ko/en/vi + 급여 ko→de)

### 엣지 케이스 (9건 전체 PASS)

- null 필드 처리: 4건 PASS (title/company/salary/expiresAt)
- 비자 3+ 뱃지: 1건 PASS
- 긴 제목 ellipsis: 1건 PASS
- 만료 공고 라벨: 1건 PASS
- 숙소 제공 칩: 1건 PASS
- 빈 비자: 1건 PASS

### DB 데이터 품질 (16건 PASS)

- salary_amount 음수: 0건 (PASS)
- 시급 비현실적: 0건 (PASS)
- 활성 공고 title NULL: 0건 (PASS)
- 활성 공고 url NULL: 0건 (PASS)
- gender/education/experience 허용값: 0건 (PASS)
- address_translations en 누락: 0건 (PASS)
- 번역 빈 문자열: 0건 (PASS)
- 필터 카운트 정합성: hourly/monthly/weekly 모두 일치 (PASS)
- 전체 활성 공고 수: 11,713건 (PASS)

### DB 번역 품질 (5건 PASS)

- 번역값 == 원문: 0건 (PASS)
- title 한글 혼입 (500건 x 15언어): 0건 (PASS)
- description 한글 혼입: 0건 (PASS)
- address en 한글 포함: 0건 (PASS)
- work_model_translations 누락: 0건 (PASS)

### 검색/필터 (12건 PASS)

- 삼성 검색: 3건 반환 (PASS)
- Samsung 영어 검색: 3건 반환 (PASS)
- 삼선 오타 검색: 3건 유사도 매칭 (PASS)
- 빈 문자열 검색: 크래시 없음 (PASS)
- 50자 초과: 크래시 없음 (PASS)
- XSS 시도: 인젝션 차단 (PASS)
- 필터 카운트 hourly: 6,577건 일치 (PASS)
- 필터 카운트 monthly: 4,592건 일치 (PASS)
- 필터 카운트 weekly: 22건 일치 (PASS)

---

## 수정 우선순위

| 순위 | 이슈 | 영향 | 난이도 |
|------|------|------|--------|
| 1 | **JobCard 하단 오버플로우** | 사용자에게 보이는 UI 깨짐 | 쉬움 (Flexible 추가) |
| 2 | **salary_type=weekly 미처리** | 42건 급여 미표시 | 중간 (enum + 번역 추가) |
| 3 | salary_amount NULL 2건 | 2건 폴백 표시 | 쉬움 (DB 수정) |

---

## 테스트 파일 위치

```
test/
├── unit/
│   ├── job_model_test.dart        (30건)
│   ├── filter_state_test.dart     (15건)
│   ├── region_mapper_test.dart    (14건)
│   ├── salary_format_test.dart    (15건)
│   ├── app_strings_test.dart      (63건)
│   └── filter_counts_test.dart    (7건)
├── widget/
│   ├── job_card_test.dart         (14건)
│   └── job_card_edge_test.dart    (30건)
└── widget_test.dart               (기존 스모크 테스트)
```

## 실행 명령어

```bash
# 전체 테스트
flutter test

# 유닛 테스트만
flutter test test/unit/

# 위젯 테스트만
flutter test test/widget/
```
