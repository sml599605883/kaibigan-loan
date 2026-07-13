import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
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
        sessionStore: SessionStore.memory(),
        timestampProvider: () => 1700000000000,
        randomDigitsProvider: (length) => '7' * length,
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

  test('homePage supplies obfuscated placeholders internally', () async {
    await client.homePage();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, 'https://api.example.test/plater/fas');
    expect(adapter.lastRequest.queryParameters['ghastful'], '777777');
    expect(adapter.lastRequest.queryParameters['lairs'], '777777');
  });

  test('getDeviceName requires only device identifier from caller', () async {
    await client.getDeviceName(unwits: 'iPhone11,8');

    expect(adapter.lastRequest.method, 'POST');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/threadier',
    );
    expect(adapter.lastRequest.queryParameters['unwits'], isNull);
    expect(adapter.lastBody, {'unwits': 'iPhone11,8', 'stoups': '777777'});
  });

  test('account methods add obfuscated fields internally', () async {
    await client.sendSmsCode(potline: '09171234567', waterbird: 'sms');
    expect(adapter.lastRequest.path, 'https://api.example.test/plater/potline');
    expect(adapter.lastBody, {
      'potline': '09171234567',
      'waterbird': 'sms',
      'footbaths': '777777',
    });

    await client.supportDeliveryChannels(potline: '09171234567');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/footbaths',
    );
    expect(adapter.lastBody, {
      'potline': '09171234567',
      'barned': '777777',
      'royalmast': '777777',
    });

    await client.smsCodeLogin(threadier: '09171234567', informal: '123456');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/waterbird',
    );
    expect(adapter.lastBody, {
      'threadier': '09171234567',
      'informal': '123456',
      'barned': '777777',
      'royalmast': '777777',
    });
  });

  test('app and product methods expose only business params', () async {
    await client.personalCenter();
    expect(adapter.lastRequest.path, 'https://api.example.test/plater/barned');
    expect(adapter.lastRequest.queryParameters['deniable'], '777777');

    await client.dialog(loungy: 1);
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/pereiopods',
    );
    expect(adapter.lastRequest.queryParameters['loungy'], 1);

    await client.productApply(geobotanists: '1001', succumbs: '2');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/informal',
    );
    expect(adapter.lastBody, {
      'enates': '1001',
      'nonfeasance': '1000',
      'chad': '1000',
      'geobotanists': '1001',
      'succumbs': '2',
      'fib': '777777',
      'dyable': '777777',
    });
  });

  test('certification methods add obfuscated fields internally', () async {
    await client.basicPersonInfo(geobotanists: '1001');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/causations',
    );
    expect(adapter.lastRequest.queryParameters['geobotanists'], '1001');
    expect(adapter.lastRequest.queryParameters['cosponsored'], '777777');

    await client.saveBasicInfo(
      asthmas: '23-11-1993',
      overmanaged: '623099344112',
      unwits: 'NAVEEN TOM VARGHESE',
      commensurate: '11',
      heirship: '1',
    );
    expect(adapter.lastRequest.path, 'https://api.example.test/plater/violent');
    expect(adapter.lastBody, {
      'asthmas': '23-11-1993',
      'overmanaged': '623099344112',
      'unwits': 'NAVEEN TOM VARGHESE',
      'commensurate': '11',
      'heirship': '1',
      'terrific': '777777',
    });

    await client.savePersonalInfo(data: {'geobotanists': '1001'});
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/stigmasterol',
    );
    expect(adapter.lastBody, {
      'geobotanists': '1001',
      'enemies': '777777',
      'cryophytes': '777777',
    });

    await client.personalInfo(geobotanists: '1001');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/shortchange',
    );
    expect(adapter.lastBody, {'geobotanists': '1001', 'utopians': '777777'});

    await client.jobInfo(geobotanists: '1001');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/preattuned',
    );
    expect(adapter.lastRequest.queryParameters['geobotanists'], '1001');
    expect(adapter.lastRequest.queryParameters['utopians'], '777777');

    await client.saveJobInfo(data: {'geobotanists': '1001', 'freshly': 'SPSS'});
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/religiosities',
    );
    expect(adapter.lastBody, {
      'geobotanists': '1001',
      'freshly': 'SPSS',
      'komondors': '777777',
      'noncertified': '777777',
      'tradescantias': '777777',
    });
  });

  test('addressInit uses the documented GET endpoint', () async {
    await client.addressInit();

    expect(adapter.lastRequest.method, 'GET');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/centerlines',
    );
  });

  test('order methods expose only business params', () async {
    await client.orderRedirect(
      dodgy: 'ORDER001',
      ecumenicalism: '3000',
      desertifying: '7',
      tythes: '1',
    );
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/geometrically',
    );
    expect(adapter.lastBody, {
      'dodgy': 'ORDER001',
      'ecumenicalism': '3000',
      'desertifying': '7',
      'tythes': '1',
      'woods': '777777',
      'anlagen': '777777',
      'anga': '777777',
      'expectorating': '777777',
    });

    await client.orderList(mummies: '4', dissipaters: '1', bewaring: '50');
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/mainlined',
    );
    expect(adapter.lastBody, {
      'mummies': '4',
      'dissipaters': '1',
      'bewaring': '50',
    });

    await client.originalCardRetry(chattinesses: 'ORDER001');
    expect(adapter.lastRequest.path, 'https://api.example.test/plater/dodgy');
    expect(adapter.lastBody, {'chattinesses': 'ORDER001'});
  });

  test('data report methods add obfuscated fields internally', () async {
    await client.uploadLocation(
      phrasemongers: 'PH',
      callee: 'Philippines',
      clientless: 'Street',
      overtone: '14.5995',
      rhodopsins: '120.9842',
      lushest: 'Manila',
      verticil: 'NCR',
    );
    expect(
      adapter.lastRequest.path,
      'https://api.example.test/plater/outmarching',
    );
    expect(adapter.lastBody, {
      'verticil': 'NCR',
      'phrasemongers': 'PH',
      'callee': 'Philippines',
      'clientless': 'Street',
      'overtone': '14.5995',
      'rhodopsins': '120.9842',
      'lushest': 'Manila',
      'embordered': '777777',
      'satellites': '777777',
    });

    await client.googleMarket(simplistically: 'idfv', preadjusts: 'idfa');
    expect(adapter.lastRequest.path, 'https://api.example.test/plater/pulpit');
    expect(adapter.lastBody, {
      'simplistically': 'idfv',
      'preadjusts': 'idfa',
      'chickpea': '777777',
    });

    await client.uploadContacts(fas: 'encrypted');
    expect(adapter.lastRequest.path, 'https://api.example.test/plater/hatlike');
    expect(adapter.lastBody, {
      'commensurate': '3',
      'fas': 'encrypted',
      'crampit': '777777',
      'otoplasties': '777777',
    });
  });

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
        ..write(
          jsonEncode({'griding': 0, 'organizational': 'success', 'fas': {}}),
        )
        ..close();
    });

    final proxyClient = ApiClient(
      ApiConfig(
        apiBaseUrl: 'http://127.0.0.1:${targetServer.port}',
        signatureSecret: 'secret',
        sessionStore: SessionStore.memory(),
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
        ..write(
          jsonEncode({'griding': 0, 'organizational': 'success', 'fas': {}}),
        )
        ..close();
    });
    proxyServer.listen((request) {
      proxyRequestCount++;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({'griding': 0, 'organizational': 'success', 'fas': {}}),
        )
        ..close();
    });

    final proxyClient = ApiClient(
      ApiConfig(
        apiBaseUrl: 'http://127.0.0.1:${targetServer.port}',
        signatureSecret: 'secret',
        sessionStore: SessionStore.memory(),
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
