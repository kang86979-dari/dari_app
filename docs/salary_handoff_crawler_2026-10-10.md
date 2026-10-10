# JobnShop salary 필드 오염 — 크롤러 수정 요청 (2026-10-10)

## 문제
jobs.salary에 급여가 아닌 텍스트가 들어오고 있다. salary_type / salary_amount는 NULL.
앱 카드에서 급여 자리에 "BEAM 용접 작업 수행" 같은 문구가 그대로 노출됐다
(앱은 방어 폴백을 넣어 이제 "회사내규"로 표시하지만, 데이터 자체를 고쳐야 한다).

## 전수조사 결과 (활성·번역 공고 전체)
- **JobnShop 7건만 해당. 다른 사이트는 0건.**

| salary 값 | 비고 |
|---|---|
| `BEAM 용접 작업 수행` | **제목이 그대로 들어감** (salary = title) |
| `기본급` | 자유서술 |
| `최저시급` | 자유서술 |
| `잔업2시간` | 급여 아님 |
| `평균시급보다 더` | 자유서술 |
| `일하는만큼 받음/잔업특근개념 없음` | 자유서술 |
| `3개월지나면 출하수당있음` | 급여 아님 |

조회 쿼리:
```sql
SELECT s.name, j.id, j.salary, j.title
FROM jobs j JOIN sites s ON s.id = j.site_id
WHERE j.is_active AND j.is_translated
  AND j.salary IS NOT NULL
  AND j.salary_type IS NULL AND j.salary_amount IS NULL
  AND j.salary !~ '내규|협의';
```

## 요청 작업
1. **JobnShop 파서 수정**
   - 급여 영역 파싱 실패 시 salary에 제목·설명 등 다른 필드 텍스트를 넣지 말 것 (NULL로 둘 것)
   - salary에 넣는 값은 "금액을 파싱할 수 있는 텍스트" 또는 "내규/협의"만 허용
   - 공통 가드 제안: `salary == title`이면 저장 전에 NULL 처리 (전 사이트 공통 적용 권장)
2. **기존 7건 데이터 정리**
   - 위 쿼리로 잡히는 행의 salary를 NULL로 업데이트 (앱은 NULL이면 "회사내규" 표시)
3. 완료 후 같은 쿼리로 0건인지 확인 회신

## 참고 — 앱 표시 규칙 (변경 완료, 2.1.6)
- salary_amount+salary_type 있음 → 다국어 금액 포맷
- 그 외 파싱 불가 → 카드·상세 모두 "회사내규"(다국어) 표시. 원문 텍스트는 더 이상 노출 안 함.
