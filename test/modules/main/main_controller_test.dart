import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/main.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/core/client/client_bridge.dart';
import 'package:kaibigan_loan/src/core/device/device_info_store.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_endpoints.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ClientBridge.channelName);

  late _RecordingAdapter adapter;
  late ApiClient apiClient;

  setUp(() {
    Get.testMode = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return <String, Object?>{
            'platform': 'iPhone10,3',
            'systemVersion': '17.0',
            'appVersion': '1.0.0',
            'buildNumber': '1',
            'deviceId': 'idfv',
          };
        });
    adapter = _RecordingAdapter();
    apiClient = ApiClient(
      ApiConfig(
        apiBaseUrl: 'https://api.example.test',
        signatureSecret: 'secret',
        clientBridge: ClientBridge(platform: ClientPlatform.ios),
        deviceInfoStore: DeviceInfoStore.memory(),
        timestampProvider: () => 1700000000000,
      ),
      dio: Dio()..httpClientAdapter = adapter,
    );
    Get.put<ApiClient>(apiClient);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    Get.reset();
  });

  testWidgets('requests home page and dialog when home becomes visible', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(adapter.homeRequestCount, 1);
    expect(adapter.dialogRequestCount, 1);

    await tester.tap(find.image(const AssetImage(AppAssets.ordersNormal)));
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 1);
    expect(adapter.dialogRequestCount, 1);

    await tester.tap(find.image(const AssetImage(AppAssets.homeNormal)));
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);
  });

  testWidgets('requests home page and dialog after returning to visible home', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Find a suitable loan offer'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.detail);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.main);
    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);
  });

  testWidgets('requests home page and dialog on app resume only on home', (
    tester,
  ) async {
    await _pumpApp(tester);

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);

    await tester.tap(find.image(const AssetImage(AppAssets.ordersNormal)));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const KaibiganLoanApp());
  await tester.pumpAndSettle();
}

class _RecordingAdapter implements HttpClientAdapter {
  int homeRequestCount = 0;
  int dialogRequestCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == 'https://api.example.test${ApiEndpoints.homePage}') {
      homeRequestCount++;
    }
    if (options.path == 'https://api.example.test${ApiEndpoints.dialog}') {
      dialogRequestCount++;
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
