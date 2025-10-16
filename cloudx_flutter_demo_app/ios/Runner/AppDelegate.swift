import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // DEMO APP ONLY: Force test mode for all bid requests
    // This internal flag ensures test=1 is always set in bid requests for demo app
    // regardless of build configuration (simulator/device, debug/release)
    UserDefaults.standard.set(true, forKey: "CLXCore_Internal_ForceTestMode")
    
    // DEMO APP ONLY: Enable Meta test mode for release builds
    // This ensures Meta SDK registers device as test device and serves test ads
    UserDefaults.standard.set(true, forKey: "CLXMetaTestModeEnabled")
    
    UserDefaults.standard.synchronize()
    
    print("✅ [Flutter AppDelegate] Test mode flags set: CLXCore_Internal_ForceTestMode=true, CLXMetaTestModeEnabled=true")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
} 