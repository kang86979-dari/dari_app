# 푸시 발송 확장 핸드오프 (앱 → 크롤링 서버, 2026-10-09)

앱(Dari) 2.1.6에서 푸시 관련 기능이 확장됐다. 발송은 크롤링 서버 주관 —
아래 스펙대로 기존 9시/15시 배치를 확장하고, 19시 배치를 신설해 달라.
DB 스키마 변경은 앱 쪽에서 이미 적용 완료(운영 DB 반영됨).

## 1. push_subscriptions 변경 사항 (적용 완료)

기존 컬럼은 그대로. 신규 컬럼 5개:

| 컬럼 | 타입 | 의미 |
|---|---|---|
| search_keyword | text | 키워드 알림 조건의 검색어 (null=조건 없음) |
| search_filters | jsonb | 키워드 조건의 필터 스냅샷 — **filter_state와 같은 포맷** |
| search_enabled | boolean (default true) | 키워드 알림 켬/끔 |
| recommend_enabled | boolean (default true) | 추천 공고 푸시(19시) 켬/끔 |
| last_opened_at | timestamptz | 마지막 앱 진입 시각(UTC). 앱이 시간당 1회 갱신 |

**동작 변경 1건(중요)**: 앱이 이제 **빈 필터여도 행을 삭제하지 않고
`filter_state = null`로 유지**한다 (키워드/추천 설정이 같은 행에 있어서).
→ **기본 조건 푸시(9시/15시)는 `filter_state IS NULL`인 행을 스킵**할 것.
행 삭제는 "푸시 전체 OFF"일 때만 일어난다(기존과 동일).

## 2. 발송 체계 (최종)

| 시각(KST) | 푸시 | 대상 |
|---|---|---|
| 9시, 15시 | 기본 조건 건수 푸시 (기존) | enabled=true AND filter_state IS NOT NULL |
| 9시, 15시 | **키워드 조건 건수 푸시 (신규)** | enabled=true AND search_keyword IS NOT NULL AND search_enabled=true |
| **19시 (신설)** | **추천 공고 1건 (구체 정보)** | enabled=true AND recommend_enabled=true AND **당일 미진입** |

- 키워드 푸시는 기본 푸시와 **별개 1건** (같은 기기가 최대 2건 받을 수 있음 — 확정 정책)
- 당일 미진입 = `last_opened_at IS NULL OR last_opened_at < KST 오늘 00:00`

## 3. 키워드 조건 매칭 규칙

신규 공고(직전 배치 이후 crawled_at) 중:
1. **키워드**: 앱 검색과 동일 규칙 — 공백으로 단어 분리, 모든 단어가
   `jobs.search_text`(또는 search_text + title_translations->>lang_code)에
   ILIKE 부분일치(AND). DB의 `search_jobs_count_v2` 함수를 그대로 호출해도 됨
   (search_query + 필터 파라미터 받음 — 정의는 마이그레이션
   `supabase/migrations/20261009000000_search_v2_push_conditions.sql` 참고).
2. **필터**: search_filters(jsonb)를 기존 filter_state 매칭 로직 그대로 적용.

## 4. 메시지 템플릿 (확정)

공고 상세 정보 없이 **건수만**. 키워드는 항상 노출, 필터는 2개 이하면 나열,
3개 이상이면 "설정한 필터" 표현.

- 키워드 + 필터 1~2개: `'용접' · G-1 조건의 새 구인정보 5건이 등록됐어요`
- 키워드 + 필터 3개↑: `'용접'과 설정한 필터에 맞는 새 구인정보 5건이 등록됐어요`
- 기본 조건(필터 1~2개): `G-1 · 경기 조건의 새 구인정보 12건이 등록됐어요`
- 기본 조건(필터 3개↑): `설정한 필터에 맞는 새 구인정보 12건이 등록됐어요`

언어: 행의 lang_code(16언어: ko,en,zh,hi,ja,th,vi,bn,ru,id,ne,km,my,si,uz,mn).
템플릿 번역문이 필요하면 앱 쪽에 요청 — app_strings 포맷으로 전달 가능.
필터 라벨(G-1·경기 등)은 각 마스터 테이블의 name_en/name_ko 사용
(16언어 라벨이 없는 항목은 en 폴백).

## 5. 추천 공고 푸시 (19시, 신설)

- 대상 공고: **그날 신규**(당일 crawled_at) 중 해당 기기 조건 매칭:
  1순위 키워드 조건(있고 enabled면) → 2순위 filter_state → 조건 없으면 전체
- 선정: 매칭 결과 중 **salary_amount가 있는 공고 우선, 그중 최고 급여 1건**
  (동률이면 crawled_at 최신)
- 메시지: `'용접' 추천 공고 — {제목} · {급여} · {지역}` 형식
  - 제목: title_translations->>lang_code (없으면 en → 원문)
  - 급여: salary_type+salary_amount로 "월 320만" 식 — 기존 앱 표기 규칙 참고
- 매칭 0건이면 발송 안 함

## 6. 푸시 payload (딥링크 — 앱 2.1.6이 처리)

FCM data 필드:
- 키워드 조건 푸시: `{"type": "search", "keyword": "<search_keyword>"}`
  → 앱이 검색 결과 화면을 열고 즉시 검색 실행 (필터는 앱의 전역 필터 적용)
- 추천 공고 푸시: `{"type": "job", "job_id": "<jobs.id>"}`
  → 공고 상세로 직행
- 기본 조건 푸시: data 없음(기존대로) → 홈

## 7. 참고

- 새 RPC `search_jobs_fuzzy_v2` / `search_jobs_count_v2`가 운영 DB에 있음 —
  키워드+필터 조합 매칭을 직접 구현하지 않고 count_v2 호출로 대체 가능
  (filters jsonb → 파라미터 매핑만 필요. 파라미터 시맨틱은 get_jobs_page와 동일:
  지역은 regionIds 그대로, 학력/경력은 최고값 1개 등 — 앱 _buildRpcParams 참고)
- 발송 후 last_sent_at 갱신은 기존 방식 유지
