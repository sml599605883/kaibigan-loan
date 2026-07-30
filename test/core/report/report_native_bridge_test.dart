import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/report/report_native_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/report_method');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('requests location permission through the native report channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 'authorized_when_in_use';
        });
    final bridge = MethodChannelReportNativeBridge(methodChannel: channel);

    final status = await bridge.requestLocationPermission();

    expect(status, 'authorized_when_in_use');
    expect(calls.map((call) => call.method), ['requestLocationPermission']);
  });
}
