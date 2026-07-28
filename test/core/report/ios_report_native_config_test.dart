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
    expect(content, contains('getTrackingStatus'));
    expect(content, contains('getLocation'));
    expect(content, contains('getPushToken'));
    expect(content, contains('getDeviceSnapshot'));
    expect(content, contains('FlutterStreamHandler'));
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
