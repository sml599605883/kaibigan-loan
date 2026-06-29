import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';
import 'package:kaibigan_loan/src/core/device/device_info_store.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';

void main() {
  late _RecordingAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = _RecordingAdapter();
    client = ApiClient(
      ApiConfig(
        apiBaseUrl: 'https://api.example.test',
        signatureSecret: 'secret',
        clientBridge: _FakeClientBridge(),
        deviceInfoStore: DeviceInfoStore.memory(),
        timestampProvider: () => 1700000000000,
      ),
      dio: Dio()..httpClientAdapter = adapter,
    );
  });

  test('GET puts business params with signed common params in query', () async {
    await client.get('/plater/fas', params: const {'ghastful': 'a'});

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.queryParameters['ghastful'], 'a');
    expect(adapter.lastRequest.queryParameters['hereat'], '1.0.0');
    expect(adapter.lastRequest.queryParameters['feoffer'], isNotEmpty);
    expect(adapter.lastBody, isNull);
  });

  test(
    'POST keeps common params in query and business params in body',
    () async {
      await client.post('/plater/mainlined', data: const {'mummies': '4'});

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.queryParameters['hereat'], '1.0.0');
      expect(adapter.lastRequest.queryParameters['mummies'], isNull);
      expect(adapter.lastBody, {'mummies': '4'});
    },
  );

  test(
    'multipart upload keeps common params in query and file in form data',
    () async {
      final file = File('${Directory.systemTemp.path}/kaibigan-upload-test.txt')
        ..writeAsStringSync('id');
      addTearDown(() {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });

      await client.upload(
        '/plater/busywork',
        filePath: file.path,
        fileField: 'attach',
        data: const {'commensurate': '11'},
      );

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.queryParameters['hereat'], '1.0.0');
      expect(adapter.lastBody, isA<FormData>());
      final form = adapter.lastBody as FormData;
      expect(
        form.fields.any(
          (entry) => entry.key == 'commensurate' && entry.value == '11',
        ),
        isTrue,
      );
      expect(form.files.single.key, 'attach');
    },
  );

  test(
    'bootstrap parses base64 remote config when default probe fails',
    () async {
      adapter.queue
        ..add(ResponseBody.fromString('', 500))
        ..add(
          ResponseBody.fromString(
            base64Encode(
              utf8.encode(
                '{"api":"https://remote-api.test","web":"https://h5.test"}',
              ),
            ),
            200,
          ),
        );

      await client.bootstrapBaseUrls(
        defaultProbePath: '/health',
        remoteConfigUrl: 'https://config.example.test/api.json',
      );

      expect(client.config.apiBaseUrl, 'https://remote-api.test');
      expect(client.config.webBaseUrl, 'https://h5.test');
    },
  );

  test('proxy adapter routes requests through configured proxy', () async {
    final targetServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxiedRequests = <HttpRequest>[];

    addTearDown(() async {
      await targetServer.close(force: true);
      await proxyServer.close(force: true);
    });

    targetServer.listen((request) {
      request.response
        ..statusCode = 500
        ..write('target should not receive proxied requests')
        ..close();
    });
    proxyServer.listen((request) {
      proxiedRequests.add(request);
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'griding': 0, 'organizational': 'success', 'fas': {}}))
        ..close();
    });

    final proxyClient = ApiClient(
      ApiConfig(
        apiBaseUrl: 'http://127.0.0.1:${targetServer.port}',
        signatureSecret: 'secret',
        deviceInfoStore: DeviceInfoStore.memory(),
      ),
    )..setProxy(host: '127.0.0.1', port: proxyServer.port);

    await proxyClient.get('/plater/fas');

    expect(proxyClient.proxyHost, '127.0.0.1');
    expect(proxyClient.proxyPort, proxyServer.port);
    expect(proxiedRequests, hasLength(1));
    expect(proxiedRequests.single.uri.toString(), contains('/plater/fas'));
  });

  test('setProxy replaces an already-created direct client', () async {
    final targetServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var targetRequestCount = 0;
    var proxyRequestCount = 0;

    addTearDown(() async {
      await targetServer.close(force: true);
      await proxyServer.close(force: true);
    });

    targetServer.listen((request) {
      targetRequestCount++;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'griding': 0, 'organizational': 'success', 'fas': {}}))
        ..close();
    });
    proxyServer.listen((request) {
      proxyRequestCount++;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'griding': 0, 'organizational': 'success', 'fas': {}}))
        ..close();
    });

    final proxyClient = ApiClient(
      ApiConfig(
        apiBaseUrl: 'http://127.0.0.1:${targetServer.port}',
        signatureSecret: 'secret',
        deviceInfoStore: DeviceInfoStore.memory(),
      ),
    );

    await proxyClient.get('/plater/fas');
    proxyClient.setProxy(host: '127.0.0.1', port: proxyServer.port);
    await proxyClient.get('/plater/fas');

    expect(targetRequestCount, 1);
    expect(proxyRequestCount, 1);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions lastRequest = RequestOptions();
  Object? lastBody;
  final queue = <ResponseBody>[];

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
    if (queue.isNotEmpty) {
      return queue.removeAt(0);
    }
    return ResponseBody.fromString(
      jsonEncode({'griding': 0, 'organizational': 'success', 'fas': {}}),
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
