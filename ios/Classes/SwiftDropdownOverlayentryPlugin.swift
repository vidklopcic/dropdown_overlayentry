import Flutter
import UIKit

public class SwiftDropdownOverlayentryPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dropdown_overlayentry", binaryMessenger: registrar.messenger())
    let instance = SwiftDropdownOverlayentryPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
