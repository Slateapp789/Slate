import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var statusBarScrollBridge: WorkloopStatusBarScrollBridge?

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
      statusBarScrollBridge = WorkloopStatusBarScrollBridge(controller: controller)
    }
    return launched
  }
}

private final class WorkloopStatusBarScrollBridge: NSObject, UIScrollViewDelegate {
  private let channel: FlutterMethodChannel
  private let detector = UIScrollView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

  init(controller: FlutterViewController) {
    channel = FlutterMethodChannel(
      name: "com.ismaeel.workloop/navigation",
      binaryMessenger: controller.binaryMessenger
    )
    super.init()
    detector.delegate = self
    detector.scrollsToTop = true
    detector.contentSize = CGSize(width: 1, height: 2)
    detector.contentOffset = CGPoint(x: 0, y: 1)
    detector.backgroundColor = .clear
    detector.showsVerticalScrollIndicator = false
    detector.showsHorizontalScrollIndicator = false
    detector.isScrollEnabled = true
    detector.isUserInteractionEnabled = true
    detector.accessibilityElementsHidden = true
    controller.view.insertSubview(detector, at: 0)
  }

  func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
    channel.invokeMethod("scrollToTop", arguments: nil)
    return false
  }
}
