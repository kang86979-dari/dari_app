## 필터 매칭 규칙

### 기본 원칙
- 같은 카테고리 내: OR
- 다른 카테고리 간: AND

### 카테고리별 상세

| 카테고리 | filter_state 키 | 연산 | 예시 |
|---------|----------------|------|------|
| 비자 | visaIds | OR | F-4 또는 E-9 중 하나라도 매칭 |
| 지역 | regionIds | OR | 경기 31개 구/군 중 하나라도 매칭 |
| 직종 | categoryIds | OR | |
| 고용형태 | employmentTypeIds | OR | |
| 급여유형 | salaryTypes | OR | |
| 근무요일 | workScheduleIds | OR | |
| 한국어능력 | koreanLevelIds | OR | |
| 복리후생 | benefitIds | OR | |
| 성별 | gender | 단일값 | male/female/null |
| 비자지원 | visaSponsorship | 단일값 | true/null |

### 비자 특수 처리
- ANY 비자(비자무관, id: 95082c17-aa5a-4b5c-b19a-50b3ab6381b4)인 공고는 모든 비자 조건에 매칭

### 빈 필터 처리
- 해당 카테고리가 비어있으면([] 또는 null) 조건 없음 = 전체 매칭

### 매칭 예시

구독 `11390e23`의 경우:
```
visaIds: [F-4]        → 공고 비자가 F-4 OR ANY이면 매칭
  AND
regionIds: [31개]     → 공고 지역이 31개 중 하나면 매칭
  AND
koreanLevelIds: [1]   → 공고 한국어능력이 1(무관)이면 매칭
  AND
나머지 비어있음        → 조건 없음 (전체 매칭)
```
