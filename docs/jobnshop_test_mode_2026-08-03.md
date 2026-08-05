# JobnShop 테스트 모드 통합 — 진행/계획 정리

작성일: 2026-08-03
브랜치: main
관련 메모리: `project_todo.md`

---

## 1. 목적
새로 크롤한 사이트 **JobnShop**(207건, 제조업/E-7-4 위주, 지역 경기·경남·충남 많음)을 **실서비스 오픈 전 실앱에서 안전하게 검수**하고, 문제없으면 live 전환.

- **숨김 토글(테스트 모드)**: 내부 테스터 ON → JobnShop이 실서비스처럼 섞여 보임 / 고객 OFF → 안 보임
- **이중 안전장치**: sites 테이블 RLS로 숨김 + 푸시 서버에서 항상 차단 → 고객/구버전 사용자에게 절대 안 샘

---

## 2. 완료 (main 커밋됨)

### 테스트 모드 인프라 (`3331d8f`)
- `testModeProvider` (SharedPreferences 영속, 기본 OFF)
- 설정 → **앱 버전 행 + 7탭 → 테스트 모드 토글** 노출
- 홈 워드마크 옆 **TEST 배지** (ON 시)
- testing 사이트 null UI: 카드 사이트 뱃지 / 상세 출처행 → siteName 없으면 생략 (기존 `siteName ?? siteId` = UUID 노출 버그 수정)

### RPC 파라미터 주입 (`1fce2e8`)
- 6개 RPC에 파라미터 전달 (테스트 모드 ON 시):
  - `p_include_testing`: get_jobs_page, get_jobs_count, get_filter_counts
  - `include_testing`: search_jobs_fuzzy, search_jobs_count
- 프로바이더가 testModeProvider watch → 토글 시 자동 재조회
- getJobCount 캐시 키에 includeTesting 포함

### 서버 (백엔드, 배포됨)
- union 처리: `(site_ids 매칭) OR (include_testing AND testing 사이트)`
- 1차 버그: RPC가 SECURITY INVOKER라 anon 호출 시 함수 내부 testing 조회가 sites RLS에 막힘 → 앱이 항상 `p_site_ids=[live]` 보내는 케이스에서 union 안 됨
- 2차 수정: 6개 RPC를 **SECURITY DEFINER 전환** → 해결. 함수 시그니처/앱 코드 영향 없음
- 부수: get_filtered_jobs '전국' 공고 지역필터 미매칭 잠복버그도 해소

---

## 3. 검증 결과 (에뮬)
- anon 하네스 4케이스 전부 통과: 필터無/live8개/TalentLink/생략 → 15,822 / 15,822 / 1,702 / 15,615
- 앱: 테스트 모드 ON → **Total 1,495 → 1,702 (+207 JobnShop)** ✅
- "press" 검색 → JobnShop 프레스/용접 공고 노출. 카드에 사이트 뱃지 없음(정상), 회사명 없음, E-7-4R·Manufacturing·Housing·경기/충남 확인

---

## 4. 남은 UI 폴리시 (구현 대기 — 사용자 검토 중)

제안 기본값(사용자 "이대로 해" 시 일괄 구현):

| # | 항목 | 제안 |
|---|------|------|
| 1 | 회사명 없음 표시 | `?? ''`(빈 줄) → **"회사명 미기재" / "Company not listed"** 회색 placeholder (16개 언어 신규 문자열). 대안: "비공개" |
| 2 | 사이트명 표시 | 현행 **생략 유지** (JobnShop live 시 자동으로 뜸) |
| 3 | WebView 상단 타이틀 다국어 | `apply_webview_screen`의 `'지원하기'`·`'닫기'` 하드코딩 → `s.apply` 등 localized 교체 (langCode 이미 받음) |
| 4 | 상세화면 정리 | JobnShop 상세(설명 없음+희소 필드) 휑한 곳 정리 — 실제 화면 확인 후 |
| 5 | 원문 링크 | 상세에 **"원문 보기"(job.url)** 노출 (siteUrl null이라 출처행 생략됐지만 job.url=jobnshop.com/job/번호는 있음). 기존 "원문 보기" 문자열 재활용 |

### 별도 이슈 — 필터에 JobnShop 없음
- 원인: 사이트 필터 목록 = `sites` 테이블 조회(getSiteOptions) → RLS로 JobnShop 숨김 → 목록에 없음 (스펙에 명시됨)
- 검수 시 "JobnShop만 골라 보기" 불가 → 현재는 검색/비자(E-7-4) 필터로 우회
- 필터에 넣으려면 백엔드 협조 필요(테스트 모드 시 site 목록에 testing 포함). **현행 유지 제안**

---

## 5. QA 13개 체크리스트 (테스터 실주행)
- ✅ QA2 사이트명 빈칸 / ✅ QA1 회사명 없음(단 placeholder 적용 후 재확인) / ✅ QA5 E-7-4 / ✅ QA8 검색
- 미확인: QA3 급여 원문텍스트 10건, QA4 목록 자연 섞임, QA6 경기 지역, QA7 기숙사, QA9 필터 카운트 207, QA10 번역, QA11 급여높은순, QA12 원문 링크, QA13 토글 OFF 시 전부 사라짐
- 테스트 모드 켜기: 설정 → 버전 7탭 → 테스트 모드 ON

---

## 6. 다음 액션
1. 사용자 4번 UI 폴리시 승인(기본값) → 1~5 일괄 구현
2. JobnShop 상세 화면 확인 후 정리
3. 13개 QA 실주행 (테스터)
4. 통과 시 → live 전환 (백엔드가 RLS 해제)
