import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ClientBridge.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reports bridge unavailable on unsupported platforms', () async {
    final bridge = ClientBridge(platform: ClientPlatform.android);

    expect(await bridge.isNativeBridgeAvailable(), isFalse);
    expect(() => bridge.getPlatformInfo(), throwsA(isA<UnsupportedError>()));
    expect(() => bridge.getProxySettings(), throwsA(isA<UnsupportedError>()));
  });

  test('calls iOS method channel for bridge availability', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });

    final bridge = ClientBridge(platform: ClientPlatform.ios);

    expect(await bridge.isNativeBridgeAvailable(), isTrue);
    expect(calls.single.method, 'isNativeBridgeAvailable');
  });

  test('normalizes iOS platform info response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getPlatformInfo');
          return <String, Object?>{
            'platform': 'iPhone10,3',
            'systemVersion': '17.5',
            'appVersion': '1.0.0',
            'buildNumber': '1',
            'deviceId': 'stable-idfv',
          };
        });

    final bridge = ClientBridge(platform: ClientPlatform.ios);

    expect(
      await bridge.getPlatformInfo(),
      const ClientPlatformInfo(
        platform: 'iPhone10,3',
        systemVersion: '17.5',
        appVersion: '1.0.0',
        buildNumber: '1',
        deviceId: 'stable-idfv',
      ),
    );
  });

  test('normalizes iOS proxy settings response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getProxySettings');
          return <String, Object?>{
            'enabled': true,
            'host': '127.0.0.1',
            'port': '8888',
          };
        });

    final bridge = ClientBridge(platform: ClientPlatform.ios);

    expect(
      await bridge.getProxySettings(),
      const ClientProxySettings(enabled: true, host: '127.0.0.1', port: 8888),
    );
  });
}
