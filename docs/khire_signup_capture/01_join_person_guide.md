# K-HIRE 개인회원 가입 폼 — 안내 대본 + 자동입력 매핑 초안

- URL: `https://sign.khire.co.kr/user/join/JoinRegFormP.asp`
- 제출: `가입하기` 버튼 → `JoinRegFormPCLS.doSubmit()`
- 외국인 모드 = 영어 UI 일부 노출 (Get code / Confirm 등)
- 원본 HTML: `scratchpad/join_person.html`

## 처리 유형
- **AUTO** = 앱 프로필로 자동입력 (사용자 검토)
- **USER** = 사용자가 직접 입력 (자동화 불가/부적절)
- **CERT** = 인증번호 — 사용자가 받아서 직접 입력

## 필드 순서 · 매핑 · 안내

| 순서 | 필드(selector) | 유형 | 앱 프로필 소스 | 안내 문구(초안, 사용자언어 번역) |
|---|---|---|---|---|
| 1 | `#nationtype_F` (외국인) | AUTO | 고정(외국인) | "외국인으로 자동 선택했어요" |
| 2 | `#allAgree` + `#chk0~#chk3` | AUTO | 필수약관 자동체크 | "필수 약관에 동의 처리했어요. 내용은 확인하세요" |
| 2b | 광고성/개인정보(sectioncd_*) | USER | 선택 | (선택 동의는 사용자 판단) |
| 3 | `#userid` | USER | — | "원하는 아이디를 정하세요 (중복확인)" |
| 4 | `#passwd` / `#passwd2` | USER | — | "비밀번호를 정하세요" (비번 저장 안 함) |
| 5 | `#usernm` | AUTO | fullName | "이름을 넣었어요" |
| 6 | `#birthdate` | AUTO | birthDate(8자리) | "생년월일을 넣었어요" |
| 7 | `input[name=gender]` | AUTO | gender(male/female) | "성별을 넣었어요" |
| 8 | `#nationcd` | AUTO | nationality (ISO alpha-2, 1:1) | "국적을 넣었어요" |
| 9 | `#visacd` | AUTO | visaCode (1:1, 예 E-9) | "비자를 넣었어요" |
| 10 | `#visasdt` / `#visaedt` | AUTO | 비자 발급일/만료일(8자리) | "비자 발급일·만료일을 넣었어요" |
| 11 | `#email` → Get Mail(`sendEmailCertNum`) → `#emailcertnum` → Confirm(`doSubmitEmailCertNum`) | USER+CERT | email(있으면 프리필) | "이메일 입력 → Get Mail → 받은 인증번호 입력 → Confirm" |
| 12 | `#htel` → Get code(`sendCertNum`) → `#certnum` → Confirm(`doSubmitCertNum`) | USER+CERT | — | "휴대폰 입력 → Get code → 문자로 온 인증번호 입력 → Confirm" |
| 13 | `가입하기`(`doSubmit()`) | USER | — | "다 확인했으면 가입하기를 누르세요" (자동 제출 X) |

## 매핑 메모
- 비자·국적 = K-HIRE 값과 **1:1**(변환 불필요)
- 본인인증 = 휴대폰 SMS + 이메일 인증뿐 → 인증번호만 사용자, 나머지 자동입력 가능
- ApplicantProfile 추가 필요: birthDate, visaExpiry, 비자 발급일

## 미확인 (사용자 캡처/로그인 후 확인)
- 실제 화면상 필드 노출 순서(외국인 선택 시 동적 표시 여부)
- userid 중복확인 버튼/함수
- `가입하기` 후 이동 화면(가입 완료 → gourl 복귀)
- 캡처 스크린샷 이 폴더에 추가되면 안내 위치(좌표/셀렉터) 확정
