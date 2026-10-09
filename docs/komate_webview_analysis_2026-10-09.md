# KoMate(사라민 글로벌) 웹뷰 분석 — 지원방법 기능 대비 레퍼런스

작성 2026-10-09. 재진입 모달 버그를 라이브 DevTools로 파헤치며 확보한
KoMate 내부 구조. **다음에 KoMate 지원방법 도우미(K-HIRE 문자지원 같은
자동화)를 만들 때 이 문서부터 볼 것.**

## 1. 사이트 기본

- 공고 상세 URL: `https://komate.saramin.co.kr/recruits/{recruitNo}`
- **Next.js(App Router) SPA** — HTML 셸만 내려오고 본문은 RSC/클라 렌더.
  curl로는 상세 안 보임(로그인/본문 판정이 클라에서 일어남).
- API 서버(별도 도메인): `https://api-komate.saramin.co.kr/api/v2/...`
  - `recruits/{no}/view-count` (POST) — 열람 카운트 증가
  - `companies/{csn}` — 회사 정보(JSON). csn은 base64류 토큰.
- 번역: 사이트에 googleTranslate 위젯 내장(`googtrans` 쿠키).
- 로그인 제공자: 카카오 등 소셜(`saramin_last_login_provider=kakao`).

## 2. 라이브 디버깅 방법 (재사용)

디버그 빌드 웹뷰는 Chrome DevTools Protocol로 원격 조사 가능.
scratchpad에 스크립트 있음(cdp.py/cdp2.py/cdp_cookies.py/cdp_net.py 등).

```bash
# 1) 웹뷰 devtools 소켓 찾기 → 포트포워드
SOCK=$(adb shell cat /proc/net/unix | grep -o "webview_devtools_remote_[0-9]*" | sort -u | head -1)
adb forward tcp:9222 localabstract:$SOCK
# 2) 페이지(target) 목록 — komate URL인 id 찾기
curl -s http://127.0.0.1:9222/json | python3 -c "import json,sys;[print(t['id'],t.get('url','')[:90]) for t in json.load(sys.stdin) if 'saramin' in t.get('url','')]"
```

- **403 Forbidden 주의**: WebSocket 연결 시 Chrome이 Origin 거부 →
  파이썬 `websocket.create_connection(..., suppress_origin=True)`로 우회
  (또는 `--remote-allow-origins=*` 플래그, 앱 재빌드 필요하니 전자 권장).
- `Runtime.evaluate`로 임의 JS 실행(쿠키/DOM/localStorage 덤프, 모달 탐지),
  `Network.getAllCookies`로 **httpOnly 포함** 전 쿠키(앱 CookieManager는
  httpOnly 못 봄), `Network.enable`+`Page.reload`로 API 응답 바디 캡처.

## 3. 쿠키 구조 (핵심)

### 비로그인 (열람 제한 관련)
| 쿠키 | 도메인 | 비고 |
|---|---|---|
| `RECRUIT_VIEW_COUNT` | **`.komate.saramin.co.kr`(점 접두)** + host 두 벌 | 비로그인 열람 카운트. **서버가 읽는 건 점 접두 쪽.** 5회 초과 시 "로그인하고 공고 더보기" 모달로 상세 가림 |
| `route` | komate (httpOnly) | 세션 라우팅 |
| `mobile_modal_recruit_shown` | komate | "가입하면 추천" 모달 닫음 플래그 |
| `nudge_modal_shown` | komate | 넛지 모달 닫음 플래그 |

> ⚠️ `CookieManager.deleteCookies(url)`는 **부모 도메인(.komate / .saramin)
> 쿠키를 못 지움** — host 변형만 지워짐. 반드시 `deleteCookie(name, domain)`로
> 도메인 변형(.komate / host / .saramin)을 각각 지정해 삭제해야 함.

### 로그인 시 (추가로 생기는 것 — **로그인 판별 키**)
| 쿠키 | 도메인 | 값 예 |
|---|---|---|
| `CUST_NO` | `.saramin.co.kr` | 회원번호(23835239) — **로그인 판별에 사용** |
| `UID` / `AUID` | `.saramin.co.kr` | 회원번호와 동일값 |
| `saramin_last_login_provider` | `.saramin.co.kr` | kakao 등 |
| `FOREIGN_MEMBER_TYPE` | komate | p 등 (외국인 회원 유형) |
| `PHPSESSID` | `.saramin.co.kr` (httpOnly) | 세션 |

- **로그인하면 `RECRUIT_VIEW_COUNT`가 사라짐 = 열람 제한 없음.**
- 그래서 현재 수정: 비로그인(=CUST_NO 없음)일 때만 쿠키 초기화,
  로그인 시 초기화 생략(세션 보존). → `apply_webview_screen.dart`
  `_isKomateLoggedIn()` / `_clearKomateCookies()`.

## 4. DOM 마커 (모달/상세 탐지용)

- 로그인/가입 모달 컨테이너 클래스: `MobileModal_mobile-modal__...`,
  배경 dimmed: `Dimmed_dimmed__...`
- 모달 닫기 버튼: `mobile-modal__container__header__close` (또는 내부 svg),
  CTA 버튼: "로그인하러 가기" / "가입하러 가기"
- 상세 본문 판별(로그인 모달 vs 실제 상세): body 텍스트에 회사명/직무
  (예 "이지차이나학원", "중국어") 포함 여부.
- SPA 상태: react-query 캐시가 RSC(`self.__next_f`)에 임베드 —
  `queryKey:["auth","isLogin"]`의 data로 로그인 상태 확인 가능.

## 5. 지원방법 기능 만들 때 참고

- KoMate 지원은 **사라민 "입사지원"** 흐름(apply_methods에 `online`으로
  매핑돼야 함 — 크롤러 미매핑 이슈는 push_handoff 문서 §8 참고).
- 자동화하려면 로그인 필수(위 CUST_NO로 로그인 상태 감지 가능).
  비로그인이면 소셜 로그인(카카오 등) 유도 필요.
- API가 `api-komate.saramin.co.kr/api/v2`로 분리돼 있어, 지원 제출도
  별도 API 호출일 가능성 — 실제 '입사지원' 버튼 눌러 Network 탭
  (CDP `Network.enable`)으로 요청 캡처해 엔드포인트/페이로드 확보할 것.
- 폼 주입 방식(K-HIRE localStorage 주입과 다름): Next.js라 React 상태라
  DOM 직접 입력보다 **입력 이벤트 디스패치** 또는 API 직접 호출 검토.
