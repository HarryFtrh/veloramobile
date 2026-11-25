import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let updateChannel = FlutterMethodChannel(
        name: "com.velora.mobile/app_update",
        binaryMessenger: controller.binaryMessenger
      )
      updateChannel.setMethodCallHandler { call, result in
        if call.method == "getAppVersion" {
          let info = Bundle.main.infoDictionary
          let packageName = Bundle.main.bundleIdentifier ?? "com.velora.veloraMobile"
          let versionName = (info?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
          let buildStr = (info?["CFBundleVersion"] as? String) ?? "1"
          let versionCode = Int(buildStr) ?? 1
          result([
            "packageName": packageName,
            "versionName": versionName,
            "versionCode": versionCode,
          ])
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      let printerChannel = FlutterMethodChannel(
        name: "com.velora.mobile/printer",
        binaryMessenger: controller.binaryMessenger
      )
      printerChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "getPairedDevices":
          // iOS tidak menyediakan API RFCOMM SPP Bluetooth Classic untuk printer non-MFi;
          // gunakan printer LAN/WiFi (port 9100).
          result([])
        case "printBluetooth":
          result([
            "success": false,
            "message": "Printer Bluetooth Classic tidak didukung langsung di iOS. Gunakan Printer Jaringan (WiFi/LAN port 9100).",
          ])
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
