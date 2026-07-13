import AdSupport
import AppTrackingTransparency
import CFNetwork
import CoreLocation
import CoreTelephony
import Flutter
import NetworkExtension
import Security
import SystemConfiguration.CaptiveNetwork
import TDMobRisk
import UIKit
import Darwin
import UserNotifications

final class ClientBridgeRegistrar: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  static let shared = ClientBridgeRegistrar()

  private let trustDecisionPartnerCode = "boqin_ph"
  private let trustDecisionPartnerKey = "1dc25522f2adc77f5347816c0f7fa31b"
  private let pushTokenKey = "report.apple_push_token"
  private lazy var trustDecisionManager = TDMobRiskManager.sharedManager()
  private lazy var locationManager = CLLocationManager()
  private let geocoder = CLGeocoder()
  private var hasConfiguredTrustDecision = false
  private var eventSink: FlutterEventSink?
  private var pendingLocationResult: FlutterResult?

  private override init() {
    super.init()
    locationManager.delegate = self
    UIDevice.current.isBatteryMonitoringEnabled = true
  }

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

    let reportChannel = FlutterMethodChannel(
      name: "kaibigan_loan/report_method",
      binaryMessenger: controller.binaryMessenger
    )
    reportChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "requestNotificationPermission":
        self.requestNotificationPermission(result: result)
      case "requestTrackingPermission":
        self.requestTrackingPermission(result: result)
      case "getTrackingStatus":
        result(self.trackingStatusString())
      case "getLocation":
        self.getLocation(result: result)
      case "getPushToken":
        result(UserDefaults.standard.string(forKey: self.pushTokenKey) ?? "")
      case "getDeviceSnapshot":
        self.buildDeviceSnapshot(result: result)
      case "initializeAttribution":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let reportEventChannel = FlutterEventChannel(
      name: "kaibigan_loan/report_event",
      binaryMessenger: controller.binaryMessenger
    )
    reportEventChannel.setStreamHandler(self)
  }

  func updatePushToken(_ deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    UserDefaults.standard.set(token, forKey: pushTokenKey)
    eventSink?(["type": "push_token", "token": token])
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    if let token = UserDefaults.standard.string(forKey: pushTokenKey), !token.isEmpty {
      events(["type": "push_token", "token": token])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
      DispatchQueue.main.async {
        if granted {
          UIApplication.shared.registerForRemoteNotifications()
        }
        result(granted ? "authorized" : "denied")
      }
    }
  }

  private func requestTrackingPermission(result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      ATTrackingManager.requestTrackingAuthorization { status in
        let value = self.trackingStatusString(status)
        DispatchQueue.main.async {
          self.eventSink?(["type": "tracking_status_changed", "status": value])
          result(value)
        }
      }
    } else {
      eventSink?(["type": "tracking_status_changed", "status": "not_supported"])
      result("not_supported")
    }
  }

  private func getLocation(result: @escaping FlutterResult) {
    let status = locationAuthorizationStatus()
    switch status {
    case .notDetermined:
      pendingLocationResult = result
      locationManager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse:
      pendingLocationResult = result
      locationManager.requestLocation()
    default:
      result(locationPayload(location: nil, status: locationStatusString(status)))
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = locationAuthorizationStatus()
    if status == .authorizedAlways || status == .authorizedWhenInUse {
      manager.requestLocation()
    } else if let result = pendingLocationResult, status != .notDetermined {
      pendingLocationResult = nil
      result(locationPayload(location: nil, status: locationStatusString(status)))
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let result = pendingLocationResult else {
      return
    }
    pendingLocationResult = nil
    guard let location = locations.last else {
      result(locationPayload(location: nil, status: locationStatusString(locationAuthorizationStatus())))
      return
    }

    if geocoder.isGeocoding {
      geocoder.cancelGeocode()
    }
    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
      guard let self else {
        return
      }
      result(self.locationPayload(
        location: location,
        placemark: placemarks?.first,
        status: self.locationStatusString(self.locationAuthorizationStatus())
      ))
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    guard let result = pendingLocationResult else {
      return
    }
    pendingLocationResult = nil
    result(locationPayload(location: nil, status: locationStatusString(locationAuthorizationStatus())))
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

  private func buildDeviceSnapshot(result: @escaping FlutterResult) {
    fetchCurrentSSIDBSSID { [weak self] wifiName, wifiBssid in
      guard let self else {
        result([String: Any]())
        return
      }
      result(self.deviceSnapshot(
        wifiCount: self.currentWifiNetworkInfos().count,
        currentWifiName: wifiName,
        currentWifiBssid: wifiBssid
      ))
    }
  }

  private func deviceSnapshot(
    wifiCount: Int,
    currentWifiName: String,
    currentWifiBssid: String
  ) -> [String: Any] {
    let info = Bundle.main.infoDictionary
    let screen = UIScreen.main.bounds
    let batteryLevel = UIDevice.current.batteryLevel >= 0
      ? Int(UIDevice.current.batteryLevel * 100)
      : 0
    let storage = storageInfo()
    return [
      "idfv": stableVendorIdentifier(),
      "idfa": advertisingIdentifier(),
      "deviceId": stableVendorIdentifier(),
      "batteryLevel": batteryLevel,
      "isCharging": UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full ? 1 : 0,
      "elapsedMillis": Int(ProcessInfo.processInfo.systemUptime * 1000),
      "uptimeMillis": "\(Int(ProcessInfo.processInfo.systemUptime * 1000))",
      "isUsingProxy": currentProxySettings()["enabled"] as? Bool == true ? 1 : 0,
      "isUsingVpn": isUsingVpn() ? 1 : 0,
      "isJailbroken": isJailbroken() ? 1 : 0,
      "isEmulator": isSimulator() ? 1 : 0,
      "language": Locale.current.languageCode ?? "",
      "carrier": currentCarrierName(),
      "networkType": currentNetworkType(),
      "timeZoneName": gmtTimeZone(),
      "cpuCoreCount": ProcessInfo.processInfo.processorCount,
      "brand": "Apple",
      "deviceName": UIDevice.current.name,
      "model": deviceModelName(),
      "systemVersion": UIDevice.current.systemVersion,
      "appVersion": info?["CFBundleShortVersionString"] as? String ?? "",
      "packageName": Bundle.main.bundleIdentifier ?? "",
      "screenHeight": Int(screen.height * UIScreen.main.scale),
      "screenWidth": Int(screen.width * UIScreen.main.scale),
      "screenSize": "\(Int(screen.width * UIScreen.main.scale))x\(Int(screen.height * UIScreen.main.scale))",
      "innerIp": wifiIPv4Address(),
      "currentWifiName": currentWifiName,
      "currentWifiBssid": currentWifiBssid,
      "wifiCount": wifiCount,
      "availableStorage": "\(storage.available)",
      "totalStorage": "\(storage.total)",
      "totalMemory": "\(ProcessInfo.processInfo.physicalMemory)",
      "availableMemory": currentAvailableMemory(),
      "pushToken": UserDefaults.standard.string(forKey: pushTokenKey) ?? "",
      "riskDeviceId": stableVendorIdentifier()
    ]
  }

  private func advertisingIdentifier() -> String {
    if #available(iOS 14, *) {
      guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
        return ""
      }
    }
    return ASIdentifierManager.shared().advertisingIdentifier.uuidString
  }

  private func fetchCurrentSSIDBSSID(completion: @escaping (String, String) -> Void) {
    if #available(iOS 14.0, *) {
      NEHotspotNetwork.fetchCurrent { [weak self] network in
        let ssid = network?.ssid ?? ""
        let bssid = network?.bssid ?? ""
        if !ssid.isEmpty || !bssid.isEmpty {
          completion(ssid, bssid)
          return
        }
        let fallback = self?.legacySSIDBSSID() ?? ("", "")
        completion(fallback.0, fallback.1)
      }
      return
    }

    let fallback = legacySSIDBSSID()
    completion(fallback.0, fallback.1)
  }

  private func legacySSIDBSSID() -> (String, String) {
    guard let network = currentWifiNetworkInfos().first else {
      return ("", "")
    }
    return (network.ssid, network.bssid)
  }

  private func currentWifiNetworkInfos() -> [(ssid: String, bssid: String)] {
    guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
      return []
    }

    return interfaces.compactMap { interface in
      guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else {
        return nil
      }
      let ssid = info[kCNNetworkInfoKeySSID as String] as? String ?? ""
      let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String ?? ""
      return ssid.isEmpty && bssid.isEmpty ? nil : (ssid, bssid)
    }
  }

  private func currentCarrierName() -> String {
    let networkInfo = CTTelephonyNetworkInfo()
    return networkInfo.serviceSubscriberCellularProviders?.values.first?.carrierName ?? ""
  }

  private func currentNetworkType() -> String {
    if activeInterfaceNames().contains("en0") {
      return "WIFI"
    }

    let radioTech = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology?.values.first
    switch radioTech {
    case CTRadioAccessTechnologyGPRS,
      CTRadioAccessTechnologyEdge,
      CTRadioAccessTechnologyCDMA1x:
      return "2G"
    case CTRadioAccessTechnologyWCDMA,
      CTRadioAccessTechnologyHSDPA,
      CTRadioAccessTechnologyHSUPA,
      CTRadioAccessTechnologyCDMAEVDORev0,
      CTRadioAccessTechnologyCDMAEVDORevA,
      CTRadioAccessTechnologyCDMAEVDORevB,
      CTRadioAccessTechnologyeHRPD:
      return "3G"
    case CTRadioAccessTechnologyLTE:
      return "4G"
    default:
      if #available(iOS 14.1, *),
         radioTech == CTRadioAccessTechnologyNR ||
         radioTech == CTRadioAccessTechnologyNRNSA {
        return "5G"
      }
      return "OTHER"
    }
  }

  private func gmtTimeZone() -> String {
    let offset = TimeZone.current.secondsFromGMT()
    guard offset != 0 else {
      return "GMT"
    }

    let sign = offset >= 0 ? "+" : "-"
    let totalMinutes = abs(offset) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    guard minutes != 0 else {
      return "GMT\(sign)\(hours)"
    }
    return String(format: "GMT%@%d:%02d", sign, hours, minutes)
  }

  private func wifiIPv4Address() -> String {
    var interfacePointer: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&interfacePointer) == 0, let firstInterface = interfacePointer else {
      return ""
    }
    defer { freeifaddrs(interfacePointer) }

    for interface in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
      guard let address = interface.pointee.ifa_addr,
            address.pointee.sa_family == UInt8(AF_INET),
            String(cString: interface.pointee.ifa_name) == "en0" else {
        continue
      }
      var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
      var socketAddress = address.pointee
      if getnameinfo(
        &socketAddress,
        socklen_t(address.pointee.sa_len),
        &hostname,
        socklen_t(hostname.count),
        nil,
        0,
        NI_NUMERICHOST
      ) == 0 {
        return String(cString: hostname)
      }
    }
    return ""
  }

  private func activeInterfaceNames() -> Set<String> {
    var interfacePointer: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&interfacePointer) == 0, let firstInterface = interfacePointer else {
      return []
    }
    defer { freeifaddrs(interfacePointer) }

    var names = Set<String>()
    for interface in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
      let flags = Int32(interface.pointee.ifa_flags)
      guard (flags & IFF_UP) == IFF_UP, (flags & IFF_RUNNING) == IFF_RUNNING else {
        continue
      }
      names.insert(String(cString: interface.pointee.ifa_name))
    }
    return names
  }

  private func trackingStatusString() -> String {
    if #available(iOS 14, *) {
      return trackingStatusString(ATTrackingManager.trackingAuthorizationStatus)
    }
    return "not_supported"
  }

  @available(iOS 14, *)
  private func trackingStatusString(_ status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .authorized:
      return "authorized"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .notDetermined:
      return "not_determined"
    @unknown default:
      return "unknown"
    }
  }

  private func locationPayload(
    location: CLLocation?,
    placemark: CLPlacemark? = nil,
    status: String
  ) -> [String: Any] {
    return [
      "province": placemark?.administrativeArea ?? "",
      "locality": placemark?.subAdministrativeArea ?? "",
      "fullAddress": fullAddress(from: placemark),
      "countryCode": placemark?.isoCountryCode ?? "",
      "country": placemark?.country ?? "",
      "street": street(from: placemark),
      "latitude": location.map { "\($0.coordinate.latitude)" } ?? "",
      "longitude": location.map { "\($0.coordinate.longitude)" } ?? "",
      "city": placemark?.locality ?? placemark?.subAdministrativeArea ?? "",
      "permissionStatus": status
    ]
  }

  private func street(from placemark: CLPlacemark?) -> String {
    guard let placemark else {
      return ""
    }
    let parts = [placemark.subThoroughfare, placemark.thoroughfare, placemark.subLocality, placemark.name]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    return uniqueAddressParts(parts).joined(separator: " ")
  }

  private func fullAddress(from placemark: CLPlacemark?) -> String {
    guard let placemark else {
      return ""
    }
    let parts = [placemark.name, placemark.subLocality, placemark.locality, placemark.subAdministrativeArea, placemark.administrativeArea, placemark.country]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    return uniqueAddressParts(parts).joined(separator: ", ")
  }

  private func uniqueAddressParts(_ parts: [String]) -> [String] {
    var seen = Set<String>()
    return parts.filter { seen.insert($0).inserted }
  }

  private func locationAuthorizationStatus() -> CLAuthorizationStatus {
    if #available(iOS 14, *) {
      return locationManager.authorizationStatus
    }
    return CLLocationManager.authorizationStatus()
  }

  private func locationStatusString(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .authorizedAlways:
      return "authorized_always"
    case .authorizedWhenInUse:
      return "authorized_when_in_use"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .notDetermined:
      return "not_determined"
    @unknown default:
      return "unknown"
    }
  }

  private func storageInfo() -> (total: Int64, available: Int64) {
    do {
      let values = try URL(fileURLWithPath: NSHomeDirectory()).resourceValues(
        forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
      )
      return (
        Int64(values.volumeTotalCapacity ?? 0),
        values.volumeAvailableCapacityForImportantUsage ?? 0
      )
    } catch {
      return (0, 0)
    }
  }

  private func currentAvailableMemory() -> String {
    var vmStats = vm_statistics_data_t()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics_data_t>.size / MemoryLayout<integer_t>.size
    )
    let status = withUnsafeMutableBytes(of: &vmStats) { rawBuffer in
      host_statistics(
        mach_host_self(),
        HOST_VM_INFO,
        rawBuffer.bindMemory(to: integer_t.self).baseAddress,
        &count
      )
    }
    guard status == KERN_SUCCESS else {
      return "0"
    }
    let bytes = UInt64(vm_page_size) * UInt64(vmStats.free_count) +
      UInt64(vm_page_size) * UInt64(vmStats.inactive_count)
    return "\(bytes)"
  }

  private func isUsingVpn() -> Bool {
    guard
      let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
      let scoped = settings["__SCOPED__"] as? [String: Any]
    else {
      return false
    }
    return scoped.keys.contains { key in
      key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") || key.contains("utun")
    }
  }

  private func isJailbroken() -> Bool {
#if targetEnvironment(simulator)
    return false
#else
    let paths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt"
    ]
    return paths.contains { FileManager.default.fileExists(atPath: $0) }
#endif
  }

  private func isSimulator() -> Bool {
#if targetEnvironment(simulator)
    return true
#else
    return false
#endif
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
