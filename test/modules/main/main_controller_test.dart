import 'dart:async';
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
import 'package:kaibigan_loan/src/modules/main/home_page.dart';
import 'package:kaibigan_loan/src/modules/main/main_controller.dart';
import 'package:kaibigan_loan/src/modules/widgets/retention_popup.dart';
import 'package:kaibigan_loan/src/navigation_helper.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';
import 'package:permission_handler/permission_handler.dart';

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

  testWidgets('shows and dismisses custom loading during home refresh', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(toastPresenter.showLoadingCount, 1);
    expect(toastPresenter.dismissLoadingCount, 1);
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

  testWidgets('refreshes the phone number whenever Mine becomes visible', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    await sessionStore.savePhone('09175551234');
    await _pumpApp(tester);

    await tester.tap(find.image(const AssetImage(AppAssets.profileNormal)));
    await tester.pumpAndSettle();
    expect(find.text('091***1234'), findsOneWidget);

    await tester.tap(find.image(const AssetImage(AppAssets.homeNormal)));
    await tester.pumpAndSettle();
    await sessionStore.savePhone('09998887654');

    await tester.tap(find.image(const AssetImage(AppAssets.profileNormal)));
    await tester.pumpAndSettle();

    expect(find.text('099***7654'), findsOneWidget);
    expect(find.text('091***1234'), findsNothing);
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

  testWidgets('hides gaps after empty dynamic home sections', (tester) async {
    await _pumpApp(tester);

    expect(find.byKey(const ValueKey('home_promo_bottom_gap')), findsNothing);
    expect(
      find.byKey(const ValueKey('home_order_status_bottom_gap')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('home_recommendation_bottom_gap')),
      findsNothing,
    );
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
    expect(find.byKey(const ValueKey('home_promo_bottom_gap')), findsNothing);
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
              'bloomeries': 'https://h5.example.test/order-card',
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
    expect(
      find.byKey(const ValueKey('home_order_status_bottom_gap')),
      findsOneWidget,
    );
    expect(find.text('Order Status'), findsOne);
    expect(find.text('Kaibigan Loan'), findsOne);
    expect(find.text('₱ 20,000'), findsOne);
    expect(find.text('2026/05/06'), findsOne);
    expect(find.text('Past Due'), findsOne);
    expect(find.text('Repay'), findsOne);
    expect(
      Get.find<MainController>().orderStatusItems.single.linkUrl,
      'https://h5.example.test/order-card',
    );
    expect(
      Get.find<MainController>().orderStatusItems.single.actions.single.url,
      'https://h5.example.test/order',
    );
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
    expect(
      find.byKey(const ValueKey('home_recommendation_bottom_gap')),
      findsOneWidget,
    );
    expect(find.text('Loan Process'), findsNothing);
    expect(
      find.image(const AssetImage(AppAssets.homeProcessPanel)),
      findsNothing,
    );
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
    await sessionStore.setLoggedIn(true);
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

  testWidgets('redirects unauthenticated recommendation tap to login', (
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

    expect(adapter.productApplyRequestCount, 0);
    expect(adapter.productDetailRequestCount, 0);
    expect(Get.currentRoute, AppRoutes.login);
  });

  testWidgets('applies grey recommendation product on card tap', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
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

    expect(adapter.productApplyRequestCount, 1);
    expect(adapter.productDetailRequestCount, 1);
    expect(adapter.lastProductApplyId, 'product-1');
    expect(Get.currentRoute, AppRoutes.detail);
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

  testWidgets('top hero can be tapped again after locking during permission', (
    tester,
  ) async {
    final oldPermissionRequest = Completer<PermissionStatus>();
    final newPermissionRequest = Completer<PermissionStatus>();
    addTearDown(() {
      if (!oldPermissionRequest.isCompleted) {
        oldPermissionRequest.complete(PermissionStatus.denied);
      }
      if (!newPermissionRequest.isCompleted) {
        newPermissionRequest.complete(PermissionStatus.denied);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      NavigationHelper.nativeLocationLoader =
          NavigationHelper.defaultNativeLocationLoader;
      NavigationHelper.locationServiceStatusProvider =
          NavigationHelper.defaultLocationServiceStatusProvider;
      NavigationHelper.locationPermissionStatusProvider =
          NavigationHelper.defaultLocationPermissionStatusProvider;
      NavigationHelper.locationPermissionRequester =
          NavigationHelper.defaultLocationPermissionRequester;
    });
    var permissionRequestCount = 0;
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
    NavigationHelper.locationAccessChecker =
        NavigationHelper.defaultLocationAccessChecker;
    NavigationHelper.nativeLocationLoader = () async => null;
    NavigationHelper.locationServiceStatusProvider = () async =>
        ServiceStatus.enabled;
    NavigationHelper.locationPermissionStatusProvider = () async =>
        PermissionStatus.denied;
    NavigationHelper.locationPermissionRequester = () {
      permissionRequestCount += 1;
      return permissionRequestCount == 1
          ? oldPermissionRequest.future
          : newPermissionRequest.future;
    };

    await _pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pump();

    expect(permissionRequestCount, 2);
    expect(adapter.productApplyRequestCount, 0);

    newPermissionRequest.complete(PermissionStatus.granted);
    await tester.pumpAndSettle();

    expect(adapter.productApplyRequestCount, 1);

    oldPermissionRequest.complete(PermissionStatus.granted);
    await tester.pump();
    expect(adapter.productApplyRequestCount, 1);
  });

  testWidgets('returning home releases the pending top hero tap lock', (
    tester,
  ) async {
    final firstLocationCheck = Completer<bool>();
    final secondLocationCheck = Completer<bool>();
    addTearDown(() {
      if (!firstLocationCheck.isCompleted) {
        firstLocationCheck.complete(false);
      }
      if (!secondLocationCheck.isCompleted) {
        secondLocationCheck.complete(false);
      }
    });
    var locationCheckCount = 0;
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
    NavigationHelper.locationAccessChecker = () {
      locationCheckCount += 1;
      return locationCheckCount == 1
          ? firstLocationCheck.future
          : secondLocationCheck.future;
    };

    await _pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pump();

    Get.find<MainController>().returnToHomeTab();
    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pump();

    expect(locationCheckCount, 2);
    expect(adapter.productApplyRequestCount, 0);

    firstLocationCheck.complete(false);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home_loan_card')));
    await tester.pump();

    expect(locationCheckCount, 2);
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

  testWidgets('top loan card shows delivered product name and logo', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'omissible': 'Kaibigan Loan',
              'biontic': 'https://cdn.example.test/product-logo.png',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('Kaibigan Loan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home_loan_product_logo')),
      findsOneWidget,
    );
  });

  testWidgets('top loan card hides empty product logo but keeps name', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'omissible': 'Kaibigan Loan',
              'biontic': '',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('Kaibigan Loan'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_loan_product_logo')), findsNothing);
  });

  testWidgets('top loan card shows delivered description labels', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'geometrically': 'Maximum available amount',
              'outmarching': 'Repayment period',
              'rescinders': 'Daily interest rate',
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('Maximum available amount'), findsOneWidget);
    expect(find.text('Repayment period'), findsOneWidget);
    expect(find.text('Daily interest rate'), findsOneWidget);
  });

  testWidgets('top loan card leaves missing description labels empty', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {'cabdrivers': 'hero-product'},
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('Available up to'), findsNothing);
    expect(find.text('Loan Term'), findsNothing);
    expect(find.text('Low Interest'), findsNothing);
  });

  testWidgets('top loan card keeps loan facts when hotdogs is empty', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'mainlined': '180 Days',
              'outmarching': 'Loan Term',
              'pulpit': '0.05% / Day',
              'rescinders': 'Interest Rate',
              'hotdogs': <Map<String, dynamic>>[],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('180 Days'), findsOneWidget);
    expect(find.text('Loan Term'), findsOneWidget);
    expect(find.text('0.05% / Day'), findsOneWidget);
    expect(find.text('Interest Rate'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byIcon(Icons.percent_rounded), findsOneWidget);
  });

  testWidgets('top loan card shows one delivered hotdogs option', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'hotdogs': [
                {'mononucleotides': '3', 'strumming': 'Terms'},
              ],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_rounded), findsNothing);
    expect(find.byIcon(Icons.percent_rounded), findsNothing);

    final options = find.byKey(const ValueKey('home_loan_term_options'));
    final option = find.byKey(const ValueKey('home_loan_term_option_0'));
    expect(tester.getSize(option).width, closeTo(136, 0.01));
    expect(
      tester.getCenter(option).dx,
      closeTo(tester.getCenter(options).dx, 0.01),
    );
  });

  testWidgets('top loan card shows two delivered hotdogs options', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'hotdogs': [
                {'mononucleotides': '3', 'strumming': 'Terms'},
                {'mononucleotides': '4', 'strumming': 'Periods'},
              ],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Periods'), findsOneWidget);
  });

  testWidgets('top loan card shows first and last hotdogs options', (
    tester,
  ) async {
    adapter.homePayload = {
      'religiosities': [
        {
          'commensurate': 'CatechisticOverlooking',
          'anchovetta': [
            {
              'cabdrivers': 'hero-product',
              'hotdogs': [
                {'mononucleotides': '3', 'strumming': 'First'},
                {'mononucleotides': '5', 'strumming': 'Middle'},
                {'mononucleotides': '7', 'strumming': 'Last'},
              ],
            },
          ],
        },
      ],
    };

    await _pumpApp(tester);

    expect(find.text('3'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('5'), findsNothing);
    expect(find.text('Middle'), findsNothing);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Last'), findsOneWidget);
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

  testWidgets('dialog route changes do not refresh home data', (tester) async {
    await _pumpApp(tester);

    final dialog = Get.dialog<void>(
      const AlertDialog(content: Text('Permission prompt')),
      transitionDuration: Duration.zero,
    );
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 1);

    Get.back<void>();
    await tester.pumpAndSettle();
    await dialog;

    expect(adapter.homeRequestCount, 1);
  });

  testWidgets('certification exits refresh home and keep pull refresh active', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    await _pumpApp(tester);

    NavigationHelper.toCertificationIdentity<void>(productId: 'product-1');
    await tester.pumpAndSettle();
    Get.back<void>();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.main);
    expect(adapter.homeRequestCount, 2);

    NavigationHelper.toCertificationIdentity<void>(productId: 'product-1');
    await tester.pumpAndSettle();
    final popup = Get.dialog<void>(
      RetentionPopupContent(
        imageUrl: 'https://example.test/retention.png',
        exitText: 'Exit',
        continueText: 'Continue',
        onExit: () => Get.back<void>(),
      ),
      transitionDuration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RetentionPopup.exitButtonKey));
    await tester.pumpAndSettle();
    await popup;

    expect(Get.currentRoute, AppRoutes.main);
    expect(adapter.homeRequestCount, 3);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 360));
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 4);
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

  testWidgets('refreshes home only once for inactive resumes per app launch', (
    tester,
  ) async {
    await _pumpApp(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(adapter.homeRequestCount, 2);
    expect(adapter.dialogRequestCount, 2);
  });

  testWidgets('refreshes orders when the visible orders tab resumes', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    await _pumpApp(tester);

    await tester.tap(find.image(const AssetImage(AppAssets.ordersNormal)));
    await tester.pumpAndSettle();

    expect(adapter.orderListRequestCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(adapter.orderListRequestCount, 2);
  });

  testWidgets('refreshes orders after returning to the visible orders tab', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    await _pumpApp(tester);

    await tester.tap(find.image(const AssetImage(AppAssets.ordersNormal)));
    await tester.pumpAndSettle();

    expect(adapter.orderListRequestCount, 1);

    Get.to<void>(() => const SizedBox());
    await tester.pumpAndSettle();
    Get.back<void>();
    await tester.pumpAndSettle();

    expect(adapter.orderListRequestCount, 2);
  });

  testWidgets('records banner tap and opens its delivered link', (
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

    await _pumpBannerApp(tester);

    expect(find.byKey(const ValueKey('home_promo_banner_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_promo_bottom_gap')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_promo_banner_0')));
    await tester.pumpAndSettle();

    expect(adapter.bannerClickRecordCount, 1);
    expect(adapter.lastBannerId, 'banner-1');
    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://h5.example.test/banner',
      'title': null,
    });
  });

  testWidgets('order status card opens bloomeries without admission', (
    tester,
  ) async {
    await _pumpBannerApp(tester);

    await Get.find<MainController>().handleOrderStatusTap(
      _orderStatusItem(
        linkUrl: 'https://h5.example.test/order-card',
        productId: 'product-link',
      ),
    );
    await tester.pumpAndSettle();

    expect(adapter.productApplyRequestCount, 0);
    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://h5.example.test/order-card',
      'title': null,
    });
  });

  testWidgets('order status card uses geobotanists when bloomeries is empty', (
    tester,
  ) async {
    await sessionStore.setLoggedIn(true);
    await _pumpApp(tester);

    final admission = Get.find<MainController>().handleOrderStatusTap(
      _orderStatusItem(linkUrl: '', productId: 'product-admission'),
    );
    await tester.pumpAndSettle();
    await admission;

    expect(adapter.productApplyRequestCount, 1);
    expect(adapter.lastProductApplyId, 'product-admission');
  });

  testWidgets('order status retry action retries the original card', (
    tester,
  ) async {
    adapter.originalCardRetryPayload = {
      'preinserting': 'https://h5.example.test/retry-result',
    };
    await _pumpBannerApp(tester);

    final action = Get.find<MainController>().handleOrderStatusButtonTap(
      _orderStatusItem(linkUrl: '', productId: 'product-retry'),
      const HomeOrderStatusAction(
        type: 'retry',
        text: 'Retry Original Card',
        url: '',
        visible: true,
      ),
    );
    await tester.pumpAndSettle();
    await action;

    expect(adapter.originalCardRetryOrderNos, ['order-no']);
    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://h5.example.test/retry-result',
      'title': null,
    });
  });

  testWidgets('order status retry dismisses loading when result url is empty', (
    tester,
  ) async {
    adapter.originalCardRetryPayload = <String, dynamic>{};
    await _pumpBannerApp(tester);
    final loadingCount = toastPresenter.showLoadingCount;
    final dismissCount = toastPresenter.dismissLoadingCount;

    final action = Get.find<MainController>().handleOrderStatusButtonTap(
      _orderStatusItem(linkUrl: '', productId: 'product-retry'),
      const HomeOrderStatusAction(
        type: 'retry',
        text: 'Retry Original Card',
        url: '',
        visible: true,
      ),
    );
    await tester.pumpAndSettle();
    await action;

    expect(toastPresenter.showLoadingCount, loadingCount + 1);
    expect(toastPresenter.dismissLoadingCount, dismissCount + 1);
    expect(toastPresenter.errorMessages, ['Missing retry result url']);
    expect(Get.currentRoute, AppRoutes.main);
  });

  testWidgets('order status change action opens account list when available', (
    tester,
  ) async {
    adapter.userAccountListPayload = {
      'religiosities': [
        {'smokehouse': 'bind-1'},
      ],
    };
    await _pumpBannerApp(tester);

    final action = Get.find<MainController>().handleOrderStatusButtonTap(
      _orderStatusItem(linkUrl: '', productId: 'product-change'),
      const HomeOrderStatusAction(
        type: 'change',
        text: 'Change Account',
        url: '',
        visible: true,
      ),
    );
    await tester.pumpAndSettle();
    await action;

    expect(adapter.userAccountListProductIds, ['product-change']);
    expect(Get.currentRoute, AppRoutes.accountList);
    expect(Get.arguments, {
      'geobotanists': 'product-change',
      'dodgy': 'order-no',
    });
  });

  testWidgets('order status change action opens bind card when list is empty', (
    tester,
  ) async {
    adapter.userAccountListPayload = {'religiosities': <dynamic>[]};
    await _pumpBannerApp(tester);

    final action = Get.find<MainController>().handleOrderStatusButtonTap(
      _orderStatusItem(linkUrl: '', productId: 'product-bind'),
      const HomeOrderStatusAction(
        type: 'change',
        text: 'Change Account',
        url: '',
        visible: true,
      ),
    );
    await tester.pumpAndSettle();
    await action;

    expect(adapter.userAccountListProductIds, ['product-bind']);
    expect(Get.currentRoute, AppRoutes.certificationBindCard);
    expect(Get.arguments, {
      'geobotanists': 'product-bind',
      'dodgy': 'order-no',
      'isAccountChange': true,
    });
  });
}

HomeOrderStatusItem _orderStatusItem({
  required String linkUrl,
  required String productId,
}) {
  return HomeOrderStatusItem(
    id: 'order-card',
    productName: 'Kaibigan Loan',
    productLogo: '',
    amount: '1,000.00',
    amountText: 'Loan Amount',
    dueDate: '2026/08/08',
    dateText: 'Due Date',
    statusText: 'Pending',
    buttonText: '',
    linkUrl: linkUrl,
    productId: productId,
    orderNo: 'order-no',
    cardStatus: 1,
    actions: const [],
  );
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const KaibiganLoanApp());
  await tester.pumpAndSettle();
}

Future<void> _pumpBannerApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });

  Get.put<MainController>(MainController());
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.main,
      getPages: [
        GetPage(
          name: AppRoutes.main,
          page: () => const Scaffold(body: HomePage()),
        ),
        GetPage(
          name: AppRoutes.webView,
          page: () => const SizedBox(key: Key('webViewPageStub')),
        ),
        GetPage(
          name: AppRoutes.accountList,
          page: () => const SizedBox(key: Key('accountListPageStub')),
        ),
        GetPage(
          name: AppRoutes.certificationBindCard,
          page: () => const SizedBox(key: Key('bindCardPageStub')),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

class _RecordingAdapter implements HttpClientAdapter {
  int homeRequestCount = 0;
  int dialogRequestCount = 0;
  int orderListRequestCount = 0;
  int bannerClickRecordCount = 0;
  int productApplyRequestCount = 0;
  int productDetailRequestCount = 0;
  final originalCardRetryOrderNos = <String>[];
  final userAccountListProductIds = <String>[];
  String? lastBannerId;
  String? lastProductApplyId;
  Map<String, dynamic> homePayload = <String, dynamic>{};
  Map<String, dynamic> dialogPayload = <String, dynamic>{};
  Map<String, dynamic> originalCardRetryPayload = <String, dynamic>{};
  Map<String, dynamic> userAccountListPayload = <String, dynamic>{};
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
    if (options.path == 'https://api.example.test${ApiEndpoints.orderList}') {
      orderListRequestCount++;
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
    if (options.path ==
        'https://api.example.test${ApiEndpoints.originalCardRetry}') {
      originalCardRetryOrderNos.add(
        options.data is Map
            ? options.data['chattinesses']?.toString() ?? ''
            : '',
      );
      return _successResponse(originalCardRetryPayload);
    }
    if (options.path ==
        'https://api.example.test${ApiEndpoints.userAccountList}') {
      userAccountListProductIds.add(
        options.data is Map
            ? options.data['geobotanists']?.toString() ?? ''
            : '',
      );
      return _successResponse(userAccountListPayload);
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

  ResponseBody _successResponse(Map<String, dynamic> payload) {
    return ResponseBody.fromString(
      jsonEncode({'griding': 0, 'organizational': 'success', 'fas': payload}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RecordingToastPresenter implements ToastPresenter {
  int showLoadingCount = 0;
  int dismissLoadingCount = 0;
  final errorMessages = <String>[];

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      errorMessages.add(message);
    }
  }

  @override
  Future<void> showLoading(String? message) async {
    showLoadingCount++;
  }

  @override
  Future<void> dismissLoading() async {
    dismissLoadingCount++;
  }
}
