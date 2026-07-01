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

  testWidgets('pull to refresh requests home page and dialog', (tester) async {
    await _pumpApp(tester);

    expect(adapter.homeRequestCount, 1);
    expect(adapter.dialogRequestCount, 1);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 360));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);
  });

  testWidgets('renders delivered banner and records banner tap', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'Moorages',
          'anchovetta': [
            {
              'cabdrivers': 'banner-1',
              'bloomeries': 'https://h5.example.test/banner',
              'centerlines': 'https://cdn.example.test/banner-a.png',
            },
            {
              'cabdrivers': 'banner-2',
              'bloomeries': 'https://h5.example.test/banner-b',
              'centerlines': 'https://cdn.example.test/banner-b.png',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.byKey(const ValueKey('home_promo_banner_0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_promo_banner_0')));
    await tester.pumpAndSettle();

    expect(adapter.bannerClickRecordCount, 1);
    expect(adapter.lastBannerId, 'banner-1');
  });

  testWidgets('sizes delivered banner from available width ratio', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'Moorages',
          'anchovetta': [
            {
              'cabdrivers': 'banner-1',
              'bloomeries': 'https://h5.example.test/banner',
              'centerlines': 'https://cdn.example.test/banner-a.png',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    final bannerSize = tester.getSize(
      find.byKey(const ValueKey('home_promo_banner_0')),
    );

    expect(bannerSize.width, 335);
    expect(bannerSize.height, closeTo(96, 0.01));
  });

  testWidgets('ignores original banner element type before obfuscation', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'BANNER',
          'anchovetta': [
            {
              'cabdrivers': 'banner-1',
              'bloomeries': 'https://h5.example.test/banner',
              'centerlines': 'https://cdn.example.test/banner-a.png',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.byKey(const ValueKey('home_promo_banner_0')), findsNothing);
  });

  testWidgets(
    'renders loan process list when large card humpiness is not empty',
    (tester) async {
      adapter.homePayload = {
        'religiosities': [
          {
            'commensurate': 'CatechisticOverlooking',
            'anchovetta': [
              {
                'humpiness': [
                  {
                    'primogenitor': 'Limit granted',
                    'pyknoses': '₱ 30,000',
                    'vixenish': 1,
                  },
                  {
                    'primogenitor': 'Verify to unlock',
                    'pyknoses': '₱ 40,000',
                    'vixenish': 0,
                  },
                ],
              },
            ],
          },
        ],
      };

      await _pumpApp(tester);

      expect(
        find.byKey(const ValueKey('home_loan_process_list')),
        findsOneWidget,
      );
      expect(
        find.image(const AssetImage(AppAssets.homeProcessPanel)),
        findsNothing,
      );
      expect(find.text('Limit granted'), findsOneWidget);
      expect(find.text('₱ 30,000'), findsOneWidget);
      expect(find.text('Verify to unlock'), findsOneWidget);
      expect(find.text('₱ 40,000'), findsOneWidget);
    },
  );

  testWidgets('renders loan process image when large card humpiness is empty', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {'humpiness': <Map<String, dynamic>>[]},
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.byKey(const ValueKey('home_loan_process_list')), findsNothing);
    expect(
      find.image(const AssetImage(AppAssets.homeProcessPanel)),
      findsOneWidget,
    );
  });

  testWidgets('requests home page and dialog after returning to visible home', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Apply Now'));
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

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);

    await tester.tap(find.image(const AssetImage(AppAssets.ordersNormal)));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
  int bannerClickRecordCount = 0;
  String? lastBannerId;
  Map<String, dynamic> homePayload = <String, dynamic>{};

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
    if (options.path ==
        'https://api.example.test${ApiEndpoints.bannerClickRecord}') {
      bannerClickRecordCount++;
      lastBannerId = options.data is Map
          ? options.data['mesial'] as String?
          : null;
    }
    return ResponseBody.fromString(
      jsonEncode({
        'griding': 0,
        'organizational': 'success',
        'fas': homePayload,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
