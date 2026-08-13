import Flutter
import UIKit
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // 새 UIScene 구조(FlutterImplicitEngineDelegate)에서는 플러그인 등록이 늦어져
    // firebase_messaging이 didFinishLaunching 시점에 호출하는 registerForRemoteNotifications()가
    // 실행되지 않는다 → APNs 토큰이 영영 발급 안 됨. 여기서 직접 호출해 등록을 보장한다.
    application.registerForRemoteNotifications()
    return result
  }

  // Scene 생명주기(SceneDelegate)에서 Firebase 스위즐링이 APNs 토큰을 못 잡는 문제 우회:
  // 앱 델리게이트에서 APNs 토큰을 Firebase Messaging에 직접 전달.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // APNs 토큰 환경을 자동감지에 맡기면 TestFlight/App Store(production) 빌드에서
    // sandbox로 오판돼 BadEnvironmentKeyInToken 발생 → 빌드 구성에 맞춰 명시적으로 지정.
    #if DEBUG
    Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
    #else
    Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
    #endif
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // APNs 등록 실패 시 에러 로그 (원인 추적용 — 유지).
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
