import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  final infoPlist = File('$root/ios/Runner/Info.plist');
  final podfile = File('$root/ios/Podfile');
  final appDelegate = File('$root/ios/Runner/AppDelegate.swift');
  final sceneDelegate = File('$root/ios/Runner/SceneDelegate.swift');
  final registrar = File('$root/ios/Runner/ClientBridgeRegistrar.swift');

  test('Info.plist declares iOS report permission usage descriptions', () {
    final content = infoPlist.readAsStringSync();

    expect(content, contains('NSUserTrackingUsageDescription'));
    expect(content, contains('NSLocationWhenInUseUsageDescription'));
  });

  test('Podfile compiles permission handler features used by the app', () {
    final content = podfile.readAsStringSync();

    expect(content, contains('PERMISSION_CAMERA=1'));
    expect(content, contains('PERMISSION_LOCATION_WHENINUSE=1'));
  });

  test('iOS registrar exposes report method and event channels', () {
    final content = registrar.readAsStringSync();

    expect(content, contains('kaibigan_loan/report_method'));
    expect(content, contains('kaibigan_loan/report_event'));
    expect(content, contains('requestNotificationPermission'));
    expect(content, contains('requestTrackingPermission'));
    expect(content, contains('requestLocationPermission'));
    expect(content, contains('getTrackingStatus'));
    expect(content, contains('getLocation'));
    expect(content, contains('getPushToken'));
    expect(content, contains('getDeviceSnapshot'));
    expect(content, contains('FlutterStreamHandler'));
  });

  test('iOS report bridge buffers and emits notification routes', () {
    final content = registrar.readAsStringSync();

    expect(content, contains('func acceptNotificationPayload('));
    expect(content, contains('"push_route"'));
    expect(content, contains('pendingNotificationRoutes'));
    expect(content, contains('JSONSerialization.jsonObject'));
    expect(content, contains('userInfo["url"]'));
    expect(content, contains('userInfo["params"]'));
  });

  test('AppDelegate forwards foreground and clicked notifications', () {
    final content = appDelegate.readAsStringSync();

    expect(
      content,
      contains('UNUserNotificationCenter.current().delegate = self'),
    );
    expect(content, contains('willPresent notification: UNNotification'));
    expect(content, contains('didReceive response: UNNotificationResponse'));
    expect(
      content,
      contains('ClientBridgeRegistrar.shared.acceptNotificationPayload'),
    );
    expect(content, contains('routed ? [] : [.banner, .badge, .sound]'));
  });

  test('iOS registers for APNs regardless of notification permission', () {
    final content = registrar.readAsStringSync();
    final methodStart = content.indexOf(
      'private func requestNotificationPermission(',
    );
    final methodEnd = content.indexOf(
      '\n  private func requestTrackingPermission(',
      methodStart,
    );

    expect(methodStart, isNonNegative);
    expect(methodEnd, greaterThan(methodStart));
    final methodBody = content.substring(methodStart, methodEnd);
    expect(
      methodBody,
      contains('UIApplication.shared.registerForRemoteNotifications()'),
    );
    expect(methodBody, isNot(contains('if granted {')));
  });

  test('iOS location reads never request permission implicitly', () {
    final content = registrar.readAsStringSync();
    final methodStart = content.indexOf('private func getLocation(');
    final methodEnd = content.indexOf(
      '\n  func locationManagerDidChangeAuthorization',
      methodStart,
    );

    expect(methodStart, isNonNegative);
    expect(methodEnd, greaterThan(methodStart));
    final methodBody = content.substring(methodStart, methodEnd);
    expect(methodBody, contains('case .notDetermined:'));
    expect(methodBody, contains('result(locationPayload(location: nil'));
    expect(methodBody, isNot(contains('requestWhenInUseAuthorization()')));
  });

  test(
    'iOS product permission request replaces and restarts pending request',
    () {
      final content = registrar.readAsStringSync();
      final methodStart = content.indexOf(
        'private func requestLocationPermission(',
      );

      expect(methodStart, isNonNegative);
      if (methodStart < 0) {
        return;
      }
      final methodEnd = content.indexOf(
        '\n  private func getLocation(',
        methodStart,
      );
      expect(methodEnd, greaterThan(methodStart));
      final methodBody = content.substring(methodStart, methodEnd);
      expect(methodBody, contains('pendingLocationPermissionResult'));
      expect(methodBody, contains('previousResult("interrupted")'));
      expect(methodBody, contains('requestWhenInUseAuthorization()'));
    },
  );

  test('iOS location bridge queues concurrent reads as one native request', () {
    final content = registrar.readAsStringSync();

    expect(content, contains('pendingLocationResults'));
    expect(content, contains('isRequestingLocation'));
    expect(content, contains('pendingLocationResults[id] = result'));
    expect(content, contains('guard !isRequestingLocation else {'));
    expect(content, contains('guard !geocoder.isGeocoding else {'));
    expect(content, contains('completeAllLocationRequests'));
    expect(content, isNot(contains('private var pendingLocationResult:')));
    expect(content, isNot(contains('geocoder.cancelGeocode()')));
  });

  test('iOS location bridge starts continuous location updates', () {
    final content = registrar.readAsStringSync();
    final methodStart = content.indexOf('private func startLocationIfNeeded()');

    expect(methodStart, isNonNegative);
    if (methodStart < 0) {
      return;
    }
    final methodEnd = content.indexOf(
      '\n  private func completeAllLocationRequests(',
      methodStart,
    );
    expect(methodEnd, greaterThan(methodStart));
    final methodBody = content.substring(methodStart, methodEnd);
    expect(methodBody, contains('locationManager.startUpdatingLocation()'));
    expect(methodBody, isNot(contains('locationManager.requestLocation()')));
  });

  test(
    'iOS location bridge stops continuous updates when completing reads',
    () {
      final content = registrar.readAsStringSync();
      final methodStart = content.indexOf(
        'private func completeAllLocationRequests(',
      );

      expect(methodStart, isNonNegative);
      if (methodStart < 0) {
        return;
      }
      final methodEnd = content.indexOf(
        '\n  private func locationAuthorizationStatus()',
        methodStart,
      );
      expect(methodEnd, greaterThan(methodStart));
      final methodBody = content.substring(methodStart, methodEnd);
      expect(methodBody, contains('locationManager.stopUpdatingLocation()'));
    },
  );

  test('iOS location bridge times out pending reads after ten seconds', () {
    final content = registrar.readAsStringSync();

    expect(
      content,
      contains('private let locationRequestTimeoutInterval: TimeInterval = 10'),
    );
    expect(content, contains('private var activeLocationRequestID: UUID?'));
    expect(
      content,
      contains('private var locationRequestTimeout: DispatchWorkItem?'),
    );
    expect(content, contains('DispatchQueue.main.asyncAfter'));
    expect(content, contains('activeLocationRequestID == requestID'));
    expect(content, contains('locationRequestTimeout?.cancel()'));
  });

  test('iOS bridge registers with the initialized Flutter engine', () {
    final appContent = appDelegate.readAsStringSync();
    final sceneContent = sceneDelegate.readAsStringSync();
    final registrarContent = registrar.readAsStringSync();

    expect(
      appContent,
      contains('engineBridge.applicationRegistrar.messenger()'),
    );
    expect(appContent, isNot(contains('window?.rootViewController')));
    expect(sceneContent, isNot(contains('ClientBridgeRegistrar.shared')));
    expect(
      registrarContent,
      contains('func register(with messenger: FlutterBinaryMessenger)'),
    );
  });

  test('iOS bridge reports network availability with NWPathMonitor', () {
    final content = registrar.readAsStringSync();

    expect(content, contains('import Network'));
    expect(content, contains('NWPathMonitor()'));
    expect(content, contains('case "isNetworkAvailable"'));
    expect(content, contains('currentPath.status == .satisfied'));
  });

  test('iOS bridge collects Salmon-compatible hardware values', () {
    final podContent = podfile.readAsStringSync();
    final content = registrar.readAsStringSync();

    expect(podContent, contains("pod 'DeviceKit', '5.7.0'"));
    expect(content, contains('import DeviceKit'));
    expect(content, contains('"board": "QC_Reference_Phone"'));
    expect(content, contains('"brand": "iPhone"'));
    expect(content, contains('"model": Device.current.description'));
    expect(content, contains('"screenHeight": Int(screen.height)'));
    expect(content, contains('"screenWidth": Int(screen.width)'));
    expect(content, isNot(contains('screen.height * UIScreen.main.scale')));
    expect(content, isNot(contains('screen.width * UIScreen.main.scale')));
  });

  test('iOS bridge builds full address in reporting order', () {
    final content = registrar.readAsStringSync();

    expect(
      content,
      contains(
        'let streetNumber = [placemark.thoroughfare, '
        'placemark.subThoroughfare]',
      ),
    );
    expect(
      content,
      contains(
        'let parts = [placemark.country, placemark.administrativeArea, '
        'placemark.locality, placemark.subAdministrativeArea, '
        'placemark.subLocality, streetNumber]',
      ),
    );
  });

  test('iOS bridge reads street from the placemark street field', () {
    final content = registrar.readAsStringSync();
    final methodStart = content.indexOf(
      'private func street(from placemark: CLPlacemark?)',
    );

    expect(content, contains('import Contacts'));
    expect(methodStart, isNonNegative);
    if (methodStart < 0) {
      return;
    }
    final methodEnd = content.indexOf(
      '\n  private func fullAddress(',
      methodStart,
    );
    expect(methodEnd, greaterThan(methodStart));
    final methodBody = content.substring(methodStart, methodEnd);
    expect(methodBody, contains('placemark.postalAddress?.street'));
    expect(methodBody, isNot(contains('placemark.subThoroughfare')));
    expect(methodBody, isNot(contains('placemark.thoroughfare')));
    expect(methodBody, isNot(contains('placemark.subLocality')));
    expect(methodBody, isNot(contains('placemark.name')));
  });

  test('iOS registrar collects report fields instead of hardcoding blanks', () {
    final content = registrar.readAsStringSync();

    expect(content, contains('import CoreTelephony'));
    expect(content, contains('import NetworkExtension'));
    expect(content, contains('import SystemConfiguration.CaptiveNetwork'));
    expect(content, contains('buildDeviceSnapshot(result: result)'));
    expect(content, contains('fetchCurrentSSIDBSSID'));
    expect(content, contains('"carrier": currentCarrierName()'));
    expect(content, contains('"networkType": currentNetworkType()'));
    expect(content, contains('"innerIp": wifiIPv4Address()'));
    expect(content, contains('"availableMemory": currentAvailableMemory()'));
    expect(content, contains('geocoder.reverseGeocodeLocation'));
  });

  test('iOS registrar reports timezone as a GMT offset', () {
    final content = registrar.readAsStringSync();

    expect(content, contains('"timeZoneName": gmtTimeZone()'));
    expect(content, contains('private func gmtTimeZone() -> String'));
    expect(content, contains('return "GMT"'));
  });
}
