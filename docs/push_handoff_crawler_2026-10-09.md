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
- 당일 미진입 = `last_opened_at IS NULL OR last_opened_at < (KST 오늘 00:00을 UTC로 환산한 값)`.
  **last_opened_at은 UTC로 저장됨** — 비교 시 KST 00:00(= UTC 전날 15:00)으로 변환할 것.

### 2-1. 발송 시각은 app_config가 소유(중요)
앱 설정 화면이 발송 시각을 **app_config 테이블에서 읽어 사용자에게 표시**한다
("매일 오전 9시·오후 3시" / "오후 7시"). 그러니 **크론 시각을 바꾸면 반드시
app_config도 같이 갱신**해야 앱 표시와 실제 발송이 일치한다. 현재 값:
- `push_new_times` = `["09:00","15:00"]` (신규 공고 건수 푸시 시각, 배열)
- `push_recommend_time` = `"19:00"` (추천 공고 푸시 시각)
- 주의: app_config.value는 **TEXT 컬럼에 JSON 문자열**로 저장(jsonb 아님). 읽을 때 JSON 파싱 필요.

## 3. 키워드 조건 매칭 규칙

신규 공고(직전 배치 이후 crawled_at) 중:
1. **키워드**: 앱 검색과 동일 규칙 — 공백으로 단어 분리, 모든 단어가
   `jobs.search_text`(또는 search_text + title_translations->>lang_code)에
   ILIKE 부분일치(AND). DB의 `search_jobs_count_v2` 함수를 그대로 호출해도 됨
   (search_query + 필터 파라미터 받음 — 정의는 마이그레이션
   `supabase/migrations/20261009000000_search_v2_push_conditions.sql` 참고).
2. **필터**: search_filters(jsonb)를 기존 filter_state 매칭 로직 그대로 적용.

## 4. 메시지 템플릿 (확정 — 2026-10-10 개정)

**중요(개정): 키워드 푸시와 기본 조건 푸시의 문구 방식을 다르게 한다.**
키워드 푸시는 **건수를 넣지 않는다**. 이유: 키워드 푸시를 누르면 검색 화면이
열리는데(검색어 복원), 거기 Total은 "조건 전체 건수"라 푸시가 셌던 "신규 건수"와
다르다. 건수를 넣으면 "눌렀더니 숫자가 안 맞네"가 되므로, 키워드 푸시는 건수 없이
"새 공고가 생겼다"만 알린다. 기본 조건 푸시는 홈으로 가므로 비교 대상이 없어 건수 유지.

**(A) 키워드 푸시 — 건수 없음. 검색어만 노출(조건 라벨도 생략):**
- `'용접' 조건에 새 공고가 올라왔어요! 지금 확인해보세요`
- (검색어가 조건의 핵심이므로 필터 라벨은 문구에 안 넣음 — 간결하게)

**(B) 기본 조건 푸시 — 건수 유지.** 조건 2개 이하 나열, 3개↑ "설정한 조건":
- 기본 조건 1~2개: `G-1 · 경기 조건의 새 구인정보 12건이 등록됐어요`
- 기본 조건 3개↑: `설정한 조건에 맞는 새 구인정보 12건이 등록됐어요`
- (앱 UI와 통일 — "필터"가 아니라 "조건")

언어: 행의 lang_code(16언어: ko,en,zh,hi,ja,th,vi,bn,ru,id,ne,km,my,si,uz,mn).
**번역 템플릿 16언어는 앱 팀이 일괄 제공 예정**(추측 생성 금지 — 발송 문구는
앱 UI와 동일해야 하므로). 이 문서의 한국어 예시는 구조 참고용.
- 조건 라벨(G-1·경기 등): search_filters/filter_state에 저장된 건 **ID 배열**
  (visaIds·regionIds 등)이라, 각 마스터 테이블에서 ID→이름 조인해 표기.
  (visa_master.name_ko/en, regions.si_name/gu_name, job_categories.name_* 등)
- 조건이 여러 종류면(비자+지역+…) 대표 1~2개만 노출하고 나머지는 "설정한 조건"으로.

## 5. 추천 공고 푸시 (19시, 신설)

- 대상 공고: **그날 신규**(당일 crawled_at) 중 해당 기기 조건 매칭:
  1순위 키워드 조건(있고 enabled면) → 2순위 filter_state → 조건 없으면 전체
- 선정: 매칭 결과 중 **salary_amount가 있는 공고 우선, 그중 최고 급여 1건**
  (동률이면 crawled_at 최신)
- 메시지(검색어 있으면): `'용접' 추천 공고 — {제목} · {급여} · {지역}`
- 메시지(검색어 없이 기본 조건만): `오늘의 추천 공고 — {제목} · {급여} · {지역}`
  (검색어가 없으면 '용접' 자리를 "오늘의 추천 공고"로 대체. 조건 라벨은 안 붙임)
  - 제목: title_translations->>lang_code (없으면 en → 원문)
  - 급여: salary_type+salary_amount로 "월 320만" 식 — 기존 앱 표기 규칙 참고.
    salary_amount 없으면(회사내규/협의) 급여 토막 생략
  - 지역: **region_id → regions 조인(si_name + gu_name)**. 없으면 생략
    (office_address/workplace_company 쓰지 말 것 — 표기 혼선)
- 매칭 0건이면 발송 안 함

## 6. 푸시 payload (딥링크 — 앱 2.1.6이 처리)

FCM data 필드:
- 키워드 푸시: `{"type": "search", "keyword": "<search_keyword>"}`
  → 앱이 검색 결과 화면을 열고 검색어로 즉시 검색 (필터는 앱의 전역 필터 적용).
  키워드 푸시는 건수를 안 넣으므로(§4-A) 화면 Total과 비교될 일 없음 → 불일치 무해.
- 추천 공고 푸시: `{"type": "job", "job_id": "<jobs.id>"}`
  → 공고 상세로 직행
- 기본 조건 푸시: data 없음(기존대로) → 홈

## 7. 참고

- 새 RPC `search_jobs_fuzzy_v2` / `search_jobs_count_v2`가 운영 DB에 있음 —
  키워드+필터 조합 매칭을 직접 구현하지 않고 count_v2 호출로 대체 가능.
- **filter_state/search_filters 스냅샷에 들어있는 키(이게 전부)**:
  visaIds, categoryIds, employmentTypeIds, benefitIds, countryIds, siteIds,
  regionIds, workScheduleIds, koreanLevelIds, salaryTypes, gender,
  visaSponsorship. → v2 함수의 p_* 파라미터로 1:1 매핑.
  **학력(education)·경력(experience)은 스냅샷에 없음**(푸시 조건에 미포함) —
  해당 파라미터는 비워서 호출.
- 발송 후 last_sent_at 갱신은 기존 방식 유지

## 8. (별건) 지원방법(apply_methods) 수집 누락 — 크롤러 수정 요청

활성 공고 기준 apply_methods가 null/빈 배열인 비율이 높은 사이트 3곳
(2026-10-09 집계):

| 사이트 | 누락/전체 |
|---|---|
| KoMate | 586 / 1,929 (30%) |
| K-Work | 430 / 680 (63%) |
| JobnShop | 163 / 207 (79%) |

확인된 사례: KoMate `recruits/54880641` — 페이지의 지원방법 영역
(`#template_how_to_apply_howtoapply`)에 **"사람인 입사지원"**이라고 적혀
있는데 매핑이 없어 null로 수집됨. "사람인 입사지원" → `online` 매핑 추가
필요. K-Work·JobnShop도 같은 방식으로 미매핑 문구를 조사해 매핑 보강 요청.
(앱은 apply_methods가 비면 지원방법 행을 통째로 숨기므로 사용자에게는
"지원방법 없는 공고"로 보임.)
