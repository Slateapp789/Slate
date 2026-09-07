import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var stripeTerminalBridge: WorkloopStripeTerminalBridge?
  private var notificationSettingsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    if let controller = window?.rootViewController as? FlutterViewController {
      stripeTerminalBridge = WorkloopStripeTerminalBridge(controller: controller)
      let channel = FlutterMethodChannel(
        name: "workloop/notifications",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "openSettings" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let settingsURL: String
        if #available(iOS 16.0, *) {
          settingsURL = UIApplication.openNotificationSettingsURLString
        } else {
          settingsURL = UIApplication.openSettingsURLString
        }
        guard let url = URL(string: settingsURL) else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          result(opened)
        }
      }
      notificationSettingsChannel = channel
    }
    return launched
  }
}
