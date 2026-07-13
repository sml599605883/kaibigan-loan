import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  final infoPlist = File('$root/ios/Runner/Info.plist');
  final registrar = File('$root/ios/Runner/ClientBridgeRegistrar.swift');

  test('Info.plist declares iOS report permission usage descriptions', () {
    final content = infoPlist.readAsStringSync();

    expect(content, contains('NSUserTrackingUsageDescription'));
    expect(content, contains('NSLocationWhenInUseUsageDescription'));
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
