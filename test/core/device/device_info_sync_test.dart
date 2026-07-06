import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/core/device/device_info_sync.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_endpoints.dart';

void main() {
  late _RecordingAdapter adapter;
  late SessionStore store;
  late DeviceInfoSync sync;

  setUp(() async {
    adapter = _RecordingAdapter();
    store = SessionStore.memory();
    sync = DeviceInfoSync(
      apiClient: ApiClient(
        ApiConfig(
          apiBaseUrl: 'https://api.example.test',
          signatureSecret: 'secret',
          clientBridge: _FakeClientBridge(),
          sessionStore: store,
          timestampProvider: () => 1700000000000,
          randomDigitsProvider: (length) => '7' * length,
        ),
        dio: Dio()..httpClientAdapter = adapter,
      ),
      clientBridge: _FakeClientBridge(),
      store: store,
    );
  });

  test(
    'queries iOS device info by platform and stores response values',
    () async {
      await sync.sync();

      expect(
        adapter.lastRequest.path,
        'https://api.example.test${ApiEndpoints.getDeviceName}',
      );
      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.queryParameters['unwits'], isNull);
      expect(adapter.lastBody, {'unwits': 'iPhone10,3', 'stoups': '777777'});
      expect(await store.gyrofrequency(), 'iPhone X');
      expect(await store.entertainers(), '375x812');
    },
  );
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

class _FakeClientBridge extends ClientBridge {
  _FakeClientBridge() : super(platform: ClientPlatform.ios);

  @override
  bool get supportsNativeBridge => true;

  @override
  Future<ClientPlatformInfo> getPlatformInfo() async {
    return const ClientPlatformInfo(
      platform: 'iPhone10,3',
      systemVersion: '17.0',
      appVersion: '1.0.0',
      buildNumber: '1',
      deviceId: 'idfv',
    );
  }
}
