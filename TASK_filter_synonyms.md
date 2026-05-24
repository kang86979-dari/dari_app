# DB 변경 요청: 필터 옵션 동의어(synonyms) 컬럼 추가

## 배경
앱 검색 화면에 "필터 추천 탭" 기능을 추가했습니다. 사용자가 검색어를 입력하면 해당 검색어와 매칭되는 필터 옵션을 추천합니다.

현재는 필터 옵션의 label(name_ko, name_en)과만 비교하는데, 사용자가 "developer", "factory", "공장" 등 동의어로 검색하면 매칭이 안 됩니다.

## 요청 사항

### 1. 테이블에 synonyms 컬럼 추가

아래 테이블에 `synonyms` 컬럼(TEXT[] 또는 JSONB)을 추가해주세요:

- `job_categories` (직종)
- `employment_types` (고용형태)
- `visa_master` (비자)
- `korean_levels` (한국어능력)
- `regions` (지역) — 시/도 레벨만

```sql
ALTER TABLE job_categories ADD COLUMN IF NOT EXISTS synonyms TEXT[] DEFAULT '{}';
ALTER TABLE employment_types ADD COLUMN IF NOT EXISTS synonyms TEXT[] DEFAULT '{}';
ALTER TABLE visa_master ADD COLUMN IF NOT EXISTS synonyms TEXT[] DEFAULT '{}';
ALTER TABLE korean_levels ADD COLUMN IF NOT EXISTS synonyms TEXT[] DEFAULT '{}';
ALTER TABLE regions ADD COLUMN IF NOT EXISTS synonyms TEXT[] DEFAULT '{}';
```

### 2. 동의어 데이터 입력

크롤링할 때 정리한 동의어를 각 테이블에 넣어주세요. 예시:

**job_categories:**
| name_ko | name_en | synonyms (다국어, 오타 포함) |
|---|---|---|
| IT·개발 | IT & Development | developer, programmer, engineer, coding, software, 개발자, 프로그래머, エンジニア, ... |
| 제조·생산 | Manufacturing | factory, 공장, production, 제조, assembly, 조립, ... |
| 건설·현장 | Construction | 건축, 현장, building, 노가다, ... |
| 음식·조리 | Food & Cooking | restaurant, kitchen, cook, chef, 식당, 주방, 요리사, ... |
| ... | ... | ... |

**visa_master:**
| code | synonyms |
|---|---|
| E-9 | 비전문, non-professional, 공장비자, factory visa, E9, ... |
| F-2 | 거주, residence, F2, ... |
| H-2 | 방문취업, working visit, H2, 동포, ... |
| ... | ... |

**regions (시/도):**
| si_name | synonyms |
|---|---|
| 서울특별시 | seoul, 서울, ソウル, सियोल, ... |
| 경기도 | gyeonggi, 경기, 수원, 성남, ... |
| ... | ... |

### 3. 앱에서 사용 방식

앱이 필터 옵션을 로드할 때 synonyms도 함께 가져와서, 검색어와 label + synonyms 모두 비교합니다.

기존 API 응답에 synonyms 필드만 추가되면 됩니다:
```
GET /job_categories?select=id,name_ko,name_en,synonyms
```

### 4. 유지보수

새 카테고리나 비자가 추가될 때 synonyms도 함께 입력해주세요. 빈 배열이면 label만으로 매칭합니다 (기존 동작).
