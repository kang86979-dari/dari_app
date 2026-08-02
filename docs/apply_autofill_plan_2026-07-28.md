# 지원 자동 채움(WebView Autofill) 기술 기획서

작성일: 2026-07-28
대상: Dari (한국 거주 외국인 구직 앱)
관련: `job_detail_screen.dart` 지원하기 흐름, `sites` 테이블

---

## 1. 배경 & 문제 정의

**사용자가 가장 많이 이탈하는 지점**: `[지원하기]` 버튼 → 외부 사이트 이동 → **회원가입/로그인 → 이력서 작성**.

외국인 구직자에게 이 구간의 벽:
- 가입 폼이 **한국어 전용**, 본인인증 요구
- 이력서를 **매 사이트마다 한국어로 처음부터** 작성
- 어떤 항목을 어떻게 채워야 하는지 모름

**목표**: 사용자가 앱에 **프로필을 한 번만 입력**해두면, 지원 시 외부 사이트의 지원/이력서 폼을 **앱이 자동으로 채워주고**, 사용자는 검토 후 **직접 제출**만 하면 되도록 한다.

---

## 2. 범위 (Scope)

### ✅ 이번 범위 (2단계)
1. **지원자 프로필 저장** — 자동 채움에 쓸 데이터 (1단계 데이터부, UI는 최소)
2. **인앱 WebView 전환** — 외부 브라우저 대신 앱 내부에서 지원 사이트 열기
3. **폼 자동 채움** — 저장된 프로필로 JS 주입하여 입력칸 미리 채움
4. **사이트별 레시피** — 사이트마다 다른 폼 구조를 매핑하는 설정

### ❌ 이번 범위 아님 (명확히 제외)
- **자동 회원가입** — 본인인증 벽으로 불가. 사용자가 직접 가입
- **자동 제출(봇)** — 제출은 반드시 **사용자가 직접**. ToS·법적 리스크 회피
- **모든 사이트 동시 지원** — 타깃 1곳부터 PoC 후 확장
- **완성형 이력서 빌더 UI** — 이번엔 최소 입력 폼만. 리치 UI는 후속

---

## 3. 넘을 수 없는 벽 (사전 인지)

| 벽 | 내용 | 대응 |
|----|------|------|
| **로그인 벽** | 사이트 상당수가 로그인 후에야 지원 폼 노출 | 자동 채움은 **로그인 이후 폼부터**. 가입/로그인은 사용자가 직접 하되, WebView가 세션 쿠키를 유지해 재방문 시 로그인 상태 보존 |
| **본인인증** | 휴대폰 인증·외국인등록번호 | 자동화 불가. 사용자 직접 |
| **폼 변경 취약성** | 사이트가 폼 구조 바꾸면 셀렉터 깨짐 | 레시피를 **서버(Supabase)에서 원격 관리** → 앱 업데이트 없이 수정 |
| **사이트별 상이** | 폼 필드·셀렉터 제각각 | 사이트별 레시피 필요. 그래서 **한 번에 1곳** |

---

## 4. 데이터 모델 — `ApplicantProfile`

기존 온보딩에서 이미 **비자·지역**을 `SharedPreferences`에 저장 중이므로 재활용하고, 자동 채움에 필요한 필드를 확장한다. 저장 방식은 기존 `favorite_provider` / `job_provider` 패턴(Riverpod `StateNotifier` + `SharedPreferences` + `jsonEncode`)을 그대로 따른다.

```dart
class ApplicantProfile {
  // 기본 인적사항
  final String? fullName;        // 영문/한글 이름
  final String? nameKo;          // 한국어 이름(선택)
  final String? phone;           // 연락처
  final String? email;
  final String? birthDate;       // YYYY-MM-DD
  final String? gender;          // male/female
  final String? nationality;     // 국적 코드

  // 비자/체류 (온보딩에서 이미 수집 중 → 재활용)
  final String? visaCode;        // 예: E-9, D-2, F-6
  final String? visaExpiry;      // 체류 만료일(선택)

  // 거주지 (온보딩 지역 재활용)
  final String? addressRegion;   // 시/도
  final String? addressDetail;   // 상세주소(선택)

  // 구직 정보
  final String? koreanLevel;     // IRRELEVANT/BEGINNER/INTERMEDIATE/ADVANCED/NATIVE
  final int? experienceYears;    // 경력 연수
  final String? desiredJobType;  // 희망 직종(선택)

  // 자기소개 (다국어 → 한국어 번역본 함께 보관)
  final String? introOriginal;   // 모국어 원문
  final String? introKo;         // 한국어 번역본(자동 채움용)

  const ApplicantProfile({ ... });

  Map<String, dynamic> toJson();
  factory ApplicantProfile.fromJson(Map<String, dynamic> json);
}
```

**저장 위치**: `SharedPreferences` 키 `applicant_profile` (JSON).
**프로바이더**: `applicantProfileProvider (StateNotifier<ApplicantProfile>)`.
**민감정보 주의**: 전부 **기기 로컬 저장**. 서버 전송 없음 (개인정보 최소화). → `privacy_policy.html` 갱신 필요.

---

## 5. 아키텍처 & 흐름

```
[지원하기] 탭
   │
   ├─ (기존) analytics.applyTap + 전면광고
   │
   ▼
_navigateToUrl()  ← 여기를 교체
   │
   ├─ 프로필 있음 & 사이트 레시피 있음?
   │     │
   │     ├─ YES → ApplyWebViewScreen (인앱 WebView)
   │     │           │
   │     │           ├─ 페이지 로드 완료 감지
   │     │           ├─ URL이 레시피의 form_url_pattern 매칭?
   │     │           │     └─ YES → JS 주입으로 폼 자동 채움
   │     │           ├─ 상단 배너: "정보가 자동 입력되었어요. 확인 후 제출하세요"
   │     │           └─ 제출은 사용자가 직접
   │     │
   │     └─ NO  → 기존 url_launcher(외부 브라우저) 폴백
```

**핵심 원칙**: 레시피가 없거나 프로필이 비어 있으면 **항상 기존 동작(외부 브라우저)으로 안전 폴백**. 자동 채움은 "되면 좋은" 부가기능으로, 실패해도 기존 흐름을 깨지 않는다.

---

## 6. 기술 스택

| 항목 | 현재 | 변경 |
|------|------|------|
| 외부 링크 | `url_launcher` (`LaunchMode.externalApplication`) | **`flutter_inappwebview`** 로 인앱 WebView + JS 주입 |
| JS 주입 | — | `controller.evaluateJavascript()` / `onLoadStop` 콜백 |
| 세션 유지 | — | WebView 쿠키 매니저(로그인 상태 보존) |
| 레시피 저장 | — | Supabase 테이블 `apply_recipes` (원격 관리) |

`url_launcher`는 사이트 홈페이지 이동 등 다른 용도로 유지. 지원 폼만 WebView 경유.

---

## 7. 사이트별 레시피 구조

폼 필드 → 프로필 항목 매핑을 **데이터로 관리**한다. 앱에 하드코딩하지 않고 Supabase에 저장해 **앱 업데이트 없이 수정** 가능하게 한다.

### Supabase 테이블 `apply_recipes`
```
apply_recipes
  ├── id
  ├── site_id (FK → sites)
  ├── form_url_pattern (text)  -- 이 URL 패턴에서만 주입 (정규식)
  ├── requires_login (boolean) -- 로그인 필요 여부(안내용)
  ├── field_map (jsonb)        -- 아래 구조
  ├── is_active (boolean)
  └── updated_at
```

### `field_map` JSON 예시
```json
{
  "fields": [
    { "selector": "#applicant_name", "profileKey": "fullName", "type": "input" },
    { "selector": "input[name='phone']", "profileKey": "phone", "type": "input" },
    { "selector": "#visa_type", "profileKey": "visaCode", "type": "select" },
    { "selector": "textarea#intro", "profileKey": "introKo", "type": "textarea" }
  ],
  "afterFillMessage": "정보가 자동 입력되었어요. 확인 후 제출하세요."
}
```

- `selector`: CSS 셀렉터
- `profileKey`: `ApplicantProfile` 필드명
- `type`: input / textarea / select / radio (채우는 방식 분기)

주입 JS는 `fields`를 순회하며 `document.querySelector(selector).value = profile[profileKey]` + `dispatchEvent(input/change)` 처리(프레임워크 폼 반응용).

---

## 8. 첫 타깃 사이트 선정

사이트별 활성 공고수(2026-07-28 기준):

| 사이트 | 공고수 | 도메인 |
|--------|-------:|--------|
| **K-HIRE** | **9,836** | m.khire.co.kr |
| KoMate | 1,893 | komate.saramin.co.kr |
| TalentLink | 1,495 | talent-link.co.kr |
| K-Work | 807 | k-work.or.kr |
| WorkVisa | 617 | www.workvisa.co.kr |
| WorkOn | 440 | workon.net |
| Kowork | 407 | kowork.kr |
| Jobploy | 295 | www.jobploy.kr |

### 선정 기준
1. **커버리지** — 공고수가 많을수록 자동 채움 혜택받는 사용자 多
2. **지원 방식** — 가입 없이/간편하게 지원 가능한 곳 우선(로그인 벽 낮음)
3. **폼 안정성** — 폼 구조가 단순하고 자주 안 바뀌는 곳

→ **1순위 K-HIRE** (커버리지 압도적, 전체의 절반 이상).
단, 실착수 전 **K-HIRE 지원 흐름의 로그인 벽·폼 셀렉터를 실측**해야 함(아래 로드맵 0단계). 만약 K-HIRE가 로그인 벽이 높으면, 간편지원 가능한 차순위(예: Jobploy/WorkOn)로 PoC 먼저.

---

## 8-1. K-HIRE 0단계 실측 결과 (2026-07-28)

살아있는 공고 3건(외식·제조 등) 실측. K-HIRE는 `m.khire.co.kr`의 **ASP + jQuery** 사이트, 지원 UI는 서버렌더 HTML.

### 지원 흐름
```
[지원하기 .btnApply] 클릭
   └─ 지원 레이어(.applyLayer--base) 모달 오픈
        ├─ 간편입사지원 (.applyLayer__link--simple → ApplicationSimpleResume)  ← 온라인 폼(자동채움 대상)
        ├─ 문자 지원   (.applyLayer__link--sms  → ApplicationTalkResume)
        └─ 전화지원    (.btnTel / .applyLayer__link--tel)  ← 전화번호로 바로 연결
```

### 핵심 발견
| 항목 | 결과 | 시사점 |
|------|------|--------|
| **온라인 지원 폼 존재** | ✅ 간편입사지원(SimpleResume) | 자동 채움 대상 확실 |
| **로그인 벽** | ⚠️ **HIGH** — 간편/문자/채팅 지원 **모두** `confirm("로그인이 필요합니다")` → `/login/Login.asp`를 **새 창**으로 오픈 | 로그인 후에야 폼 접근. 실계정 없이 폼 셀렉터 확인 불가 |
| **구조 일관성** | ✅ 공고 3건 모두 동일 함수·클래스(`ApplicationSimpleResume`, `.applyLayer` 등) | **레시피 1개로 전체 9,836건 커버** — 사이트마다 폼 다른 문제가 K-HIRE엔 없음 (최대 강점) |
| **전화/문자 지원** | 공고마다 병존 | 이 경로는 폼이 없음 → **자동 채움이 아니라 "원터치 전화/문자" 도우미**가 적합 |
| **외국인 전용 섹션** | `/foreign/main.asp` 존재 | K-HIRE도 외국인 간편지원을 이미 고민 중. 제휴/경쟁 포인트 |
| 지원 처리 엔드포인트 | `/person/ApplicationEtcProc.asp` (로그인 후) | |

### 판정
- **K-HIRE는 "로그인 벽 높음"** — 첫 마찰은 크지만, **구조가 완전히 일관돼 레시피 1개 = 9,836건(전체 59%)** 이라 ROI가 압도적. 로그인은 **1회성**(WebView가 쿠키 세션 유지 → 이후 재로그인 불필요)이므로, 온보딩성 로그인 1회만 넘기면 그다음부터 모든 K-HIRE 지원이 자동 채움됨.
- **→ K-HIRE 강행 유지**. 단, 로그인 벽 때문에 **간편입사지원 폼의 실제 필드 셀렉터는 로그인 후에만 확인 가능**.

### 다음 필요 작업 (블로커)
- **사용자가 K-HIRE 계정으로 로그인 후 "간편입사지원" 폼 HTML 확보** 필요 (E-9 계정 생성 가능). 이력서/지원 폼의 input 셀렉터를 채집해야 첫 레시피(`field_map`) 작성 가능.
- 부가: 전화/문자 지원 공고용 **원터치 전화·문자 도우미**를 자동 채움과 별개 기능으로 추가 검토(폼 없는 공고 커버).

## 9. 구현 로드맵

| 단계 | 작업 | 산출물 |
|------|------|--------|
| **0. 실측** | 타깃 사이트 지원 흐름 수동 분석: 로그인 벽 여부, 폼 URL 패턴, 필드 셀렉터 채집 | 레시피 초안 1건 |
| **1. 데이터** | `ApplicantProfile` 모델 + `applicantProfileProvider` + 최소 입력 화면(온보딩 비자/지역 값 프리필) | 프로필 저장 동작 |
| **2. WebView** | `flutter_inappwebview` 도입, `ApplyWebViewScreen` 생성, `_navigateToUrl()` 분기(레시피 有 → WebView / 無 → 기존 폴백) | 인앱 지원 화면 |
| **3. 자동채움 PoC** | 타깃 1곳 레시피로 JS 주입 자동 채움 + 상단 안내 배너 | K-HIRE 자동 채움 |
| **4. 원격 레시피** | `apply_recipes` 테이블 + 앱에서 로드/캐싱 | 앱 업데이트 없이 레시피 수정 |
| **5. 확장** | 차순위 사이트 2~3곳 레시피 추가 | 커버리지 확대 |

---

## 10. 리스크 & 대응

| 리스크 | 영향 | 대응 |
|--------|------|------|
| 사이트 폼 변경 | 자동 채움 실패 | 원격 레시피로 신속 수정 + 실패 시 조용히 폴백(사용자 방해 X) |
| 로그인 벽 높음 | PoC 대상 부적합 | 사이트 선정 시 로그인 벽 낮은 곳 우선 |
| WebView 호환성 | iOS/Android 렌더링 차이 | `flutter_inappwebview`는 양 플랫폼 지원, QA 필수 |
| 개인정보 우려 | 신뢰도 | **로컬 저장만**, 서버 미전송, 개인정보처리방침 명시 |
| 잘못된 자동입력 | 오지원 | 제출 전 **사용자 검토 필수**, 자동 제출 안 함 |

---

## 11. 성공 지표 (Analytics)

기존 `AnalyticsService`에 이벤트 추가:
- `apply_webview_opened` — 인앱 WebView 진입
- `apply_autofill_success` / `apply_autofill_failed` (site_name, 채운 필드 수)
- `apply_profile_saved` — 프로필 최초 저장
- (가능하면) `apply_submitted_estimated` — 제출 추정(폼 submit 감지)

**KPI**: 지원하기 → 실제 지원 완료 전환율 상승, 프로필 저장률.

---

## 12. 다음 액션

1. **0단계 실측**: K-HIRE 지원 흐름을 실제로 눌러보며 로그인 벽·폼 셀렉터 확인 (사용자가 E-9 계정으로 테스트 가능)
2. 실측 결과로 첫 레시피 확정 → 1단계 데이터 모델부터 구현 착수

> 결정 필요: 첫 타깃을 **K-HIRE로 강행**할지, 아니면 **로그인 벽 낮은 사이트로 PoC 먼저** 할지 → 0단계 실측 후 판단.
