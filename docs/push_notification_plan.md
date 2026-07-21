# 푸시 알림 구현 계획 — 필터 매칭 신규 공고 알림

> 작성일: 2026-06-17

## 1. 개요

사용자가 앱에서 설정한 필터(비자, 지역, 직종 등 16종)에 맞는 새 구인정보가 크롤링되면,
**하루 1번 오전 9시(KST)** 에 "오늘 새 공고 N건" 푸시 알림을 보내는 기능.

### 전체 흐름

```
[pg_cron 매일 09:00 KST]
    ↓ HTTP 호출 (pg_net)
[Supabase Edge Function: send-daily-push]
    ↓ push_subscriptions 테이블에서 active 구독 조회
    ↓ 각 구독별 get_jobs_count(filters + p_crawled_after) RPC 호출
    ↓ count > 0 이면 FCM HTTP v1 API로 푸시 발송
    ↓ last_notified_at 갱신

[Flutter 앱]
    → 앱 시작 시 FCM 토큰 발급 → push_subscriptions에 upsert
    → 필터 변경 시 filter_state를 서버에 동기화
    → 알림 탭 → /home 이동 (저장된 필터로 목록 표시)
```

---

## 2. 서버 (Supabase)

### 2-1. push_subscriptions 테이블

```sql
CREATE TABLE public.push_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fcm_token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  filter_state JSONB NOT NULL DEFAULT '{}'::jsonb,
  language_code TEXT NOT NULL DEFAULT 'en',
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_notified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_push_subs_active ON push_subscriptions (is_active) WHERE is_active = true;
CREATE INDEX idx_push_subs_token ON push_subscriptions (fcm_token);
```

**RLS 정책:**

```sql
ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

-- anon: 자기 토큰만 insert/update
CREATE POLICY "anon_insert" ON push_subscriptions FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_update" ON push_subscriptions FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- service_role (Edge Function): 전체 read/update
CREATE POLICY "service_read_all" ON push_subscriptions FOR SELECT TO service_role USING (true);
CREATE POLICY "service_update_all" ON push_subscriptions FOR UPDATE TO service_role USING (true) WITH CHECK (true);
```

**설계 포인트:**
- 로그인 없는 앱이라 `fcm_token`이 디바이스 식별자 역할
- `filter_state`는 앱의 `FilterState.toJson()` 형식 그대로 저장
- `last_notified_at`이 "새 공고" 기준 시점 (이 시각 이후 crawled_at인 공고만 카운트)

### 2-2. get_jobs_count RPC 수정

기존 RPC에 파라미터 1개만 추가:

```sql
-- 기존 파라미터들 뒤에 추가
p_crawled_after TIMESTAMPTZ DEFAULT NULL::timestamptz
```

WHERE절에 한 줄 추가:

```sql
AND (p_crawled_after IS NULL OR j.crawled_at >= p_crawled_after)
```

- `DEFAULT NULL`이라 기존 호출에는 영향 없음
- Edge Function이 `last_notified_at` 값을 `p_crawled_after`로 전달

### 2-3. Edge Function: send-daily-push

**핵심 로직 (TypeScript/Deno):**

```typescript
Deno.serve(async (req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  // 1. active 구독 전체 조회
  const { data: subs } = await supabase
    .from('push_subscriptions')
    .select('*')
    .eq('is_active', true)

  // 2. FCM 인증 (Google OAuth2 access token)
  const accessToken = await getGoogleAccessToken(FCM_SERVICE_ACCOUNT)

  for (const sub of subs) {
    // 3. filter_state → RPC 파라미터 변환
    const rpcParams = buildRpcParams(sub.filter_state)
    rpcParams.p_crawled_after = sub.last_notified_at
      || new Date(Date.now() - 24*60*60*1000).toISOString()

    // 4. 새 공고 건수 확인
    const { data: count } = await supabase.rpc('get_jobs_count', rpcParams)
    if (!count || count === 0) continue

    // 5. FCM 발송
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${accessToken}` },
        body: JSON.stringify({
          message: {
            token: sub.fcm_token,
            notification: {
              title: getTitle(sub.language_code),      // "다리 - 새 공고 알림"
              body: getBody(sub.language_code, count),  // "오늘 새 공고 15건이 있습니다"
            },
            data: { type: 'daily_jobs', count: String(count) },
            android: { notification: { channel_id: 'daily_jobs' } },
          }
        })
      }
    )

    if (res.ok) {
      // 6. last_notified_at 갱신
      await supabase.from('push_subscriptions')
        .update({ last_notified_at: new Date().toISOString() })
        .eq('id', sub.id)
    } else {
      // UNREGISTERED 토큰 → 비활성화
      const err = await res.json()
      if (isUnregistered(err)) {
        await supabase.from('push_subscriptions')
          .update({ is_active: false }).eq('id', sub.id)
      }
    }
  }
})
```

**buildRpcParams — 복제해야 할 특수 로직:**

| 필터 | 특수 처리 |
|------|-----------|
| regionIds | 전국(246) 자동 포함 |
| employmentTypeIds | 협의 ID(`977e9c8e-...`) 자동 포함 |
| salaryTypes | `negotiable` 자동 포함 |
| educations | 여러 개면 MAX 레벨만 전달 |
| experiences | 여러 개면 MAX 레벨만 전달 |
| siteIds 비어있을 때 | OKJob, KLiK, Here-Ro, Foreigner-Jobs 제외 |
| gender | `any`이면 전달하지 않음 |

> 이 로직은 `lib/data/repositories/job_repository.dart`의 `_buildRpcParams()` 메서드를 TypeScript로 그대로 포팅

**FCM 인증:**
- Firebase 프로젝트의 서비스 계정 JSON 필요
- Supabase Secrets에 `FCM_SERVICE_ACCOUNT_JSON`으로 저장
- JWT 서명 → Google OAuth2 access token 발급

**알림 메시지 다국어 (16개 언어):**

```
ko: "오늘 새 공고 {N}건이 있습니다"
en: "{N} new jobs match your filters today"
vi: "Hôm nay có {N} việc làm mới phù hợp"
zh: "今天有{N}个新职位匹配您的筛选"
th: "วันนี้มี {N} งานใหม่ตรงกับตัวกรองของคุณ"
...등 16개 언어
```

### 2-4. pg_cron 스케줄 등록

```sql
-- pg_cron + pg_net 확장 필요
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

SELECT cron.schedule(
  'daily-push-notifications',
  '0 0 * * *',  -- UTC 00:00 = KST 09:00
  $$
  SELECT net.http_post(
    url := 'https://rcyxbxmhjtukmogvneyp.supabase.co/functions/v1/send-daily-push',
    headers := jsonb_build_object(
      'Authorization', 'Bearer <SERVICE_ROLE_KEY>',
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);
```

---

## 3. 클라이언트 (Flutter)

### 3-1. 패키지 추가

```yaml
# pubspec.yaml
firebase_messaging: ^15.1.0
```

### 3-2. push_notification_service.dart (신규)

```dart
// lib/data/services/push_notification_service.dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/filter_state.dart';

class PushNotificationService {
  static final _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  Future<void> init() async {
    // 1. 권한 요청 (iOS 필수, Android 13+)
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. FCM 토큰 발급 → 서버 등록
    _currentToken = await _messaging.getToken();
    if (_currentToken != null) await _upsertSubscription(_currentToken!);

    // 3. 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((newToken) async {
      final oldToken = _currentToken;
      _currentToken = newToken;
      await _upsertSubscription(newToken, oldToken: oldToken);
    });
  }

  Future<void> _upsertSubscription(String token, {String? oldToken}) async {
    final client = Supabase.instance.client;
    try {
      if (oldToken != null) {
        await client.from('push_subscriptions')
          .update({'fcm_token': token, 'updated_at': DateTime.now().toIso8601String()})
          .eq('fcm_token', oldToken);
      } else {
        await client.from('push_subscriptions').upsert({
          'fcm_token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'filter_state': {},
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'fcm_token');
      }
    } catch (_) {}
  }

  /// 필터 변경 시 서버 동기화
  Future<void> syncFilters(FilterState filter, String langCode) async {
    if (_currentToken == null) return;
    try {
      await Supabase.instance.client.from('push_subscriptions')
        .update({
          'filter_state': filter.toJson(),
          'language_code': langCode,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('fcm_token', _currentToken!);
    } catch (_) {}
  }

  /// 알림 켜기/끄기
  Future<void> setActive(bool active) async {
    if (_currentToken == null) return;
    try {
      await Supabase.instance.client.from('push_subscriptions')
        .update({'is_active': active, 'updated_at': DateTime.now().toIso8601String()})
        .eq('fcm_token', _currentToken!);
    } catch (_) {}
  }
}

final pushService = PushNotificationService();
```

### 3-3. main.dart 수정

```dart
// 파일 최상단에 백그라운드 핸들러 추가
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  // ... 기존 초기화 코드 ...

  // Firebase 초기화 후 추가:
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await pushService.init();

  runApp(const ProviderScope(child: DariApp()));
}
```

### 3-4. app.dart — 필터 동기화 + 알림 탭 처리

```dart
// DariApp 또는 HomeScreen의 ConsumerWidget에서:

// 필터 변경 시 서버 동기화
ref.listen(filterStateProvider, (prev, next) {
  final lang = ref.read(languageProvider);
  pushService.syncFilters(next, lang);
});

// 알림 탭 → 홈 이동
FirebaseMessaging.instance.getInitialMessage().then((msg) {
  if (msg != null) router.go('/home');
});
FirebaseMessaging.onMessageOpenedApp.listen((msg) {
  router.go('/home');
});
```

### 3-5. AndroidManifest.xml

```xml
<!-- <manifest> 레벨 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- <application> 내부 -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="daily_jobs" />
```

---

## 4. 수정 대상 파일 목록

### Flutter (앱 코드)
| 파일 | 변경 |
|------|------|
| `pubspec.yaml` | firebase_messaging 추가 |
| `lib/data/services/push_notification_service.dart` | **신규 생성** |
| `lib/main.dart` | pushService.init(), 백그라운드 핸들러 |
| `lib/app.dart` | 필터 동기화 리스너, 알림 탭 처리 |
| `android/app/src/main/AndroidManifest.xml` | 퍼미션, 채널 meta-data |

### Supabase (서버)
| 작업 | 위치 |
|------|------|
| push_subscriptions 테이블 + RLS | SQL Editor |
| get_jobs_count RPC 수정 (p_crawled_after) | SQL Editor |
| send-daily-push Edge Function | Supabase CLI 배포 |
| FCM 서비스 계정 JSON | Supabase Secrets |
| pg_cron 스케줄 등록 | SQL Editor |

### Firebase Console
| 작업 |
|------|
| FCM 서비스 계정 키 다운로드 (프로젝트 설정 → 서비스 계정) |
| (iOS 시) APNs 키 등록 |

---

## 5. 검증 체크리스트

- [ ] 앱 설치 → push_subscriptions 테이블에 행 생성 확인
- [ ] 필터 변경 → DB filter_state 컬럼 업데이트 확인
- [ ] curl로 Edge Function 수동 호출 → FCM 발송 확인
- [ ] 디바이스에서 알림 수신 확인
- [ ] 알림 탭 → 앱 열리고 /home 이동 확인
- [ ] 새 공고 0건인 구독자에게는 미발송 확인
- [ ] 앱 삭제 후 UNREGISTERED 토큰 → is_active=false 처리 확인

---

## 6. 주의사항 & 나중에 할 것

### 주의사항
- **buildRpcParams 동기화**: Edge Function의 필터→RPC 변환 로직이 Dart 코드와 정확히 일치해야 함. 앱에서 필터 로직 변경 시 Edge Function도 함께 수정 필요
- **빈 필터 처리**: 필터가 전혀 없는 사용자는 전체 새 공고 수를 받게 됨 → 숫자가 너무 크면 의미 없을 수 있음
- **Edge Function 타임아웃**: 구독자가 많아지면(수천 명+) 60초 내 처리 불가 → 배치 처리 또는 pg_net 직접 FCM 호출로 변경 필요

### 나중에 할 것 (Phase 2+)
- iOS 지원 (APNs 키, GoogleService-Info.plist)
- 대량 구독자 배치 처리
- 알림 분석 이벤트 (수신/탭/무시 추적)
- 알림 내용 상세화 (공고 제목 미리보기 등)

---

## 7. 알림 UI 설계 (확정)

### 구성 요소 2가지

**A. 홈 헤더 벨 아이콘** — 상시 on/off 토글

```
┌─────────────────────────────────┐
│  🔍 검색...        🔔  ♥  🌐   │
│  ─────────────────────────────  │
│  All  WorkOn  K-Work  ...      │
│  [비자:E-7] [서울] [×]          │
│  ─────────────────────────────  │
│  Total 17,725    최신순 ▼       │
│  ...                            │
└─────────────────────────────────┘

🔔 활성 = carrot색 (#FF6F0F)
🔔 비활성 = gray
탭하면 on/off 토글
```

**B. 안내 바텀시트** — 최초 1회 자동 표시

```
┌─────────────────────────────────┐
│                                  │
│            🔔                    │
│                                  │
│   새 공고 알림을 받아보세요       │
│                                  │
│   설정한 필터에 맞는 새 공고가    │
│   올라오면 매일 알려드려요        │
│                                  │
│  ┌─────────────────────────┐    │
│  │       알림 받기          │    │
│  └─────────────────────────┘    │
│        나중에 할게요             │
└─────────────────────────────────┘
```

### 동작 흐름

1. **홈 진입 시**: SharedPreferences `push_prompt_shown` 키 확인
2. **키 없으면** → 바텀시트 표시 (신규/기존 사용자 모두 해당)
3. **"알림 받기"** → 시스템 알림 권한 요청 → push ON → `push_prompt_shown = true`
4. **"나중에 할게요"** → 닫기 → `push_prompt_shown = true` → 스낵바: "🔔 아이콘을 눌러 언제든 알림을 켤 수 있어요"
5. **이후**: 홈 헤더 🔔 아이콘으로 on/off 토글
6. **필터 변경 시**: 알림 ON이면 자동으로 서버에 최신 필터 동기화 (묻지 않음)
7. **알림 OFF이면**: 서버 동기화 안 함 (불필요한 호출 절약)

### 기본 상태
- 알림: **OFF** (사용자가 명시적으로 켜야 함)
- 바텀시트: `push_prompt_shown` 키 없는 모든 사용자에게 1회 표시
