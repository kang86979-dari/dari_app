# iOS 배포 전체 검수 + 수정 내역 (2026-08-06)

브랜치: `feature/ios-support`
검수 방식: 4개 영역 병렬 검수(네이티브 설정 / Dart 플랫폼 코드 / 플러그인 iOS 대응 / App Store 심사·개인정보)

---

## 0. 검수 중 정정된 오판 2건

| 항목 | 최초 진단 | 실제 (직접 확인) |
|------|-----------|-----------------|
| Firebase 초기화 | plist 없으면 런치 크래시 (블로커) | `main.dart:23-29` try/catch + `firebaseReady` 플래그로 방어됨 → **크래시 안 남**, GA/푸시만 조용히 비활성 |
| 위치 권한 문구 | 위치 기능 있음 | geolocator 제거됨 → 수동 지역선택(`location_select_screen`)으로 대체. Info.plist 위치 문구는 **고아 권한**이었음 |

---

## 1. 계정 없이 완료한 수정 8건

### ① ATT 순서 — iOS 광고 요청을 ATT 응답 이후로
- **문제**: `main()`에서 `MobileAds.initialize()` 직후 `appOpenAdService.loadAd()`가 실행 → ATT 다이얼로그 응답 전에 첫 광고(IDFA 포함 가능) 요청이 나감. Apple 5.1.2 위반 → 리젝 소지.
- **수정**:
  - `lib/main.dart` — `appOpenAdService.loadAd();` → `if (!Platform.isIOS) appOpenAdService.loadAd();`
  - `lib/features/splash/splash_screen.dart` — `_requestTrackingIfNeeded()` 직후 `if (Platform.isIOS) appOpenAdService.loadAd();` 추가
  - Android는 기존대로 즉시 로드, iOS만 ATT 후 로드.
- 배너/전면 광고는 홈·상세 진입 시(ATT 이후) 로드되므로 문제 없음.

### ② Facebook IDFA 수집 ATT 전 차단
- **문제**: `Info.plist`의 `FacebookAdvertiserIDCollectionEnabled=true` → FB SDK가 앱 실행 시 ATT 전에 IDFA 수집 가능.
- **수정**: `ios/Runner/Info.plist` 해당 값을 `false`로. 추적 허용은 ATT 승인 후 `setAdvertiserTracking(true)` 코드에서만 (기존 로직 유지).

### ③ WebView — iOS에서 URL 차단/새창 작동
- **문제 A**: `flutter_inappwebview` 6.x는 iOS/WKWebView에서 `shouldOverrideUrlLoading`이 `useShouldOverrideUrlLoading:true`여야 호출됨(Android는 자동). 없어서 iOS에선 `intent://`/`market://` 차단·외부브라우저 폴백이 무력화.
- **문제 B**: `supportMultipleWindows:false`면 iOS에서 `target=_blank`/`window.open` 링크가 죽음(dead tap) → 지원 흐름 끊김.
- **수정** (`lib/features/apply/apply_webview_screen.dart`):
  - `useShouldOverrideUrlLoading: true` 추가
  - `supportMultipleWindows: true` + `onCreateWindow` 핸들러 추가 → 새창 요청 URL을 같은 웹뷰에서 로드, `return false`.

### ④ ATS(App Transport Security) — 웹뷰 http 사이트 로딩
- **문제**: `Info.plist`에 `NSAppTransportSecurity` 없음 → WKWebView가 http(비-https) 채용사이트를 기본 차단. 지원 페이지 안 열릴 수 있음.
- **수정**: `ios/Runner/Info.plist`에 아래 추가 (웹콘텐츠에만 한정, 앱 자체 트래픽은 영향 없음).
  ```xml
  <key>NSAppTransportSecurity</key>
  <dict>
      <key>NSAllowsArbitraryLoadsInWebContent</key>
      <true/>
  </dict>
  ```

### ⑤ Info.plist 정리
- 고아 `NSLocationWhenInUseUsageDescription` **제거** (위치 기능 없음 → 심사 문구/실동작 불일치 해소).
- `CFBundleName` `korea_job` → `Dari`.

### ⑥ Privacy Manifest 생성 + Xcode 타깃 등록
- **문제**: 앱 레벨 `PrivacyInfo.xcprivacy` 부재 → 업로드 시 ITMS-91053 "Missing API declaration" 리젝 소지.
- **수정**:
  - `ios/Runner/PrivacyInfo.xcprivacy` 생성 — `NSPrivacyTracking=true`, 필수사유 API 선언:
    - `NSPrivacyAccessedAPICategoryUserDefaults` → `CA92.1` (shared_preferences)
    - `NSPrivacyAccessedAPICategoryFileTimestamp` → `C617.1` (path_provider)
    - `NSPrivacyAccessedAPICategoryDiskSpace` → `E174.1`
  - `ios/Runner.xcodeproj/project.pbxproj` 4곳 삽입(PBXBuildFile / PBXFileReference / Runner 그룹 / Resources 페이즈), ID `DAD1CAFE...A1`(fileRef)·`...A2`(buildFile).

### ⑦ dev 화면 iOS 크래시 가드
- **문제**: `lib/features/dev/apply_webview_debug_screen.dart:56` `getExternalStorageDirectory()`는 Android 전용 → iOS에서 예외. (kDebugMode 전용, release 미포함이지만 iOS 디버그 빌드로 그 화면 열면 크래시)
- **수정**: `Platform.isIOS ? getApplicationDocumentsDirectory() : getExternalStorageDirectory()`.

### ⑧ 빌드 검증
- `flutter build ios --no-codesign` **통과** (exit 0, Runner.app 48.3MB).
- `pod install`이 `flutter_inappwebview_ios (0.0.1)` 동기화 → 기존 stale Podfile.lock 문제 해소.
- pbxproj 수동 편집 정상(빌드 성공으로 검증).

---

## 2. 여전히 계정 대기 (배포 블로커)

| 항목 | 내용 |
|------|------|
| GoogleService-Info.plist | Firebase iOS 앱 생성 후 `ios/Runner/`에 배치 (GA/푸시 작동용, 없어도 크래시X) |
| AdMob 실값 | `Info.plist`의 `GADApplicationIdentifier` 현재 테스트값(`ca-app-pub-3940256099942544~1458002511`) 교체 + `.env`에 `AD_BANNER_ID_IOS`/`AD_INTERSTITIAL_ID_IOS`/`AD_APP_OPEN_ID_IOS` 3종 추가 |
| 푸시 entitlement | `aps-environment` + Push Notifications capability(Runner.entitlements) — Xcode 서명 시. APNs `.p8` 키 → Firebase 등록 |
| 서명 | Apple Developer 가입 후 `DEVELOPMENT_TEAM` 설정 (현재 미설정) |
| App Store Connect | 앱 생성 + 개인정보 라벨(AdMob/FB/GA 데이터 수집) |

### 참고(선택/경고)
- `SKAdNetworkItems` 미설정 (AdMob 권장, 블로커 아님)
- FBSDK 18.1 min-iOS 15.0 vs Podfile 13.0 — Pod은 자체 floor로 링크됨, 경고 수준
- UMP `consent_service.dart`는 호출되지 않는 죽은 코드 — 사용자 지시로 그대로 둠(EEA 대응 필요 시 연결)

---

## 3. 변경 파일 목록
```
lib/main.dart
lib/features/splash/splash_screen.dart
lib/features/apply/apply_webview_screen.dart
lib/features/dev/apply_webview_debug_screen.dart
ios/Runner/Info.plist
ios/Runner/PrivacyInfo.xcprivacy            (신규)
ios/Runner.xcodeproj/project.pbxproj
```
> 커밋 시 `android/gradle.properties`(macOS 로컬 SSL 우회)는 제외.
