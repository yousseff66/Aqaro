import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // تهيئة خرائط جوجل
    GMSServices.provideAPIKey("AIzaSyAL-3NyNo1yug-JncZQwLFuqPhOZYjK1-w")

    // تشغيل فايربيز
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }

    // تعيين مفوض المراسلة
    Messaging.messaging().delegate = self

    // تسجيل الإشعارات
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    }

    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // استقبال توكن فايربيز
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("Device Token (APNs): \(token)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
