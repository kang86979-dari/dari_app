import Flutter
import UIKit
import UserNotifications

class SceneDelegate: FlutterSceneDelegate {

  // 앱이 포그라운드로 활성화될 때마다 앱 아이콘 배지를 0으로 리셋한다.
  // (UIScene 생명주기라 AppDelegate.applicationDidBecomeActive가 아닌 여기서 처리)
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(0)
    } else {
      UIApplication.shared.applicationIconBadgeNumber = 0
    }
  }
}
