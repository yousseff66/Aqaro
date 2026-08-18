import UIKit
import Flutter
import FirebaseCore
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // تهيئة خرائط جوجل
    GMSServices.provideAPIKey("AIzaSyAL-3NyNo1yug-JncZQwLFuqPhOZYjK1-w")

    // تشغيل فايربيز (نترك الباقي للمكتبة تلقائياً)
    FirebaseApp.configure()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
