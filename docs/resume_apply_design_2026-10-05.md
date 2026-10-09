# K-HIRE 온라인 이력서 지원 — 설계서 (2026-10-05)

> 베테랑 기획+개발 관점 설계. 사용자 부재 중 "추측 코드로 기존 동작을 깨지 않기"
> 위해 **검증된 조사 + 설계**까지 작성. 앱 코드 변경은 복귀 후 UX 확인하며 단계별로.

## 0. 목표 / 범위
- **온라인·이메일 지원**만 이력서 요구(간편지원은 각오한마디뿐, 이력서 아님).
- 이력서는 **K-HIRE 포맷**으로 **우리가 데이터를 채워 주입** → 저장/지원까지.
- 고객 편의 최대화("돈값") + **포인트 정기구독**으로 과금(아래 C-4, 보류).

---

## 1. 조사 결과 (K-HIRE Regist.asp 실측, dump_01_172204_011.html)

### 1-1. 폼 = `m.khire.co.kr/person/resume/Regist.asp` (formtype NORMAL=COMPACT 동일 화면)
필수: 제목 · 최종학력 · 경력사항 · 희망 근무지 · 희망 업직종 · 희망 근무조건 ·
자기소개서 · 한국어능력 · "기업 알바제의 받기".

### 1-2. 필드 selector / 입력 방식
| 항목 | selector / 방식 | 비고 |
|---|---|---|
| 제목 | `#cvTitle` (text) | 단순 주입 가능 |
| 최종학력 | `#lasteducd` select(20105 대학원…20100 초등) + `#edustatecd`(졸업상태, JS로 채워짐) | select 주입 |
| 한국어능력 | `#koreanlevel`(+`koreanlevellist`) | select 주입 |
| 희망 업직종 | `jobkind`/`jobkindlist` — **팝업 선택** | 내부 DOM 덤프 필요 |
| 희망 근무지 | **"선택해 주세요" 팝업** (주소 주입과 유사) | 내부 DOM 덤프 필요 |
| 희망 근무조건 | **팝업** (근무기간/요일/급여 등 workperiodcd·workweekcd·paycd) | 내부 DOM 덤프 필요 |
| 경력사항 | `careeryn_{직종코드}` 라디오 + 경력 리스트(comnm/duty/joinyyyy…) | 리스트형 |
| 자기소개서 | **리스트형 컴포넌트**(`#selfText`, `tmpl_selflist`, `btnMainSelfAdd/Remove`) — 단순 textarea 아님. **AI 자소서 버튼** `#btnMainSelfAiAdd` 존재 | 리스트 주입 |
| 사진 | `#resumephoto` (**file input**) | ⚠️ JS 주입 불가(아래 2-3) |
| 동의/알바제의/공개 | `#agree1yn` `#agree2yn` `emailopenyn/homepageopenyn/telopenyn/addressopenyn` `contractopenyn` | 체크박스 |
| 저장 | `Main_Save()` → **AJAX POST `/person/resume/RegistProc.asp`** (신규) / `Main_Update()`→`/ModifyProc.asp`(수정) | ResumeRegistHandler.js |
| 임시저장 | `Main_setTempSave()` → localStorage | |
| 지원하기 | 이 핸들러엔 없음 — 온라인지원 래퍼가 처리(저장 후 지원 → ApplyComplete) | |

### 1-3. ★ 계정 자동보유 데이터 (userInfoJson, 폼에 내장)
K-HIRE가 **계정에서 아래를 자동 보유** → 우리가 주입 안 해도 됨:
`usernm, gender(M/F), birthyear/birthdt, htel(1/2/3), email, zipcd+addr1+addr2(주소 완비!),
nation/nationcd(MN), visasdt/visaedt/visacd(D-4)/visanm, koreanlevel(계정에 있으면), adult, htelcertyn`.
→ **개인정보·주소·비자는 K-HIRE 몫**. 우리는 "이력서 고유 항목"만 채우면 됨.

### 1-4. ★ 이력서는 localStorage JSON에서 복원됨
- `RESUME_MAIN_JSON`(+`RESUME_TEMPSAVE_JSON`)을 페이지 init에서 읽어 폼 구성.
- 서브구조: `saveUserInfoJson / saveResumeMainJson / saveEduJson / saveCareerJson /
  saveWorkJson / saveAreaJson / saveJobKindJson / self(itemtitle·itemcontents)`.
- 주요 키: title, lasteducd/lastedustatecd/schoolnm/major/graduateyyyy,
  joinyyyy/mm·retireyyyy/mm·comnm·duty·workday, workperiodcd/workweekcd/hopeworkstatecd/paycd/homeworkcd,
  AREACD/LOCALCD, JK2CD/careerjobcode, itemtitle/itemcontents, agree1yn/agree2yn, open설정.

---

## 2. 핵심 설계 판단

### 2-1. 주입 전략 — ★ localStorage JSON 주입 (권장) vs 필드+팝업
- **권장: `RESUME_MAIN_JSON`을 우리가 구성해 localStorage에 주입 → 페이지가 폼을 스스로 채움.**
  - 장점: 희망 3종 팝업·자소서 리스트·경력 리스트를 **UI 조작 없이** 한 번에. 가장 견고.
  - 필요: **정확한 JSON 스키마(실값)** → 아래 3-1의 "tempsave JSON 1건 캡처"로 확정.
- 폴백: 단순 필드(cvTitle/lasteducd/koreanlevel/agree)는 직접 주입, 희망/자소서는 JSON.

### 2-2. 데이터 재사용 (고객 입력 최소화 = 편의)
| 이력서 항목 | 소스 |
|---|---|
| 한국어능력 | 문자 작성 칩(koreanLevel) 재사용 |
| 희망 근무지 | 홈 필터 지역(regionIds) → AREACD/LOCALCD 매핑 |
| 희망 업직종 | 홈 필터 직종(categoryIds) → JK2CD 매핑 |
| 최종학력 | 신규(또는 회원정보에 학력 추가) |
| 경력사항 | 신규 입력 |
| 자기소개서 | 신규 입력(+ 번역/템플릿 도움) |
| 제목 | 자동 생성("{국적} {비자} 구직" 등) 또는 입력 |
| 개인정보/주소/비자 | **K-HIRE 계정 자동** (입력 불필요) |

### 2-3. ⚠️ 사진 — 자동 주입 불가 (사용자 질문 답)
- `<input type=file>`는 **브라우저 보안상 JS로 값 설정 불가**. 우리가 미리 받은 사진을
  코드로 폼에 넣을 수 없음.
- 대안: (a) **K-HIRE 계정에 사진 1회 등록**(mainphotoyn=Y) → 이후 이력서가 계정 사진 재사용,
  (b) 사진 **선택 입력**이면 생략, (c) 작성 중 "사진 올려주세요" 안내만.
- 권장: **(a) 계정 사진 유도 + (b) 없으면 생략**. "우리가 미리 업로드→주입"은 불가(명확히).

---

## 3. 복귀 후 바로 하면 되는 "남은 캡처" (딱 1~2건)
1. **tempsave된 `RESUME_MAIN_JSON` 1건** — 이력서 하나를 K-HIRE에서 채운 뒤 그 JSON을
   localStorage에서 캡처. → 주입 JSON 스키마 **실값 확정**(B의 핵심).
   - 방법: 온라인지원을 우리 웹뷰로 열고 Regist 도달 시 `localStorage.RESUME_MAIN_JSON` /
     `RESUME_TEMPSAVE_JSON`를 읽어 debugPrint/핸들러로 전달(추가 코드, 리스크 없음).
2. (선택) 희망 3종 팝업 내부 DOM — JSON 주입으로 안 풀리는 부분만 폴백용.

---

## 4. 구현 단계 (복귀 후, 단계별 승인)

**A. 데이터 수집 UI (Dari "이력서 작성")**
- 재사용 자동채움(한국어/희망지역/직종) + 신규 입력(학력/경력/자소서/제목).
- 저장: `applicant_profiles` 확장 또는 신규 `resumes` 테이블(사이트별 대비 site 컬럼).
- UX: 최소 입력·단계형·자소서 템플릿/번역 도움.

**B. 주입 + 저장/지원**
- 온라인지원 탭 → (로그인) → K-HIRE 웹뷰 `ApplicationSimpleRouter appltype=ONLINE`
  → (인증 1회) → Regist 도달 → **RESUME_MAIN_JSON 주입** → 사용자 확인 → 저장/지원
  → **ApplyComplete 감지로 기록**(기존 재사용, applytype=ONLINE).

**C. 플로우/과금**
- 완료화면 재사용. 지원내역 method='online'.
- **포인트 정기구독**(월 100점, 이력서 지원 5점·문자 1점) — C-4, **보류/추후 설계**.

---

## 5. 리스크 / 메모
- 사진 자동주입 불가(2-3) — 기대치 관리 필요.
- JSON 스키마 확정 전 수집 UI를 "다 만들면" 매핑 재작업 위험 → **3-1 캡처 먼저**.
- 기존 간편/문자 주입 로직(khire_apply_webview_screen, applyType)과 동일 패턴 확장.
- K-HIRE 자산/스키마 변경 시 주입 깨질 수 있음(버전 쿼리 202609301600 관찰).

## 6. ★ 주입 확정 — localStorage 스키마 + 레시피 (2026-10-05 실캡처)
전체 실스키마: `scratchpad/dari_docs/resume_localstorage_capture.json` (PC Chrome 캡처).
섹션별 독립 localStorage 키 → 페이지가 init에서 읽어 템플릿 렌더. **각 키를 넣으면
"+추가" 항목 포함 전부 자동 렌더**(팝업/버튼 조작 불필요).

| 이력서 섹션 | 키 | 항목 구조(핵심) |
|---|---|---|
| 기본/제목/공개/동의 | `RESUME_MAIN_JSON` | title, resumeopenyn, callstarthhmi/endhhmi, openperiod, agree1yn/2yn, **hashdata(서버토큰)** |
| 자기소개서 | `RESUME_SELF_JSON` | `contents`(본문 텍스트) + list |
| 경력 | `RESUME_CAREER_JSON` | totalcareer yy/mm/dd + list[경력항목] |
| 학력 | `RESUME_EDU_JSON` | list[{educd,edunm,major,enteryyyy,graduateyyyy,schoolcd,schoolnm}], lasteducd, lastedustatecd |
| 희망 근무지 | `RESUME_AREA_JSON` | list[{AREACD,AREANM,LOCALCD,LOCALNM}] |
| 희망 업직종 | `RESUME_JOBKIND_JSON` | list[{JK1CD,JK1NM,JK2CD,JK2NM,JK_CAREERYN}] |
| 희망 근무조건 | `RESUME_WORK_JSON` | workperiodcd, workweekcd, paycd/pay/minpay, list[고용형태 optioncd] |
| 자격증 | `RESUME_LICENSE_JSON` | list[{certificateyyyy,licensecd,licensenm,organ}], licensetext |
| 스킬 | `RESUME_SKILL_JSON` | list[{skillcode,skillnm}], jkcode |
| 외국어 | `RESUME_FOREIGNLANGUAGE_JSON` | list[{foreigngroupcd,langgradecd,...}] |
| OA/MBTI/강점/보훈·병역 | `RESUME_OA/MBTI/SPECIAL/ETC_JSON` | 각 list (선택) |
| 한국어능력 | `RESUME_TEMPSAVE_JSON.koreanlevel` (예 40100) | 코드 |
| 완성도 | `RESUME_COMPLETENESS_SCORE` | 숫자(참고) |

### 주입 레시피 (B 구현 핵심)
1. 온라인지원 → K-HIRE 웹뷰로 Regist 폼 도달(인증 1회).
2. **페이지의 현재 `RESUME_MAIN_JSON`을 먼저 읽어 `hashdata` 확보**(서버토큰, 위조불가) →
   우리 내용(title/open/agree 등)만 머지해 다시 set. **hashdata는 절대 덮지 말 것.**
3. 나머지 섹션 키(`RESUME_SELF/CAREER/EDU/AREA/JOBKIND/WORK/LICENSE/SKILL…_JSON`)를
   우리 canonical 데이터에서 **K-HIRE 코드로 매핑**해 localStorage에 set.
4. 폼 재구성 트리거(리로드 또는 페이지의 init 재호출) → 전 섹션 렌더 확인.
5. 저장: `Main_Save()`(신규)/`Main_Update()`(수정) 호출 → RegistProc/ModifyProc.
6. 완료: ApplyComplete 감지로 지원 기록(applytype=ONLINE).

### ★ 코드표 소스 — 전부 공개, curl 추출 가능 (2026-10-05 확인)
| 코드표 | 소스 URL(공개) | 형태 |
|---|---|---|
| 학력(EDUCD)·졸업상태(EDUSTATECD)·한국어(KOREANLEVEL)·고용형태(WORKSTATECD)·근무요일(WORKDAY)·외국어(GCD/GRCD)·리뷰태그(TAGCD) | `/rsc/js/Resume/ResumeOptJson.js` | JS 인라인(GROUP_* 변수) |
| 근무조건: 근무기간(10999무관/10106/10103/10104/10105)·근무요일(15999/15100평일/15103주말)·고용형태(30100알바/30103계약/30102정규/30101인턴)·급여(55100시급…55105건별) | `/person/resume/layer/RegistWorkCondition.asp` | HTML input value (추출완료) |
| 업직종 JK(약 206개) | `/person/resume/layer/RegistJobKind.asp` | HTML(트리) |
| 희망근무지 AREACD/LOCALCD | `/rsc/code/AreaCodeJson.asp` | `var arrAreaCodeJson={list:[{AREACD,AREANM,LOCALCD,LOCALNM,STEP,ORD}]}` |
| 자격증 | `/person/resume/layer/RegistLicense.asp` | HTML(검색형, licensecd 99999=직접입력) |
| 스킬 | 업직종(jkcode)별 추천 — on-demand | 자유/추천 |

**입수 방식**: 전부 로그인 없이 curl 가능 → 빌드타임에 받아 **Dari 에셋(JSON)으로 번들**하거나 런타임 fetch+캐시(KhireAreaService 패턴). 주소(_AreaCode)와 별개로 **이력서 지역은 AreaCodeJson.asp**를 씀(주의).

### 코드 매핑 필요(canonical→K-HIRE)
- 학력: 20105 대학원/20104 대학4년/20103 대학2·3년/20102 고/20101 중/20100 초. 졸업상태 edustatecd(25100 등).
- 한국어: koreanlevel 코드(40100…). 희망지역 AREACD(042 대전)/LOCALCD(1511 동구).
- 업직종 JK1CD/JK2CD, 근무조건 workperiodcd/workweekcd/paycd/고용형태 optioncd(30100 알바 등).
→ 코드표는 각 select/팝업 옵션에서 수집(추가 덤프 or 옵션 파싱).

### ⚠️ 리스크
- `hashdata` 세션 종속 → 반드시 라이브 페이지 값 사용(위 2).
- 코드표(지역/직종/근무조건 옵션) 매핑 테이블 필요 — canonical 입력값↔K-HIRE 코드.
- 사진/포트폴리오(file) 주입 불가.

## 부록 — 참고 파일
- 덤프: `scratchpad/dari_docs/dump_01_172204_011.html`
- JS: `/rsc/js/Resume/ResumeRegistHandler.js`, `ResumeRegistCLS.js`
- 기존 주입: `lib/features/apply/sms/khire_apply_webview_screen.dart` (applyType talk/simple/homepage)
