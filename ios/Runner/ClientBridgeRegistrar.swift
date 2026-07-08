import CFNetwork
import Flutter
import Security
import TDMobRisk
import UIKit
import Darwin

final class ClientBridgeRegistrar {
  static let shared = ClientBridgeRegistrar()

  private let trustDecisionPartnerCode = "boqin_ph"
  private let trustDecisionPartnerKey = "1dc25522f2adc77f5347816c0f7fa31b"
  private lazy var trustDecisionManager = TDMobRiskManager.sharedManager()
  private var hasConfiguredTrustDecision = false

  private init() {}

  func register(with controller: FlutterViewController?) {
    guard let controller else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "kaibigan_loan/client_bridge",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isNativeBridgeAvailable":
        result(true)
      case "getPlatformInfo":
        let info = Bundle.main.infoDictionary
        result([
          "platform": self.deviceModelName(),
          "systemVersion": UIDevice.current.systemVersion,
          "appVersion": info?["CFBundleShortVersionString"] as? String ?? "",
          "buildNumber": info?["CFBundleVersion"] as? String ?? "",
          "deviceId": self.stableVendorIdentifier()
        ])
      case "getProxySettings":
        result(self.currentProxySettings())
      case "showTrustDecisionLiveness":
        self.showTrustDecisionLiveness(call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    DispatchQueue.main.async { [weak self] in
      self?.configureTrustDecisionIfNeeded()
    }
  }

  private func configureTrustDecisionIfNeeded() {
    guard !hasConfiguredTrustDecision else {
      return
    }
    hasConfiguredTrustDecision = true
    var params: [String: Any] = [
      "partner": trustDecisionPartnerCode,
      "appKey": trustDecisionPartnerKey,
      "country": "sg",
      "language": "en"
    ]
#if DEBUG
    params["allowed"] = true
#endif
    trustDecisionManager?.pointee.initWithOptions(params)
  }

  private func showTrustDecisionLiveness(
    _ arguments: Any?,
    result: @escaping FlutterResult
  ) {
    configureTrustDecisionIfNeeded()
    let license = arguments as? String
    guard let viewController = topViewController() else {
      result([
        "success": false,
        "code": -1,
        "message": "find ViewController Error",
        "image": "",
        "sequence_id": "",
        "liveness_id": "",
        "raw": [:]
      ])
      return
    }

    trustDecisionManager?.pointee.showLivenessWithShowStyle(
      viewController,
      license,
      TDLivenessShowStylePresent,
      { successResult in
        result(self.wrapLivenessResult(success: true, payload: successResult))
      },
      { failResult in
        result(self.wrapLivenessResult(success: false, payload: failResult))
      }
    )
  }

  private func wrapLivenessResult(success: Bool, payload: [AnyHashable: Any]?) -> [String: Any] {
    let raw = (payload as? [String: Any]) ?? [:]
    let code = (raw["code"] as? NSNumber)?.intValue ?? (success ? 0 : -1)
    let message = raw["message"] as? String ?? ""
    let image = raw["image"] as? String ?? ""
    let sequenceId = raw["sequence_id"] as? String ?? ""
    let livenessId = raw["liveness_id"] as? String ?? ""
    return [
      "success": success,
      "code": code,
      "message": message,
      "image": image,
      "sequence_id": sequenceId,
      "liveness_id": livenessId,
      "raw": raw
    ]
  }

  private func topViewController(
    from viewController: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: \.isKeyWindow)?
      .rootViewController
  ) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = viewController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }
    if let presentedViewController = viewController?.presentedViewController {
      return topViewController(from: presentedViewController)
    }
    return viewController
  }

  private func currentProxySettings() -> [String: Any] {
    guard
      let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any]
    else {
      return ["enabled": false, "host": "", "port": 0]
    }

    return proxySettings(
      settings: settings,
      enabledKey: kCFNetworkProxiesHTTPEnable as String,
      hostKey: kCFNetworkProxiesHTTPProxy as String,
      portKey: kCFNetworkProxiesHTTPPort as String
    ) ?? ["enabled": false, "host": "", "port": 0]
  }

  private func proxySettings(
    settings: [String: Any],
    enabledKey: String,
    hostKey: String,
    portKey: String
  ) -> [String: Any]? {
    let enabled = (settings[enabledKey] as? NSNumber)?.boolValue ?? false
    let host = settings[hostKey] as? String ?? ""
    let port = (settings[portKey] as? NSNumber)?.intValue ?? 0
    guard enabled, !host.isEmpty, port > 0 else {
      return nil
    }
    return ["enabled": true, "host": host, "port": port]
  }

  private func stableVendorIdentifier() -> String {
    let service = "kaibigan_loan.client_bridge"
    let account = "stable_idfv"

    if let storedIdentifier = keychainValue(service: service, account: account),
       !storedIdentifier.isEmpty {
      return storedIdentifier
    }

    let identifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
    if !identifier.isEmpty {
      saveKeychainValue(identifier, service: service, account: account)
    }
    return identifier
  }

  private func deviceModelName() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let identifier = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        String(validatingUTF8: $0) ?? ""
      }
    }
    return identifier.isEmpty ? UIDevice.current.model : identifier
  }

  private func keychainValue(service: String, account: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  private func saveKeychainValue(_ value: String, service: String, account: String) {
    let data = Data(value.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      var item = query
      item[kSecValueData as String] = data
      item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      SecItemAdd(item as CFDictionary, nil)
    }
  }
}
