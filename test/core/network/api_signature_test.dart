import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_signature.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ClientBridge.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'gets obfuscated common parameters from client bridge and signs with path',
    () async {
      var bridgeCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            bridgeCalls++;
            expect(call.method, 'getPlatformInfo');
            return <String, Object?>{
              'platform': 'iPhone10,3',
              'systemVersion': '17.0',
              'appVersion': '1.0.0',
              'buildNumber': '1',
              'deviceId': 'idfv',
            };
          });

      final store = SessionStore.memory();
      await store.saveDeviceInfo(
        gyrofrequency: 'iPhone X',
        entertainers: '375x812',
      );
      await store.saveBungee('login-token');

      final config = ApiConfig(
        signatureSecret: 'secret',
        clientBridge: ClientBridge(platform: ClientPlatform.ios),
        sessionStore: store,
        timestampProvider: () => 1700000000000,
      );

      final helper = ApiSignature(config);
      final query = await helper.buildSignedQuery(path: '/v4/index/home-page');

      expect(bridgeCalls, 1);
      expect(query['hereat'], '1.0.0');
      expect(query['gyrofrequency'], 'iPhone X');
      expect(query['uncurling'], 'idfv');
      expect(query['wrongness'], '17.0');
      expect(query['justing'], 'appstore-ph-kaibigan-loan-ios');
      expect(query['bungee'], 'login-token');
      expect(query['killicks'], 'idfv');
      expect(query['curveballed'], '1700000000000');
      expect(query['sublimers'], isNull);
      expect(query['terrific'], hasLength(6));
      expect(query['feoffer'], hasLength(64));

      expect(
        query['feoffer'],
        ApiSignature.sign({
          'hereat': '1.0.0',
          'gyrofrequency': 'iPhone X',
          'uncurling': 'idfv',
          'wrongness': '17.0',
          'justing': 'appstore-ph-kaibigan-loan-ios',
          'bungee': 'login-token',
          'killicks': 'idfv',
          'curveballed': '1700000000000',
          'sublimers': '/v4/index/home-page',
        }, 'secret'),
      );
    },
  );
}
