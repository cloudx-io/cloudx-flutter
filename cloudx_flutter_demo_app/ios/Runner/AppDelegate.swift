import UIKit
import Flutter
import AppTrackingTransparency
import AdSupport

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Request App Tracking Transparency permission after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.requestTrackingPermission()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  func requestTrackingPermission() {
    if #available(iOS 14, *) {
      // Check current status first
      let currentStatus = ATTrackingManager.trackingAuthorizationStatus
      
      print("📊 [ATT] Current tracking authorization status: \(currentStatus.rawValue)")
      
      switch currentStatus {
      case .notDetermined:
        print("🔔 [ATT] Status not determined - requesting permission...")
        ATTrackingManager.requestTrackingAuthorization { status in
          switch status {
          case .authorized:
            print("✅ [ATT] Tracking permission GRANTED")
          case .denied:
            print("❌ [ATT] Tracking permission DENIED")
          case .restricted:
            print("⚠️ [ATT] Tracking permission RESTRICTED")
          case .notDetermined:
            print("❓ [ATT] Tracking permission NOT DETERMINED (still)")
          @unknown default:
            print("❓ [ATT] Unknown status")
          }
        }
        
      case .authorized:
        print("✅ [ATT] Already AUTHORIZED")
        
      case .denied:
        print("❌ [ATT] Previously DENIED - ads may not work properly")
        print("💡 [ATT] To fix: Delete app and reinstall, or go to Settings > Privacy > Tracking")
        
      case .restricted:
        print("⚠️ [ATT] RESTRICTED by device settings")
        
      @unknown default:
        print("❓ [ATT] Unknown status")
      }
    } else {
      print("📱 [ATT] iOS version < 14, ATT not required")
    }
  }
} 