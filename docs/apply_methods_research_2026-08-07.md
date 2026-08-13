# 지원방법 9개 사이트 전수 조사 결과 + 크롤러 파싱 규칙 (2026-08-07)

관련: `docs/apply_methods_display_plan_2026-08-06.md`(표시 UI 방향), 메모 `project_apply_scenario`.
조사: 사이트별 활성 공고 50개씩(총 ~450건) 실제 fetch·분석 (병렬 에이전트).

## 핵심 결론
1. **헤드리스 브라우저 불필요** — 모든 사이트가 HTTP만으로(정적 HTML / JSON API / AJAX fragment) 지원방법 획득 가능. JS 렌더 필수인 곳 없음.
   → **데이터 출처 1안(크롤러가 크롤 시점 수집 → DB 저장)이 현실적으로 가능.** (예전 "공고마다 브라우저 렌더" 우려 해소)
2. **사이트마다 추출 방식이 완전히 다름** → 사이트별 파서 규칙 필요(아래 표). 크롤러/서버 관리.
3. **유형 풍부도 2단계**: 풍부(K-HIRE 8종, TalentLink·WorkVisa·Kowork·KoMate) / 단순(K-Work·Jobploy·WorkOn·JobnShop = 사실상 online 하나).
4. **정규화 코드 확정**: `online · homepage · email · phone · sms · simple · chat · visit` (+`other`/우편). K-HIRE가 8종 전부 커버.
5. **부가 데이터**(2단계 칩 탭 동작용): phone→전화번호, email→주소, homepage→URL 도 함께 저장 권장.

## 사이트별 요약

| 사이트 | 렌더링 | 발견 유형 | 추출 |
|--------|--------|-----------|------|
| K-HIRE | 정적 HTML | 8종 전부 | ✅ YES |
| TalentLink | AJAX fragment | simple·sms·homepage·email | ✅ YES(요청 1번 추가) |
| WorkVisa | 정적(Next RSC) | sms·simple·(website) | ✅ YES |
| Kowork | 정적(Next RSC) | simple·homepage·email | ✅ YES |
| KoMate | 정적(이스케이프 HTML) | online(사람인)·phone·homepage·우편 | ⚠️ 80%(20% 마크업 없음) |
| WorkOn | 정적 | online(100%)·email/phone·visit/fax | ✅ online / ⚠️ 자유텍스트 |
| Jobploy | 정적(Laravel) | online(100%)·phone/email(희소) | ⚠️ online만 확실 |
| JobnShop | SPA→JSON API | phone(~98%)·email(22%)·online(앱) | ⚠️ API로 가능, 자유텍스트 파싱 |
| K-Work | 정적 JSP | online 하나(균일) | ✅ 단일 |

---

# 크롤러팀 파싱 규칙 표

각 공고에서 아래 규칙으로 **정규화 코드 배열 `apply_methods`** 추출 + (가능하면) 부가데이터.

## 정규화 코드
`online`(플랫폼 자체 온라인지원) · `homepage`(외부 홈페이지 URL) · `email` · `phone`(전화/전화후방문) · `sms`(문자) · `simple`(간편지원) · `chat`(채팅) · `visit`(방문접수) · `other`(우편·팩스 등)

## 사이트별 규칙

### 1. K-HIRE — ✅ 풍부, 정적 HTML (8종)
- 요청: 공고 URL 그대로 GET (모바일 UA). 정적 HTML에 서버 렌더됨.
- 셀렉터: **`li.applyLayer__item > a.applyLayer__link.applyLayer__link--{TYPE}`** (반드시 이중클래스·`li.applyLayer__item` 내부로 스코핑)
  - ⚠️ 바 `.applyLayer__link--*` 토큰만 grep하면 JS 이벤트 바인딩 코드까지 잡혀 **모든 공고에 homepage/simple 오탐**. 활성 방법은 `<li class="applyLayer__item">` 안의 이중클래스 앵커만.
- TYPE 매핑: `online→online, sms→sms, chat→chat, email→email, simple→simple, tel→phone, offline→visit, homepage→homepage`
- 부가데이터: `--tel` → `href="tel:..."`(번호), `--homepage` → `href="https://..."`(외부 URL)

### 2. TalentLink — ✅ AJAX fragment (4종)
- 요청: 상세 URL의 `jvrt_idx=N` 추출 → **`POST https://talent-link.co.kr/employment_pt_form.php` body `lang=KR&type=&jvrt_idx=N`** (상세페이지 `#jvrt_detail_box`는 정적HTML에서 비어있음)
- 셀렉터(fragment 응답): `.method_wrap .method_span span`
- 매핑: `간편 입사 지원→simple, 문자지원→sms, 홈페이지 지원→homepage, 이메일 지원→email`
- 부가: 홈페이지 URL = 상세페이지 `a.empl_btn02[href]`; email/phone = fragment `담당자 정보` 블록

### 3. WorkVisa — ✅ 정적(Next RSC), enum
- 요청: 공고 URL GET. `self.__next_f.push([...])` RSC 스트림에 이스케이프 JSON(`\"`).
- 필드: `\"recruitmentType\":\"SMS|SIMPLE|WEBSITE\"`
- 매핑: `SIMPLE→simple, SMS→sms, WEBSITE→homepage`
- 부가: `recruitSMSPhone`(SMS 번호), `homepageLink`(WEBSITE URL)

### 4. Kowork — ✅ 정적(Next RSC), 필드
- 요청: 공고 URL GET. RSC JSON(이스케이프).
- 필드: `additionalApplyHomepage`, `additionalApplyEmail`
- 결정: homepage 비어있지않음→`homepage` / else email 비어있지않음→`email` / else→`simple`
- ⚠️ 푸터 `mailto:master@kowork.kr`는 지원 이메일 아님 → raw mailto 긁지 말고 필드 사용

### 5. KoMate(사람인) — ⚠️ 정적, 80%만
- 요청: 공고 URL GET. 본문이 이스케이프 따옴표(`class=\"value\"`).
- 셀렉터: `#template_applyway_apply_types .value` (라벨 `접수방법 :` 뒤 span). 값은 콤마 다중.
- 매핑(부분일치): `사람인 입사지원→online, 홈페이지 지원→homepage(앵커 href), 전화 지원→phone, 우편 지원→other, 이메일→email, 문자지원→sms, 간편지원→simple, 방문접수→visit, 채팅→chat`
- ⚠️ 20% 공고는 `template_applyway` 블록 자체 없음 → `apply_methods` 비움(unknown)

### 6. WorkOn — ✅ online / ⚠️ 나머지 자유텍스트
- 요청: 공고 URL GET(정적).
- 기본: 모든 공고 `button.btn-apply-blue[data-bs-target="#applyDialog"]`(지원하기) → **`online`** 100%
- 담당자: `#card-recruiter a[href^="mailto:"]`→email, `.recruiter-contact-row i.bi-telephone` 인접 텍스트→phone(번호, tel:링크 아님)
- 자유텍스트(선택): `#card-details`에서 `접수방법\s*[:;]\s*(...)` → visit/email/fax(→other)/phone 힌트. 오타·구분자 혼재라 best-effort

### 7. Jobploy — ⚠️ online만 확실
- 요청: 공고 URL GET(정적, Laravel). (가끔 봇 fallback SPA shell → 재요청)
- 기본: `a.recruit-action-btn` + `<script type="application/ld+json">`의 `"directApply":true` → **`online`** (전 공고)
- 부가: 인라인 JSON `contact_phone`(있으면 phone), `contact_mail`/본문 mailto(있으면 email). 각각 ~7/50, ~1/50로 희소
- sms/visit/chat/homepage: 본문 자유텍스트만 → 신뢰불가, 시도하지 말 것

### 8. JobnShop — ⚠️ JSON API + 자유텍스트
- 요청: 상세 URL의 `/job/{ID}` → **`GET https://jobnshop.com/php/job_postings_public_api.php?id={ID}&rows=1&page=1&target_lang=ko`** (페이지 HTML은 빈 SPA shell)
- 필드: `contact`/`phone`/`contactPhone`(동일 문자열). 구조화된 지원방법 필드 없음 → 문자열 파싱:
  - `@` 포함 → `email`(+phone), 전화번호 패턴 → `phone`, 비어있음 → online(앱)만
- 유형: phone(~98%)·email(22%). homepage/sms/chat/visit 없음. 온라인지원은 앱 기능(공고별 아님)

### 9. K-Work — ✅ 단일 online
- 요청: 공고 URL GET(정적 JSP).
- 셀렉터: `#btnAppl` / `button[onclick^="doAppl"]` (전 공고 균일) → **`online`** 하나로 매핑
- 다중유형(email/phone/homepage 등) 구조화 데이터 없음 → 시도하지 말 것. 본문 "지원방법절차"는 전형절차(hiring process)지 지원채널 아님

## DB / 앱 연동 (출처 확정 후)
- `jobs.apply_methods text[]` (코드 배열) + 선택 `apply_contact jsonb`(phone/email/homepage URL)
- RPC(get_jobs_page/getJobById) 반환에 포함
- 앱: `Job.applyMethods` + 상세화면 "지원방법" 행(핵심정보 테이블, Source 위, 아이콘+라벨 칩) — 표시 UI는 이미 테스트 반영됨
- 다국어 라벨은 app_strings 16개 언어

## 다음
- 크롤러팀에 위 규칙표 전달 → `apply_methods` 수집 시작
- 수집되면 앱 더미데이터 → 실데이터 전환 + app_strings 라벨 16개 언어 추가
