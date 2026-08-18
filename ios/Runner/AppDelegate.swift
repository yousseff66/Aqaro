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
    // 1. تهيئة خرائط جوجل
    GMSServices.provideAPIKey("AIzaSyAL-3NyNo1yug-JncZQwLFuqPhOZYjK1-w")

    // 2. تهيئة فايربيز
    FirebaseApp.configure()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
