import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_info.dart';
import '../models/filter_state.dart';
import 'analytics_service.dart';

class PushService {
  static final PushService _instance = PushService._();
  factory PushService() => _instance;
  PushService._();

  static const _tokenKey = 'fcm_token';
  static const _enabledKey = 'push_enabled';
  static const _syncedKey = 'push_synced';
  static const _toggleCountKey = 'push_toggle_count';
  static const _toggleDateKey = 'push_toggle_date';
  static const _maxTogglesPerDay = 10;

  String? _token;
  String? get token => _token;

  // init 완료 대기용
  Completer<void>? _initCompleter;

  SupabaseClient get _client => Supabase.instance.client;

  /// 초기화: 권한 요청 + 토큰 발급 (main.dart에서 1회만 호출)
  Future<void> init() {
    _initCompleter = Completer<void>();
    final future = _doInit();
    future.whenComplete(() {
      if (!_initCompleter!.isCompleted) _initCompleter!.complete();
    });
    return future;
  }

  /// init 완료 대기 (홈 화면 등에서 호출)
  Future<void> waitForInit() async {
    if (_initCompleter != null) await _initCompleter!.future;
  }

  Future<void> _doInit() async {
    final messaging = FirebaseMessaging.instance;

    if (Platform.isAndroid) {
      // 알림 채널 생성 (Android 전용)
      await _createNotificationChannel();
    } else if (Platform.isIOS) {
      // iOS: 포그라운드 수신 시 OS가 알림을 직접 표시 (로컬 알림 불필요)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // iOS: APNs 토큰 준비 전 getToken() 호출 시 예외 발생 (시뮬레이터는 APNs 미지원)
    try {
      if (Platform.isIOS) {
        // APNs 토큰은 등록 직후 비동기로 준비됨 — 콜드 스타트 첫 호출은 null이 잦아 잠깐 재시도.
        String? apns = await messaging.getAPNSToken();
        for (int i = 0; i < 20 && apns == null; i++) {
          await Future.delayed(const Duration(seconds: 1));
          apns = await messaging.getAPNSToken();
        }
        if (apns == null) {
          if (kDebugMode) print('🟡 APNs 토큰 없음 (시뮬레이터/미지원) — FCM 토큰 발급 생략');
          return;
        }
      }
      _token = await messaging.getToken();
    } catch (e) {
      if (kDebugMode) print('🔴 FCM 토큰 발급 실패: $e');
      return;
    }
    if (_token != null) {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString(_tokenKey);
      if (oldToken != _token) {
        await prefs.setString(_tokenKey, _token!);
        analytics.log('fcm_token_updated', {'new': true});
        if (oldToken != null) {
          _updateTokenOnServer(oldToken, _token!);
        }
      }
    }

    messaging.onTokenRefresh.listen((newToken) async {
      final oldToken = _token;
      _token = newToken;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, newToken);
      analytics.log('fcm_token_refreshed');
      if (oldToken != null && oldToken != newToken) {
        _updateTokenOnServer(oldToken, newToken);
      }
    });

    // 포그라운드 메시지 핸들러 (Android만 — iOS는 setForegroundNotificationPresentationOptions가 처리)
    if (Platform.isAndroid) {
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    }
  }

  /// Android 알림 채널 생성 (HIGH importance → 헤드업 + 잠금화면 표시)
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'dari_jobs',
      'New Jobs',
      description: 'New job alerts matching your filters',
      importance: Importance.high,
      showBadge: true,
      enableLights: true,
      enableVibration: true,
    );

    final flnPlugin = FlutterLocalNotificationsPlugin();
    await flnPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // flutter_local_notifications 초기화
    await flnPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
    );
  }

  /// 포그라운드에서 받은 메시지를 로컬 알림으로 표시
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final flnPlugin = FlutterLocalNotificationsPlugin();
    await flnPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'dari_jobs',
          'New Jobs',
          channelDescription: 'New job alerts matching your filters',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: Color(0xFFFF6F0F),
        ),
      ),
    );
  }

  /// 토큰 변경 시 서버 업데이트
  Future<void> _updateTokenOnServer(String oldToken, String newToken) async {
    try {
      await _client
          .from('push_subscriptions')
          .update({'device_token': newToken})
          .eq('device_token', oldToken);
    } catch (_) {}
  }

  /// 푸시 활성화 여부
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// 푸시 ON/OFF
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// 최초 동기화 완료 여부
  Future<bool> isSynced() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncedKey) ?? false;
  }

  /// 최초 동기화 완료 표시
  Future<void> markSynced() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncedKey, true);
  }

  /// 토글 횟수 제한 체크 (하루 10회, 디버그 무제한)
  Future<bool> canToggle() async {
    if (kDebugMode) return true;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_toggleDateKey);
    if (savedDate != today) {
      await prefs.setString(_toggleDateKey, today);
      await prefs.setInt(_toggleCountKey, 0);
      return true;
    }
    final count = prefs.getInt(_toggleCountKey) ?? 0;
    return count < _maxTogglesPerDay;
  }

  /// 토글 횟수 증가
  Future<void> incrementToggleCount() async {
    if (kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_toggleCountKey) ?? 0;
    await prefs.setInt(_toggleCountKey, count + 1);
  }

  /// 토큰 확보 (없으면 발급 시도). 실패 시 null — APNs 미지원 환경 등.
  Future<String?> _ensureToken() async {
    if (_token != null) return _token;
    try {
      _token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
    if (_token == null) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    return _token;
  }

  /// FilterState → 구독 저장용 JSON (기본 조건·키워드 조건 공용).
  static Map<String, dynamic> filterToJson(FilterState filter) => {
        'visaIds': filter.visaIds.toList(),
        'categoryIds': filter.categoryIds.toList(),
        'employmentTypeIds': filter.employmentTypeIds.toList(),
        'benefitIds': filter.benefitIds.toList(),
        'countryIds': filter.countryIds.toList(),
        'siteIds': filter.siteIds.toList(),
        'regionIds': filter.regionIds.toList(),
        'workScheduleIds': filter.workScheduleIds.toList(),
        'koreanLevelIds': filter.koreanLevelIds.toList(),
        'salaryTypes': filter.salaryTypes.toList(),
        'gender': filter.gender,
        'visaSponsorship': filter.visaSponsorship,
      };

  /// 서버에 구독 등록/갱신.
  /// 빈 필터면 filter_state=null로 행 유지 — 키워드 알림·추천 푸시(19시)가
  /// 같은 행을 쓰므로 삭제하면 안 됨(2026-10-09). 기본 조건 푸시는
  /// filter_state null이면 크롤러가 스킵.
  Future<void> upsertSubscription({
    required FilterState filter,
    required String langCode,
  }) async {
    if (await _ensureToken() == null) return;
    final enabled = await isEnabled();
    if (!enabled) return;

    try {
      await _client
          .from('push_subscriptions')
          .upsert({
            'device_token': _token!,
            'filter_state': filter.isEmpty ? null : filterToJson(filter),
            'lang_code': langCode,
            'enabled': true,
            // iOS 출시 대비 — 서버가 플랫폼별 발송/집계에 사용 (기본값 android라 필수)
            'platform': Platform.isIOS ? 'ios' : 'android',
            'app_version': await AppInfo.version(),
          }, onConflict: 'device_token');
      if (kDebugMode) print('🟢 push_subscriptions upsert 성공: token=${_token!.substring(0, 10)}...');
    } catch (e) {
      if (kDebugMode) print('🔴 push_subscriptions upsert 실패: $e');
    }
  }

  // ── 키워드 알림 조건 (기기당 1개, 2026-10-09) ──
  // 로컬(SharedPreferences)이 원본, 서버(push_subscriptions.search_*)는
  // 크롤러 매칭·발송용 사본. 조합 편집은 없음 — 재등록=교체.
  static const _searchCondKey = 'search_alert_condition';

  /// 저장된 키워드 조건 {'keyword','label','filter','enabled'} — 없으면 null.
  Future<Map<String, dynamic>?> getSearchCondition() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_searchCondKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// 키워드 조건 등록/교체. label은 표시용(저장 시점 언어의 칩 요약).
  Future<void> saveSearchCondition({
    required String keyword,
    required String label,
    required FilterState filter,
    required String langCode,
  }) async {
    final cond = {
      'keyword': keyword,
      'label': label,
      'filter': filterToJson(filter),
      'enabled': true,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchCondKey, jsonEncode(cond));
    if (await _ensureToken() == null) return;
    try {
      await _client.from('push_subscriptions').upsert({
        'device_token': _token!,
        'search_keyword': keyword,
        'search_filters': filterToJson(filter),
        'search_enabled': true,
        'lang_code': langCode,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'app_version': await AppInfo.version(),
      }, onConflict: 'device_token');
    } catch (e) {
      if (kDebugMode) print('🔴 search condition upsert 실패: $e');
    }
  }

  /// 키워드 조건 삭제.
  Future<void> clearSearchCondition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchCondKey);
    final token = _token ?? await getSavedToken();
    if (token == null) return;
    try {
      await _client.from('push_subscriptions').update({
        'search_keyword': null,
        'search_filters': null,
        'search_enabled': true,
      }).eq('device_token', token);
    } catch (_) {}
  }

  /// 키워드 조건 알림 켬/끔 (조건은 유지).
  Future<void> setSearchAlertEnabled(bool value) async {
    final cond = await getSearchCondition();
    if (cond == null) return;
    cond['enabled'] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchCondKey, jsonEncode(cond));
    final token = _token ?? await getSavedToken();
    if (token == null) return;
    try {
      await _client
          .from('push_subscriptions')
          .update({'search_enabled': value}).eq('device_token', token);
    } catch (_) {}
  }

  // ── 추천 공고 푸시(19시, 당일 미진입자) 켬/끔 — 2026-10-09 ──
  static const _recommendKey = 'recommend_push_enabled';

  Future<bool> isRecommendEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_recommendKey) ?? true;
  }

  Future<void> setRecommendEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recommendKey, value);
    final token = _token ?? await getSavedToken();
    if (token == null) return;
    try {
      await _client
          .from('push_subscriptions')
          .update({'recommend_enabled': value}).eq('device_token', token);
    } catch (_) {}
  }

  // ── 앱 진입 시각 — 추천 푸시 "당일 미진입자" 판정용(2026-10-09) ──
  static const _lastOpenedSyncKey = 'last_opened_synced_ms';

  /// 앱 실행/포그라운드 복귀 시 호출. 과호출 방지로 1시간에 1번만 서버 갱신.
  Future<void> touchLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastOpenedSyncKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < 60 * 60 * 1000) return;
    final token = _token ?? await getSavedToken();
    if (token == null) return;
    try {
      await _client.from('push_subscriptions').update(
          {'last_opened_at': DateTime.now().toUtc().toIso8601String()}).eq(
          'device_token', token);
      await prefs.setInt(_lastOpenedSyncKey, now);
    } catch (_) {}
  }

  /// 푸시 재활성화(설정 ON) 시 서버 행 전체 재동기화 — OFF 때 행이 삭제돼
  /// 키워드 조건·추천 설정도 함께 복원해야 함.
  Future<void> resyncServer({
    required FilterState filter,
    required String langCode,
  }) async {
    await upsertSubscription(filter: filter, langCode: langCode);
    final cond = await getSearchCondition();
    if (cond != null) {
      final token = _token ?? await getSavedToken();
      if (token == null) return;
      try {
        await _client.from('push_subscriptions').update({
          'search_keyword': cond['keyword'],
          'search_filters': cond['filter'],
          'search_enabled': cond['enabled'] ?? true,
        }).eq('device_token', token);
      } catch (_) {}
    }
    await setRecommendEnabled(await isRecommendEnabled());
  }

  /// 서버에서 구독 삭제 (푸시 OFF / 빈 필터)
  Future<void> deleteSubscription() async {
    var token = _token;
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString(_tokenKey);
      if (token == null) return;
    }
    try {
      await _client
          .from('push_subscriptions')
          .delete()
          .eq('device_token', token);
    } catch (_) {}
  }

  /// 저장된 토큰 가져오기
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}

final pushService = PushService();
