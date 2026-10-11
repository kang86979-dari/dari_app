# Dari 디자인 시스템 핸드오프 (이력서 브랜치 적용용)

> 이 문서는 **새 세션/계정이 이어서 작업**하기 위한 자립형 지시서다.
> 바로 아래 "작업 지시"부터 읽고 시작하라. 이전 세션 기억 없어도 이 문서만으로 충분하다.

## 0. 작업 지시 (무엇을 할 것인가)
`main`(커밋 `0c62eda`)에서 **앱 전반 디자인 개편**을 끝냈다. 이제 **같은 디자인 시스템을
`feature/resume-apply-v2` 브랜치의 화면들(이력서·회원정보·문자지원 등, main엔 없는 기능)에
동일하게 적용**하는 것이 과제다.

진행:
1. `git checkout feature/resume-apply-v2`
2. `git merge main`(또는 rebase)로 **개편된 공용 토큰/위젯을 먼저 들여온다**(충돌 해소).
   - main에 새로 생긴 공용 자산: `lib/core/constants/colors.dart`(토큰 추가),
     `lib/core/widgets/app_toast.dart`, `fixed_header_delegate.dart`,
     `app_dialog.dart`/`app_sheet.dart`/`app_primary_button.dart`/`segmented_tabs.dart`/
     `empty_placeholder.dart`(개편됨).
3. 이력서 브랜치 전용 화면을 열거: `find lib/features -name '*.dart'` 로 resume/account/apply/sms
   관련 파일 확인. 대략:
   `features/resume/*`(resume_edit/manage/self_compose, widgets/resume_section·pickers),
   `features/apply/sms/*`(sms_prepare, khire_apply_webview, khire_jit_sheet),
   `features/apply/online/*`, `features/account/*` 또는 additional_info,
   `apply_method_sheet.dart`, `apply_confirm_dialog.dart`, `address_input_screen`, `daum_postcode_screen`.
4. 각 화면을 **아래 §1 디자인 시스템 규칙**에 맞춰 수정하고,
   **§3 참조 구현(이미 개편된 화면)의 패턴을 그대로 따른다**.
5. `flutter analyze`(에러 0) → `flutter test`(통과) 확인. 빌드/설치까지. **UX 테스트는 사용자가 한다.**

---

## 1. 디자인 시스템 규칙 (반드시 준수)

### 색 — 역할 분리 (lib/core/constants/colors.dart)
핵심 원칙: **"주황(carrot)은 '지금 누를 것/핵심'에만"**. 나머지는 역할색으로 비운다.
- `carrot`(#FF6F0F) / `carrotLight`(#FFF3EB) / `carrotDark`(#E55A00): **주행동(지원하기 등 주 CTA)·급여·총건수·필터 진입점**에만.
- `teal`(#0E7C66) / `tealLight`(#E6F2EF): **정보·링크·선택 상태·고용형태 태그·지원방법(온라인/전화)·번역 토글·출처 링크**.
- `navy`(#003478) / `navyLight`(#E8EEF7): **비자 태그·키워드 알림 칩·지원방법(메시지/이메일)·기숙사 태그**.
- `gold`(#C9A227) / `goldBg`(#FFF8E1) / `goldInk`(#9A7B24): **메모**.
- `sand`(#FAF7F2): 세그먼트 트레이 등. `line`(#ECE9E4): 경계. grays: gray50~gray900.
- ❌ **옛 색 금지**: `tagBlue/tagBlueTxt/tagGreen/tagGreenTxt/tagPurple/tagPurpleTxt` 쓰지 말 것(역할색으로 교체).

### Radius — 3단계 고정
- **칩 = 8** / **카드·버튼·필드 = 12** / **모달·바텀시트 = 16**. (14·15·20·22·24·10 등 쓰지 말 것)

### 표면(Surface) — 홈 방식으로 통일
- 카드·섹션·메뉴 카드 = **흰 배경 + 미세 그림자, 테두리 없음**.
  ```dart
  boxShadow: const [
    BoxShadow(color: Color(0x0F14161B), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D14161B), blurRadius: 14, offset: Offset(0, 4)),
  ],
  ```
- 페이지 배경 = 흰색(진한 회색 배경 금지).

### 타이포
- weight는 **400/500/700/800**만. 크기 대략 12(보조)/14(본문·값)/16(카드제목·버튼)/18(섹션)/22(화면·상세 제목)/28(히어로).

### i18n 내구성 (16개 언어 — 독일어·벵골어는 한국어의 1.5~2배)
- **버튼/칩 고정폭 금지**: `ConstrainedBox(minWidth: ...)` + `maxLines: 2` + `overflow: ellipsis` + `height: 1.2`. (고정 `width:120/180`, 고정 `height:52` 금지 — 받침 잘림/오버플로 원인)
- **라벨/제목 Row**: 자식을 `Expanded`/`Flexible`로. 긴 번역이 아이콘·값을 밀지 않게.
- **info-row(라벨:값)**: 라벨은 `ConstrainedBox(minWidth:64, maxWidth:120, maxLines:2, ellipsis)`, 값은 **우측정렬**(`textAlign: TextAlign.right`) — 라벨 길이 달라도 값 컬럼이 깔끔. (좌측정렬하면 언어마다 들쭉날쭉 — 하지 말 것)
- 칩 가로 행: 가로 스크롤 또는 `Wrap`.
- 작업 중 반드시 **벵골어/독일어로 전환해 안 깨지는지** 가정하고 설계.

### 리스트 선택 vs 칩
- **다중 선택 리스트**(예: 지역 구/군)는 **가벼운 체크**: 흰 행 + 하단 구분선 + 체크박스 색 + 텍스트 굵기만. (행 전체를 carrotLight 박스로 칠하지 말 것 — 여러 개 선택 시 "주황 벽")
- **필터/제거 칩**: carrotLight+carrotDark(또는 키워드=navyLight+navy), radius 8.

### 토스트
- 생 `ScaffoldMessenger.showSnackBar` 금지 → **`showAppToast(context, '문구', icon: ...)`** (lib/core/widgets/app_toast.dart). 다크 알약+아이콘+페이드.

### 바텀시트/다이얼로그
- 시트는 **`showAppSheet`**(라운드16+드래그핸들+X), 다이얼로그는 **`showAppDialog`/`AppDialogShell`**(라운드16, 확정=carrot/취소=gray/위험=urgent) 사용. 커스텀 시트도 이 틀(라운드16+핸들)에 맞출 것.

### 공용 위젯 (재사용 — 새로 만들지 말고 이것들 사용)
`app_toast`(토스트), `app_dialog`(showAppDialog/AppDialogShell/AppDialogAction),
`app_sheet`(showAppSheet), `app_primary_button`(AppPrimaryButton 풀폭 CTA),
`segmented_tabs`(샌드 트레이+흰 알약 탭), `empty_placeholder`(빈상태, CTA=외곽선),
`sort_sheet`, `sheet_handle`, `fixed_header_delegate`(floating/pinned sliver 헤더),
`filter_chips_row`(ReadOnlyFilterChips).

---

## 2. 작업 방식 (사용자 선호 — 꼭 지킬 것)
- **한국어로, 핵심만 짧게** 답한다.
- **드래프트/확정된 시스템을 따른다. 즉흥 변경 금지.** 방향이 바뀌면 기준을 갱신해 "빌드=기준" 유지.
- **디자인 분기(둘 중 뭐로?)는 코드 수정 전에 물어 컨펌** 받되, 사소한 건 묻지 말고 판단해서 진행(과도한 질문 싫어함).
- **테스트는 사용자가 한다. Claude는 빌드·analyze·설치까지만.** 에뮬/실기 UX 테스트를 Claude가 하지 말 것.
- **Android 우선** 검증. 핫리로드: `flutter run --pid-file=<절대경로>` 후 `kill -USR1`(reload)/`kill -USR2`(restart). **pid 파일은 반드시 절대경로**(상대경로면 flutter 크래시). `textAlign` 등 const 위젯 변경은 USR1 반영 안 될 수 있어 USR2로.
- iOS 릴리즈 설치: `flutter run --release -d <device-id>`(서명 팀 3UC28XQ9S6 자동). 릴리즈는 핫리로드 불가 → 재빌드.
- 빌드 깨지면 `flutter clean`(NOTICES 캐시 손상 이슈).
- **memory/project_todo.md**를 상태 변경마다 즉시 갱신(재부팅 대비).
- 커밋/머지/푸시는 **사용자가 요청할 때만**. 커밋 메시지 끝: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- 지원 언어는 16개: ko,en,zh,hi,ja,th,vi,bn,ru,id,ne,km,my,si,uz,mn. 새 문구는 16개 전부 작성(`_t({...})`, 끝에 en 폴백).

---

## 3. 참조 구현 (이미 개편된 화면 — 이 패턴을 복붙하듯 따르라)
`main`에서 읽을 것:
- **카드**: `lib/features/home/widgets/job_card.dart` — radius12+그림자, 태그 역할색(비자=navy/고용=teal/직종=gray), 급여 carrot, 마감일 gray600 w500.
- **info-row(라벨:값)**: `lib/features/job_detail/job_detail_screen.dart`의 `_InfoRow`/`_AddressRow`/`_SourceRow` — 라벨 유연폭+값 우측정렬, 링크=teal.
- **섹션 카드+아이콘 타일+조건칩**: `lib/features/settings/settings_screen.dart`(_SectionCard 그림자, _SettingsTile 아이콘/center 정렬, 조건칩 카드 내부 Wrap).
- **그룹 탭/칩/시트**: `lib/features/filter/filter_screen.dart`(navy 그룹탭, radius8 칩, _SheetRow 가벼운 체크, _SidoSheet 라운드16+핸들).
- **floating/pinned 스크롤**: `lib/features/home/home_screen.dart` + `lib/features/search/search_screen.dart`(`FixedHeaderDelegate`로 탭=floating, 건수·필터칩=pinned).
- **빈상태/세그먼트/토스트/다이얼로그**: 각 core/widgets 파일.

## 4. 검증 기준
- `flutter analyze` 에러 0 (기존 dead-code 경고는 무방).
- `flutter test` 통과(기준: 185개 통과 상태였음).
- 빌드 성공 + 기기 설치.
