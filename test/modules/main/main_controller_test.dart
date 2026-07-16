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
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_endpoints.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/modules/main/home_popup.dart';
import 'package:kaibigan_loan/src/modules/main/main_controller.dart';
import 'package:kaibigan_loan/src/navigation_helper.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ClientBridge.channelName);

  late _RecordingAdapter adapter;
  late ApiClient apiClient;
  late SessionStore sessionStore;
  late _RecordingToastPresenter toastPresenter;

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
    toastPresenter = _RecordingToastPresenter();
    AppToast.presenter = toastPresenter;
    sessionStore = SessionStore.memory();
    apiClient = ApiClient(
      ApiConfig(
        apiBaseUrl: 'https://api.example.test',
        signatureSecret: 'secret',
        clientBridge: ClientBridge(platform: ClientPlatform.ios),
        sessionStore: sessionStore,
        timestampProvider: () => 1700000000000,
      ),
      dio: Dio()..httpClientAdapter = adapter,
    );
    Get.put<SessionStore>(sessionStore);
    Get.put<ApiClient>(apiClient);
    NavigationHelper.locationAccessChecker = () async => true;
    NavigationHelper.locationReporter = () async {};
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    AppToast.presenter = const EasyLoadingToastPresenter();
    NavigationHelper.locationAccessChecker =
        NavigationHelper.defaultLocationAccessChecker;
    NavigationHelper.locationReporter =
        NavigationHelper.defaultLocationReporter;
    Get.reset();
  });

  testWidgets('requests home page and dialog when home becomes visible', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(adapter.homeRequestCount, 1);
    expect(adapter.dialogRequestCount, 1);

    await sessionStore.setLoggedIn(true);

    await tester.tap(find.image(const AssetImage(AppAssets.ordersNormal)));
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 1);
    expect(adapter.dialogRequestCount, 1);

    await tester.tap(find.image(const AssetImage(AppAssets.homeNormal)));
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);
  });

  testWidgets('requests personal center dialog when Mine becomes visible', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    await _pumpApp(tester);

    await tester.tap(find.image(const AssetImage(AppAssets.profileNormal)));
    await tester.pumpAndSettle();

    expect(adapter.dialogScenes, [1, 2]);
  });

  testWidgets('requests personal center dialog when app resumes on Mine', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    await _pumpApp(tester);
    await tester.tap(find.image(const AssetImage(AppAssets.profileNormal)));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(adapter.dialogScenes, [1, 2, 2]);
  });

  testWidgets('redirects unauthenticated tab taps to login page', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.image(const AssetImage(AppAssets.ordersNormal)));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(find.text('Hi!  Welcome'), findsOneWidget);
    expect(Get.find<MainController>().selectedIndex.value, 0);
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

  testWidgets('shows documented marketing popup after home refresh', (
    tester,
  ) async {
    adapter.dialogPayload = {
      'commensurate': 3,
      'misaligned': {
        'mourningly': 'Promotion',
        'tanists': 'https://cdn.example.test/popup.png',
        'bloomeries': 'https://h5.example.test/promotion',
      },
    };

    await _pumpApp(tester);

    expect(adapter.dialogRequestCount, 1);
    expect(find.byKey(HomePopup.marketingImageKey), findsOneWidget);
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

  testWidgets('renders order status from process list module', (tester) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'BottomingSupergene',
          'anchovetta': [
            {
              'cabdrivers': 'order-1',
              'macromeres': 'Kaibigan Loan',
              'refiners': '₱ 20,000',
              'giardias': 'Loan Amount',
              'origin_end_time': '2026/05/06',
              'tallisim': 'Due Date',
              'cracksmen': 3,
              'fictitiousness': 'Past Due',
              'briefing': [
                {
                  'commensurate': 'repay',
                  'unrested': 1,
                  'stoles': 'Repay',
                  'dismasts': 'https://h5.example.test/order',
                },
              ],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.byKey(const ValueKey('home_order_status_section')), findsOne);
    expect(find.text('Order Status'), findsOne);
    expect(find.text('Kaibigan Loan'), findsOne);
    expect(find.text('₱ 20,000'), findsOne);
    expect(find.text('2026/05/06'), findsOne);
    expect(find.text('Past Due'), findsOne);
    expect(find.text('Repay'), findsOne);
  });

  testWidgets('renders failed process card with two visible actions', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'PROCESS_LIST',
          'anchovetta': [
            {
              'macromeres': 'Kaibigan Loan',
              'refiners': '₱ 20,000',
              'origin_end_time': '2026/05/06',
              'cracksmen': 5,
              'fictitiousness': 'Funding Failed',
              'briefing': [
                {
                  'commensurate': 'retry',
                  'unrested': 1,
                  'stoles': 'Retry Original Card',
                },
                {
                  'commensurate': 'change',
                  'unrested': 1,
                  'stoles': 'Change Account',
                },
                {'commensurate': 'repay', 'unrested': 0, 'stoles': 'Repay'},
              ],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('Funding Failed'), findsOne);
    expect(find.text('Retry Original Card'), findsOne);
    expect(find.text('Change Account'), findsOne);
    expect(find.text('Repay'), findsNothing);
  });

  testWidgets('renders review process card with details action', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'PROCESS_LIST',
          'anchovetta': [
            {
              'macromeres': 'Kaibigan Loan',
              'refiners': '₱ 20,000',
              'origin_end_time': '2026/05/06',
              'cracksmen': 1,
              'fictitiousness': 'Pending Approval',
              'briefing': [
                {'commensurate': 'detail', 'unrested': 1, 'stoles': 'Details'},
              ],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('Pending Approval'), findsOne);
    expect(find.text('Details'), findsOne);
    expect(find.text('Repay'), findsNothing);
  });

  testWidgets('formats raw process amount with thousands fallback', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'PROCESS_LIST',
          'anchovetta': [
            {
              'macromeres': 'Kaibigan Loan',
              'ecumenicalism': '2000',
              'origin_end_time': '2026/05/06',
              'cracksmen': 3,
              'fictitiousness': 'Past Due',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('₱ 2,000'), findsOne);
  });

  testWidgets('renders recommendation products from product list module', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'SubspecializedReawake',
          'anchovetta': [
            {
              'cabdrivers': 'product-1',
              'omissible': 'Kaibigan Loan',
              'ghillies': '₱ 20,000',
              'mainlined': '180 Days',
              'cultrate': 'Loan terms',
              'whops': '≤ 0.5% / Day',
              'rescinders': 'Interest Rate',
              'logophiles': 'yellow',
            },
            {
              'cabdrivers': 'product-2',
              'omissible': 'Partner Loan',
              'ghillies': '₱ 30,000',
              'mainlined': '120 Days',
              'cultrate': 'Loan terms',
              'whops': '≤ 0.4% / Day',
              'rescinders': 'Interest Rate',
              'logophiles': 'red',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.byKey(const ValueKey('home_recommendation_section')), findsOne);
    expect(find.text('Recommendation'), findsOne);
    expect(find.text('Kaibigan Loan'), findsOne);
    expect(find.text('Partner Loan'), findsOne);
    expect(find.text('₱ 20,000'), findsOne);
    expect(find.text('₱ 30,000'), findsOne);
    expect(find.text('180 Days'), findsOne);
    expect(find.text('≤ 0.4% / Day'), findsOne);
    expect(find.text('Loan terms'), findsNWidgets(2));
    expect(find.text('Interest Rate'), findsNWidgets(2));
  });

  testWidgets('applies recommendation product on card tap', (tester) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'PRODUCT_LIST',
          'anchovetta': [
            {
              'cabdrivers': 'product-1',
              'omissible': 'Kaibigan Loan',
              'ghillies': '₱ 20,000',
              'mainlined': '180 Days',
              'whops': '≤ 0.5% / Day',
              'logophiles': 'yellow',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    await tester.tap(
      find.byKey(const ValueKey('home_recommendation_product-1')),
    );
    await tester.pumpAndSettle();

    expect(adapter.productApplyRequestCount, 1);
    expect(adapter.productDetailRequestCount, 1);
    expect(adapter.lastProductApplyId, 'product-1');
    expect(Get.currentRoute, AppRoutes.detail);
    expect(Get.arguments, {
      'geobotanists': 'product-1',
      'scolloped': 'Kaibigan Loan',
    });
  });

  testWidgets('disables recommendation product when button color is grey', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'PRODUCT_LIST',
          'anchovetta': [
            {
              'cabdrivers': 'product-1',
              'omissible': 'Kaibigan Loan',
              'ghillies': '₱ 50,000',
              'mainlined': '121 day',
              'cultrate': 'Loan terms',
              'whops': '≤ 0.05%/day',
              'rescinders': 'Interest Rate',
              'restless': 'Daily Quota Full',
              'logophiles': 'grey',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('≤ 0.05%/day'), findsOneWidget);
    expect(find.text('Loan terms'), findsOneWidget);
    expect(find.text('Daily Quota Full'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('home_recommendation_product-1')),
    );
    await tester.pumpAndSettle();

    expect(adapter.productApplyRequestCount, 0);
    expect(adapter.productDetailRequestCount, 0);
    expect(Get.currentRoute, AppRoutes.main);
  });

  testWidgets('applies top hero product on loan card tap', (tester) async {
    await sessionStore.setLoggedIn(true);
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'humpiness': <Map<String, dynamic>>[],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pumpAndSettle();

    expect(adapter.productApplyRequestCount, 1);
    expect(adapter.productDetailRequestCount, 1);
    expect(adapter.lastProductApplyId, 'hero-product');
    expect(Get.currentRoute, AppRoutes.detail);
    expect(Get.arguments, {
      'geobotanists': 'hero-product',
      'scolloped': 'Kaibigan Loan',
    });
  });

  testWidgets('redirects unauthenticated top hero tap to login', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'humpiness': <Map<String, dynamic>>[],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pumpAndSettle();

    expect(adapter.productApplyRequestCount, 0);
    expect(adapter.productDetailRequestCount, 0);
    expect(Get.currentRoute, AppRoutes.login);
  });

  testWidgets('top loan card prefers large card over small card', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'ShivasSurveyings',
          'anchovetta': [
            {
              'cabdrivers': 'small-product',
              'ghillies': '₱ 10,000',
              'mainlined': '90 Days',
              'pulpit': '≤ 0.9% / Day',
              'restless': 'Small Apply',
            },
          ],
        },
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'large-product',
              'ghillies': '₱ 80,000',
              'mainlined': '210 Days',
              'pulpit': '≤ 0.2% / Day',
              'restless': 'Large Apply',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('₱ 80,000'), findsOneWidget);
    expect(find.text('210 Days'), findsOneWidget);
    expect(find.text('≤ 0.2% / Day'), findsOneWidget);
    expect(find.text('Large Apply'), findsOneWidget);
    expect(find.text('₱ 10,000'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pumpAndSettle();

    expect(adapter.lastProductApplyId, 'large-product');
  });

  testWidgets(
    'top loan card falls back to small card when large card is absent',
    (tester) async {
      await sessionStore.setLoggedIn(true);
      adapter.homePayload = {
        'religiosities': [
          {
            'commensurate': 'ShivasSurveyings',
            'anchovetta': [
              {
                'cabdrivers': 'small-product',
                'ghillies': '₱ 12,000',
                'mainlined': '100 Days',
                'pulpit': '≤ 0.8% / Day',
                'restless': 'Small Apply',
              },
            ],
          },
        ],
      };

      await _pumpApp(tester);

      expect(find.text('₱ 12,000'), findsOneWidget);
      expect(find.text('100 Days'), findsOneWidget);
      expect(find.text('≤ 0.8% / Day'), findsOneWidget);
      expect(find.text('Small Apply'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home_loan_card')));
      await tester.pumpAndSettle();

      expect(adapter.lastProductApplyId, 'small-product');
    },
  );

  testWidgets('ignores top hero tap when large card product id is empty', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pumpAndSettle();

    expect(adapter.productApplyRequestCount, 0);
    expect(adapter.productDetailRequestCount, 0);
    expect(Get.currentRoute, AppRoutes.main);
  });

  testWidgets('requests home page and dialog after returning to visible home', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'humpiness': <Map<String, dynamic>>[],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
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

    await sessionStore.setLoggedIn(true);
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
  int productApplyRequestCount = 0;
  int productDetailRequestCount = 0;
  String? lastBannerId;
  String? lastProductApplyId;
  Map<String, dynamic> homePayload = <String, dynamic>{};
  Map<String, dynamic> dialogPayload = <String, dynamic>{};
  final dialogScenes = <int>[];

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
      dialogScenes.add(options.queryParameters['loungy'] as int);
      return ResponseBody.fromString(
        jsonEncode({
          'griding': 0,
          'organizational': 'success',
          'fas': dialogPayload,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path ==
        'https://api.example.test${ApiEndpoints.bannerClickRecord}') {
      bannerClickRecordCount++;
      lastBannerId = options.data is Map
          ? options.data['mesial'] as String?
          : null;
    }
    if (options.path ==
        'https://api.example.test${ApiEndpoints.productApply}') {
      productApplyRequestCount++;
      lastProductApplyId = options.data is Map
          ? options.data['geobotanists'] as String?
          : null;
      return ResponseBody.fromString(
        jsonEncode({
          'griding': 0,
          'organizational': 'success',
          'fas': <String, dynamic>{'threats': 200},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path ==
        'https://api.example.test${ApiEndpoints.productDetail}') {
      productDetailRequestCount++;
      return ResponseBody.fromString(
        jsonEncode({
          'griding': 0,
          'organizational': 'success',
          'fas': {
            'geobotanists': options.data is Map
                ? options.data['geobotanists']
                : '',
            'scolloped': 'Kaibigan Loan',
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
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

class _RecordingToastPresenter implements ToastPresenter {
  @override
  Future<void> show(String message, {required bool isError}) async {}

  @override
  Future<void> showLoading(String? message) async {}

  @override
  Future<void> dismissLoading() async {}
}
