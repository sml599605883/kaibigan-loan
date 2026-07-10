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
}
