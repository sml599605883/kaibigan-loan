import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';
import 'package:kaibigan_loan/src/core/device/device_info_store.dart';
import 'package:kaibigan_loan/src/core/network/api_bootstrap.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_endpoints.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ClientBridge.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    Get.reset();
  });

  test('bootstraps ApiClient with native proxy before returning', () async {
    final adapter = _RecordingAdapter();
    final store = DeviceInfoStore.memory();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getPlatformInfo') {
            return <String, Object?>{
              'platform': 'iPhone10,3',
              'systemVersion': '17.0',
              'appVersion': '1.0.0',
              'buildNumber': '1',
              'deviceId': 'idfv',
            };
          }
          expect(call.method, 'getProxySettings');
          return <String, Object?>{'enabled': false, 'host': '', 'port': 0};
        });

    final apiClient = await bootstrapApiClient(
      clientBridge: ClientBridge(platform: ClientPlatform.ios),
      apiConfig: ApiConfig(
        apiBaseUrl: 'https://api.example.test',
        clientBridge: ClientBridge(platform: ClientPlatform.ios),
        deviceInfoStore: store,
        randomDigitsProvider: (length) => '7' * length,
      ),
      dio: Dio()..httpClientAdapter = adapter,
      deviceInfoStore: store,
    );

    expect(Get.find<ApiClient>(), same(apiClient));
    expect(apiClient.proxyHost, isNull);
    expect(apiClient.proxyPort, isNull);
    expect(
      adapter.lastRequest.path,
      'https://api.example.test${ApiEndpoints.getDeviceName}',
    );
    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.queryParameters['unwits'], isNull);
    expect(adapter.lastBody, {'unwits': 'iPhone10,3', 'stoups': '777777'});
    expect(await store.gyrofrequency(), 'iPhone X');
    expect(await store.entertainers(), '375x812');
  });

  test('does not return before native proxy lookup completes', () async {
    final completer = Completer<Map<String, Object?>>();
    final store = DeviceInfoStore.memory();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getPlatformInfo') {
            return <String, Object?>{
              'platform': 'iPhone10,3',
              'systemVersion': '17.0',
              'appVersion': '1.0.0',
              'buildNumber': '1',
              'deviceId': 'idfv',
            };
          }
          return completer.future;
        });

    var bootstrapCompleted = false;
    final bootstrap =
        bootstrapApiClient(
          clientBridge: ClientBridge(platform: ClientPlatform.ios),
          apiConfig: ApiConfig(deviceInfoStore: store),
          deviceInfoStore: store,
        ).then((apiClient) {
          bootstrapCompleted = true;
          return apiClient;
        });

    await Future<void>.delayed(Duration.zero);
    expect(bootstrapCompleted, isFalse);

    completer.complete(<String, Object?>{
      'enabled': true,
      'host': '127.0.0.1',
      'port': 8888,
    });

    final apiClient = await bootstrap;
    expect(bootstrapCompleted, isTrue);
    expect(apiClient.proxyHost, '127.0.0.1');
    expect(apiClient.proxyPort, 8888);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions lastRequest = RequestOptions();
  Object? lastBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    lastBody = options.data;
    return ResponseBody.fromString(
      jsonEncode({
        'griding': 0,
        'organizational': 'success',
        'fas': {'gyrofrequency': 'iPhone X', 'entertainers': '375x812'},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
