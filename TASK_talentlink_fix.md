# TalentLink 데이터 수정 요청

## 1. salary 오분류 수정 (4건)

`salary_type=hourly`인데 `salary_amount`가 100만 이상인 공고. 실제로는 월급입니다.

| id | title | 현재 | 수정 |
|---|---|---|---|
| `8573ac55-...` | 외국인 통역 판매직원 채용 | hourly / 2,800,000 | **monthly** / 2,800,000 |
| `88dc91ad-...` | 건강기능식품 임상시험 참여자 모집 | hourly / 1,500,000 | **monthly** / 1,500,000 |
| `a6cf2d2b-...` | 매니저,홀직원,육부과장겸 주방관리 | hourly / 3,500,000 | **monthly** / 3,500,000 |
| `e765d5ff-...` | 홀서빙 정직원모집 | hourly / 3,000,000 | **monthly** / 3,000,000 |

```sql
UPDATE jobs SET salary_type = 'monthly',
  salary = REPLACE(salary, '/ hour', '/ month')
WHERE id IN (
  '8573ac55-91fc-47f4-a731-eab7ef683cce',
  '88dc91ad-0868-4114-929b-187a7db886dc',
  'a6cf2d2b-ce6b-4332-ba2a-2a51a5b7eff4',
  'e765d5ff-6673-4e15-97f1-cc351a4b462d'
);
```

**크롤러 방지:** TalentLink에서 salary_type 판별 시, hourly인데 금액이 100만 이상이면 monthly로 분류하는 로직 추가 필요.

---

## 2. work_schedule 매핑 수정 (750건)

`work_schedule_id=1` (주1일)로 매핑된 750건이 실제 description에는 `근무요일: 평일`으로 되어 있음.

**원인 추정:** 크롤러가 TalentLink의 근무요일 필드를 파싱할 때, "평일"을 잘못 매핑하거나 기본값으로 주1일을 넣은 것.

**수정 방법:** description 텍스트의 `근무요일:` 값을 기준으로 work_schedule_id를 재매핑.

| description 값 | 올바른 매핑 |
|---|---|
| 평일 | 주5일 (월~금) |
| 주말 | 주말 |
| 요일협의 | 협의 |
| 주5일 | 주5일 |
| 주6일 | 주6일 |

```sql
-- 현재 잘못된 매핑 확인
SELECT work_schedule_id, COUNT(*) 
FROM jobs 
WHERE site_id = '267dc191-e5a7-4deb-9f52-04203407083e'
GROUP BY work_schedule_id 
ORDER BY count DESC;
```

---

## 3. expires_at 파싱 (1,211건 NULL)

description에 `마감일:` 줄이 있지만 `expires_at` 컬럼이 NULL.

**패턴:**
- `마감일: 채용시까지` → expires_at = NULL 유지 (상시채용)
- `마감일: 26.06.19 (금)` → expires_at = 2026-06-19
- `마감일: 2026-06-30` → expires_at = 2026-06-30

**크롤러 수정:** description에서 `마감일:` 줄을 파싱하여 날짜가 있으면 expires_at에 저장. "채용시까지"는 NULL 유지.

```python
# 파싱 예시 (Python)
import re
match = re.search(r'마감일:\s*(.+)', description)
if match:
    raw = match.group(1).strip()
    if raw != '채용시까지':
        # 날짜 파싱 (26.06.19 → 2026-06-19, 2026-06-30 등)
        ...
```
