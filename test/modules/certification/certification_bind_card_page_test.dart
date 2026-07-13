import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_bind_card_page.dart';

void main() {
  late _FakeApiClient apiClient;

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
  });

  tearDown(Get.reset);

  testWidgets('loads only returned bind card groups', (tester) async {
    apiClient.states = _bindCardStates();

    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(apiClient.productIds, ['product-bind']);
    expect(find.text('E-wallet'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('Cash Pickup'), findsNothing);
    expect(
      find.byKey(const Key('bindCardField_wallet_number')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('bindCardProgress')), findsOneWidget);
    expect(
      (tester.widget<Image>(find.byKey(const Key('bindCardProgress'))).image
              as AssetImage)
          .assetName,
      AppAssets.certificationBindCardProgress,
    );
  });

  testWidgets('preserves group input state across tab switches', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('bindCardField_wallet_number')),
      '09171234567',
    );
    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bindCardField_account_number')),
      '1234567890',
    );
    await tester.tap(find.byKey(const Key('bindCardTab_wallet')));
    await tester.pumpAndSettle();

    expect(find.text('09171234567'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    expect(find.text('1234567890'), findsOneWidget);
  });

  testWidgets('enum sheet selects normalized value and display label', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardField_bank_code')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metro Bank'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Metro Bank'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bindCardTab_wallet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    expect(find.text('Metro Bank'), findsOneWidget);
  });

  testWidgets('API error displays Retry and reloads', (tester) async {
    apiClient.error = ApiBusinessException('offline');
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.text('offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    apiClient.error = null;
    apiClient.states = _bindCardStates();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(apiClient.productIds, ['product-bind', 'product-bind']);
    expect(find.text('E-wallet'), findsOneWidget);
  });

  testWidgets('empty groups displays exact empty text', (tester) async {
    apiClient.states = {'enthrones': []};
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.text('No payment methods available'), findsOneWidget);
  });

  testWidgets('missing product ID makes no call and keeps stable UI', (
    tester,
  ) async {
    await _pumpPage(tester, apiClient: apiClient, arguments: const {});
    await tester.pumpAndSettle();

    expect(apiClient.productIds, isEmpty);
    expect(find.text('No payment methods available'), findsOneWidget);
  });

  testWidgets('does not throw or overflow at reference and narrow viewports', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      size: const Size(320, 700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required _FakeApiClient apiClient,
  required Object? arguments,
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  const routeName = '/bind-card-test';
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(
          name: routeName,
          page: () => CertificationBindCardPage(apiClient: apiClient),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>(routeName, arguments: arguments);
  await tester.pump();
}

Map<String, String> _arguments() => {'geobotanists': ' product-bind '};

Map<String, dynamic> _bindCardStates() => {
  'mourningly': 'Choose your payment method',
  'pollywogs': 'Details must match your identity',
  'enthrones': [
    {
      'primogenitor': 'E-wallet',
      'commensurate': 'wallet',
      'enthrones': [
        {
          'primogenitor': 'Wallet number',
          'griding': 'wallet_number',
          'suppletive': 'Enter wallet number',
          'prognosticator': 'text',
          'whackers': '09170000000',
        },
      ],
    },
    {
      'primogenitor': 'Bank',
      'commensurate': 'bank',
      'enthrones': [
        {
          'primogenitor': 'Bank name',
          'griding': 'bank_code',
          'suppletive': 'Choose your bank',
          'prognosticator': 'enum',
          'solonets': 'Old Bank',
          'whackers': 7,
          'metallurgists': [
            {
              'commensurate': 8,
              'unwits': 'Metro Bank',
              'vocalically': 'https://api.example.com/metro.png',
              'bondmen': 0,
            },
          ],
        },
        {
          'primogenitor': 'Account number',
          'griding': 'account_number',
          'suppletive': 'Enter account number',
          'prognosticator': 'text',
        },
      ],
    },
  ],
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final productIds = <String>[];
  Map<String, dynamic> states = <String, dynamic>{};
  Object? error;

  @override
  Future<ApiResponse> bankInfo({required String geobotanists}) async {
    productIds.add(geobotanists);
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    return ApiResponse(code: 0, message: 'success', states: Json(states));
  }
}
