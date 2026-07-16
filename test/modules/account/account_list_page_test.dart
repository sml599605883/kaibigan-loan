import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/modules/account/account_list_page.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeApiClient apiClient;
  late _FakeToastPresenter toastPresenter;

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    toastPresenter = _FakeToastPresenter();
    Get.put<ApiClient>(apiClient);
    AppToast.presenter = toastPresenter;
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    Get.reset();
  });

  testWidgets('loads Bank accounts and selects the main account', (
    tester,
  ) async {
    apiClient.accountStates = _accounts();

    await _pumpPage(
      tester,
      arguments: <String, String>{
        'geobotanists': ' product-1 ',
        'dodgy': ' ORDER001 ',
      },
    );
    await tester.pumpAndSettle();

    expect(apiClient.accountRequests, <String>['product-1']);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('BDO'), findsOneWidget);
    expect(find.text('**** 1234'), findsOneWidget);
    expect(
      _selectionAssetFor(tester, 'bind-1'),
      AppAssets.accountOptionSelected,
    );
    expect(
      _selectionAssetFor(tester, 'bind-2'),
      AppAssets.accountOptionUnselected,
    );
    expect(
      tester
          .widget<MaterialButton>(find.byKey(const Key('accountListConfirm')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('lays out Bank and E-wallet cards from the Kaibigan design', (
    tester,
  ) async {
    apiClient.accountStates = _accounts();

    await _pumpPage(
      tester,
      arguments: <String, String>{
        'geobotanists': 'product-1',
        'dodgy': 'ORDER001',
      },
    );
    await tester.pumpAndSettle();

    final bankCard = find.byKey(const Key('accountListItem-bind-1'));
    final walletCard = find.byKey(const Key('accountListItem-bind-2'));
    final bankHeader = find.byKey(const Key('accountCardHeader-bind-1'));
    final bankLogo = find.byKey(const Key('accountCardLogo-bind-1'));
    final bankReceiptPanel = find.byKey(
      const Key('accountCardReceiptPanel-bind-1'),
    );

    expect(tester.getSize(bankCard), const Size(335, 152));
    expect(tester.getSize(walletCard), const Size(335, 119));
    expect(tester.getSize(bankHeader), const Size(315, 30));
    expect(tester.getSize(bankLogo), const Size(30, 30));
    expect(tester.getSize(bankReceiptPanel).width, 315);
    expect(
      find.descendant(of: bankCard, matching: find.text('Receipt Account')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: walletCard, matching: find.text('Receipt Account')),
      findsOneWidget,
    );
    expect(
      find.text(
        'The bank is under maintenance. Loans may be delayed.\n'
        'Please wait or choose another option',
      ),
      findsOneWidget,
    );
    expect(_selectionImageFor(tester, 'bind-1').width, 20);
    expect(tester.widget<Text>(find.text('BDO')).style?.fontSize, 14);
    final accountStyle = tester.widget<Text>(find.text('**** 1234')).style;
    expect(accountStyle?.fontSize, 20);
    expect(accountStyle?.fontWeight, FontWeight.w700);
  });

  testWidgets('submits selected GCash account and returns it', (tester) async {
    apiClient.accountStates = _accounts();
    Future<Object?>? routeResult;
    await _pumpPage(
      tester,
      arguments: <String, String>{
        'geobotanists': 'product-1',
        'dodgy': 'ORDER001',
      },
      onRouteOpened: (route) => routeResult = route,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountListItem-bind-2')));
    await tester.tap(find.byKey(const Key('accountListConfirm')));
    await tester.pumpAndSettle();

    expect(apiClient.changeRequests, <Map<String, String>>[
      <String, String>{'dodgy': 'ORDER001', 'smokehouse': 'bind-2'},
    ]);
    expect(await routeResult, 'https://example.test/account-changed');
    expect(Get.currentRoute, AppRoutes.main);
  });

  testWidgets('add payment method opens bind card in account change mode', (
    tester,
  ) async {
    apiClient.accountStates = _accounts();
    await _pumpPage(
      tester,
      arguments: <String, String>{
        'geobotanists': 'product-1',
        'dodgy': 'ORDER001',
      },
    );
    await tester.pumpAndSettle();

    final addPaymentMethod = find.byKey(const Key('accountAddPaymentMethod'));
    tester.widget<InkWell>(addPaymentMethod).onTap!.call();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.certificationBindCard);
    expect(Get.arguments, <String, dynamic>{
      'geobotanists': 'product-1',
      'dodgy': 'ORDER001',
      'isAccountChange': true,
    });
  });

  testWidgets('shows load error and retries the request', (tester) async {
    apiClient.accountError = ApiBusinessException('Account list failed');
    await _pumpPage(
      tester,
      arguments: <String, String>{
        'geobotanists': 'product-1',
        'dodgy': 'ORDER001',
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Account list failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(apiClient.accountRequests, <String>['product-1', 'product-1']);
  });

  testWidgets('requires an order id before loading account options', (
    tester,
  ) async {
    apiClient.accountStates = _accounts();
    await _pumpPage(
      tester,
      arguments: <String, String>{'geobotanists': 'product-1'},
    );
    await tester.pumpAndSettle();

    expect(apiClient.accountRequests, isEmpty);
    expect(find.text('Missing order information'), findsOneWidget);
    expect(
      tester
          .widget<MaterialButton>(find.byKey(const Key('accountListConfirm')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('keeps selection and re-enables Confirm after submit failure', (
    tester,
  ) async {
    apiClient.accountStates = _accounts();
    apiClient.changeError = StateError('submit failed');
    await _pumpPage(
      tester,
      arguments: <String, String>{
        'geobotanists': 'product-1',
        'dodgy': 'ORDER001',
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accountListItem-bind-2')));
    await tester.tap(find.byKey(const Key('accountListConfirm')));
    await tester.pumpAndSettle();

    expect(toastPresenter.errorMessages, contains('Bad state: submit failed'));
    expect(
      _selectionAssetFor(tester, 'bind-2'),
      AppAssets.accountOptionSelected,
    );
    expect(
      tester
          .widget<MaterialButton>(find.byKey(const Key('accountListConfirm')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'dismisses submit loading when the page is popped before failure',
    (tester) async {
      apiClient.accountStates = _accounts();
      apiClient.changeCompleter = Completer<ApiResponse>();
      await _pumpPage(
        tester,
        arguments: <String, String>{
          'geobotanists': 'product-1',
          'dodgy': 'ORDER001',
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('accountListConfirm')));
      await tester.pump();
      expect(toastPresenter.showLoadingCount, 1);

      Get.back<void>();
      await tester.pumpAndSettle();
      apiClient.changeCompleter!.completeError(StateError('submit failed'));
      await tester.pumpAndSettle();

      expect(toastPresenter.dismissLoadingCount, 1);
      expect(toastPresenter.errorMessages, isEmpty);
    },
  );

  testWidgets('shows empty state and cannot submit', (tester) async {
    apiClient.accountStates = Json(<String, dynamic>{
      'religiosities': <dynamic>[],
    });
    await _pumpPage(
      tester,
      arguments: <String, String>{
        'geobotanists': 'product-1',
        'dodgy': 'ORDER001',
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('No payment methods available'), findsOneWidget);
    expect(
      tester
          .widget<MaterialButton>(find.byKey(const Key('accountListConfirm')))
          .onPressed,
      isNull,
    );
    expect(apiClient.changeRequests, isEmpty);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required Object? arguments,
  void Function(Future<Object?>? route)? onRouteOpened,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.main,
      getPages: <GetPage<dynamic>>[
        GetPage(name: AppRoutes.main, page: () => const SizedBox()),
        GetPage(
          name: AppRoutes.accountList,
          page: () => const AccountListPage(),
        ),
        GetPage(
          name: AppRoutes.certificationBindCard,
          page: () => const SizedBox(key: Key('bindCardPageStub')),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  final route = Get.toNamed<Object?>(
    AppRoutes.accountList,
    arguments: arguments,
  );
  onRouteOpened?.call(route);
}

Json _accounts() => Json(<String, dynamic>{
  'religiosities': <Map<String, dynamic>>[
    <String, dynamic>{
      'overdoer': 'E-wallet',
      'dendron': '',
      'anchovetta': <Map<String, dynamic>>[
        <String, dynamic>{
          'smokehouse': 'bind-2',
          'vocalically': '',
          'postaccident': 'GCash',
          'flamen': '0917 000 0000',
          'bondmen': 1,
          'uptime': 0,
        },
      ],
    },
    <String, dynamic>{
      'overdoer': 'Bank',
      'dendron': '',
      'anchovetta': <Map<String, dynamic>>[
        <String, dynamic>{
          'smokehouse': 'bind-1',
          'vocalically': '',
          'postaccident': 'BDO',
          'flamen': '**** 1234',
          'bondmen': 0,
          'uptime': 1,
        },
      ],
    },
  ],
});

String _selectionAssetFor(WidgetTester tester, String bindId) {
  return (_selectionImageFor(tester, bindId).image as AssetImage).assetName;
}

Image _selectionImageFor(WidgetTester tester, String bindId) {
  final images = tester.widgetList<Image>(
    find.descendant(
      of: find.byKey(Key('accountListItem-$bindId')),
      matching: find.byType(Image),
    ),
  );
  final selectionImage = images.singleWhere(
    (image) => image.image is AssetImage,
  );
  return selectionImage;
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final accountRequests = <String>[];
  final changeRequests = <Map<String, String>>[];
  Json accountStates = Json(null);
  Object? accountError;
  Object? changeError;
  Completer<ApiResponse>? changeCompleter;

  @override
  Future<ApiResponse> userAccountList({required String geobotanists}) async {
    accountRequests.add(geobotanists);
    if (accountError != null) throw accountError!;
    return ApiResponse(code: 0, message: '', states: accountStates);
  }

  @override
  Future<ApiResponse> changeOrderAccount({
    required String dodgy,
    required String smokehouse,
  }) async {
    changeRequests.add(<String, String>{
      'dodgy': dodgy,
      'smokehouse': smokehouse,
    });
    if (changeCompleter != null) return changeCompleter!.future;
    if (changeError != null) throw changeError!;
    return ApiResponse(
      code: 0,
      message: '',
      states: Json({'preinserting': 'https://example.test/account-changed'}),
    );
  }
}

class _FakeToastPresenter implements ToastPresenter {
  final errorMessages = <String>[];
  int showLoadingCount = 0;
  int dismissLoadingCount = 0;

  @override
  Future<void> dismissLoading() async {
    dismissLoadingCount++;
  }

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) errorMessages.add(message);
  }

  @override
  Future<void> showLoading(String? message) async {
    showLoadingCount++;
  }
}
