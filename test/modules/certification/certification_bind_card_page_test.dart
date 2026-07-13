import 'dart:async';

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
import 'package:kaibigan_loan/src/core/report/report_cache.dart';
import 'package:kaibigan_loan/src/core/report/report_manager.dart';
import 'package:kaibigan_loan/src/core/report/report_models.dart';
import 'package:kaibigan_loan/src/core/report/report_native_bridge.dart';
import 'package:kaibigan_loan/src/core/report/report_network.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_bind_card_page.dart';
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

  testWidgets('opening enum sheet dismisses active text keyboard', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardField_wallet_number')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardField_bank_code')));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('enum sheet scrolls a later initial selection into view', (
    tester,
  ) async {
    apiClient.states = _bindCardStates(optionCount: 7, initialBankValue: '6');
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardTab_bank')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bindCardField_bank_code')));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('bindCardOptionList')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(0));
    expect(
      find.descendant(
        of: find.byKey(const Key('bindCardOptionList')),
        matching: find.text('Bank 6'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('back target and method tabs expose accessible semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    apiClient.states = _bindCardStates();
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('Back')), const Size(48, 48));
    expect(
      tester.getSemantics(find.byKey(const Key('bindCardTab_wallet'))),
      matchesSemantics(
        label: 'E-wallet',
        hasSelectedState: true,
        isButton: true,
        isSelected: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('large text scale keeps header title visible without overflow', (
    tester,
  ) async {
    apiClient.states = _bindCardStates();
    await _pumpPage(
      tester,
      apiClient: apiClient,
      arguments: _arguments(),
      textScaler: const TextScaler.linear(2),
    );
    await tester.pumpAndSettle();

    expect(find.text('Identity verification'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed page ignores pending bank info response', (
    tester,
  ) async {
    final response = Completer<ApiResponse>();
    apiClient.pendingResponse = response;
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pump();

    Get.back<void>();
    await tester.pumpAndSettle();
    response.complete(
      ApiResponse(code: 0, message: 'success', states: Json(_bindCardStates())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
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

  testWidgets('required empty field shows server placeholder without saving', (
    tester,
  ) async {
    apiClient.states = _submissionStates(emptyFirstName: true);
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(toastPresenter.messages, ['Enter your first name']);
    expect(toastPresenter.errors, isEmpty);
    expect(apiClient.saveRequests, isEmpty);
  });

  testWidgets('different account entries do not call save API', (tester) async {
    apiClient.states = _submissionStates(
      initialCardNo: '09170000000',
      initialConfirmCardNo: '09171111111',
    );
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(toastPresenter.messages, ['The two account entries do not match']);
    expect(apiClient.saveRequests, isEmpty);
  });

  testWidgets('submits documented string fields once', (tester) async {
    apiClient.states = _submissionStates();
    apiClient.productDetailStates = {'wofuller': 'stay on bind card'};
    final saveResponse = Completer<ApiResponse>();
    apiClient.pendingSaveResponse = saveResponse;
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    final submit = find.byKey(const Key('bindCardSubmit'));
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();

    expect(apiClient.saveRequests, [
      {
        'geobotanists': 'product-bind',
        'heirship': 'wallet',
        'bladers': '6',
        'zips': 'Jane',
        'acreage': '',
        'coinable': 'Doe',
        'flabby': '09171234567',
        'rapt': '09171234567',
      },
    ]);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    expect(toastPresenter.loadingMessages, [null]);

    saveResponse.complete(
      ApiResponse(code: 0, message: 'saved', states: Json(null)),
    );
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, ['product-bind']);
    expect(toastPresenter.loadingMessages, [null, null]);
    expect(toastPresenter.dismissCount, 2);
  });

  testWidgets('normal success reports risk scene 8', (tester) async {
    final reportManager = _RecordingReportManager();
    Get.put<ReportManager>(reportManager);
    apiClient.states = _submissionStates();
    apiClient.productDetailStates = {'wofuller': 'stay on bind card'};
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    for (var index = 0; index < 5; index++) {
      await tester.pump();
    }

    expect(reportManager.riskReports, hasLength(1));
    expect(reportManager.riskReports.single['productId'], 'product-bind');
    expect(reportManager.riskReports.single['sceneType'], '8');
    expect(reportManager.riskReports.single['startTimeSeconds'], isA<int>());
  });

  testWidgets('save failure shows resolved error and re-enables submit', (
    tester,
  ) async {
    apiClient.states = _submissionStates();
    apiClient.saveError = ApiBusinessException('save failed');
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    final submit = find.byKey(const Key('bindCardSubmit'));
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(toastPresenter.errors, ['save failed']);
    expect(apiClient.productDetailIds, isEmpty);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
    expect(find.byKey(const Key('bindCardSubmit')), findsOneWidget);
  });

  testWidgets('code 20000 stays on page without product flow', (tester) async {
    apiClient.states = _submissionStates();
    apiClient.saveResponse = ApiResponse(
      code: 20000,
      message: 'verify',
      states: Json(null),
    );
    await _pumpPage(tester, apiClient: apiClient, arguments: _arguments());
    await tester.pumpAndSettle();

    await _fillSubmissionForm(tester);
    await tester.tap(find.byKey(const Key('bindCardSubmit')));
    await tester.pumpAndSettle();

    expect(apiClient.productDetailIds, isEmpty);
    expect(toastPresenter.errors, ['Liveness verification required']);
    expect(find.byKey(const Key('bindCardSubmit')), findsOneWidget);
  });
}

Future<void> _fillSubmissionForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bindCardField_channelCode')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('GCash').last);
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('bindCardField_firstName')),
    ' Jane ',
  );
  await tester.enterText(
    find.byKey(const Key('bindCardField_lastName')),
    ' Doe ',
  );
  await tester.enterText(
    find.byKey(const Key('bindCardField_cardNo')),
    ' 09171234567 ',
  );
  await tester.enterText(
    find.byKey(const Key('bindCardField_confirmCardNo')),
    '09171234567',
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required _FakeApiClient apiClient,
  required Object? arguments,
  Size size = const Size(375, 812),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  const routeName = '/bind-card-test';
  await tester.pumpWidget(
    GetMaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
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

Map<String, dynamic> _bindCardStates({
  int optionCount = 1,
  String initialBankValue = '7',
}) => {
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
          'solonets': optionCount > 1 ? 'Bank $initialBankValue' : 'Old Bank',
          'whackers': initialBankValue,
          'metallurgists': optionCount > 1
              ? List.generate(
                  optionCount,
                  (index) => {
                    'commensurate': index,
                    'unwits': 'Bank $index',
                    'bondmen': 0,
                  },
                )
              : [
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

Map<String, dynamic> _submissionStates({
  bool emptyFirstName = false,
  String initialCardNo = '',
  String initialConfirmCardNo = '',
}) => {
  'enthrones': [
    {
      'primogenitor': 'E-wallet',
      'commensurate': 'wallet',
      'enthrones': [
        {
          'primogenitor': 'Channel',
          'griding': 'channelCode',
          'suppletive': 'Choose a channel',
          'prognosticator': 'enum',
          'hairbreadth': 0,
          'solonets': 'GCash',
          'whackers': 6,
          'metallurgists': [
            {'commensurate': 6, 'unwits': 'GCash', 'bondmen': 0},
          ],
        },
        {
          'primogenitor': 'First name',
          'griding': 'firstName',
          'suppletive': 'Enter your first name',
          'prognosticator': 'text',
          'hairbreadth': 0,
          if (!emptyFirstName) 'whackers': 'Jane',
        },
        {
          'primogenitor': 'Middle name',
          'griding': 'middleName',
          'suppletive': '',
          'prognosticator': 'text',
          'hairbreadth': 1,
        },
        {
          'primogenitor': 'Last name',
          'griding': 'lastName',
          'suppletive': 'Enter your last name',
          'prognosticator': 'text',
          'hairbreadth': 0,
          'whackers': 'Doe',
        },
        {
          'primogenitor': 'Account number',
          'griding': 'cardNo',
          'suppletive': 'Enter account number',
          'prognosticator': 'text',
          'hairbreadth': 0,
          'whackers': initialCardNo.isEmpty ? '09171234567' : initialCardNo,
        },
        {
          'primogenitor': 'Confirm account number',
          'griding': 'confirmCardNo',
          'suppletive': 'Confirm account number',
          'prognosticator': 'text',
          'hairbreadth': 0,
          'whackers': initialConfirmCardNo.isEmpty
              ? '09171234567'
              : initialConfirmCardNo,
        },
        {
          'primogenitor': 'Funny Loan field',
          'griding': 'bank_code',
          'suppletive': 'Ignore this field',
          'prognosticator': 'text',
          'hairbreadth': 0,
          'whackers': 'must-not-submit',
        },
      ],
    },
  ],
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final productIds = <String>[];
  final productDetailIds = <String>[];
  final saveRequests = <Map<String, String>>[];
  Map<String, dynamic> states = <String, dynamic>{};
  Map<String, dynamic> productDetailStates = <String, dynamic>{};
  Object? error;
  Object? saveError;
  Completer<ApiResponse>? pendingResponse;
  Completer<ApiResponse>? pendingSaveResponse;
  ApiResponse? saveResponse;

  @override
  Future<ApiResponse> bankInfo({required String geobotanists}) async {
    productIds.add(geobotanists);
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    final pending = pendingResponse;
    if (pending != null) {
      return pending.future;
    }
    return ApiResponse(code: 0, message: 'success', states: Json(states));
  }

  @override
  Future<ApiResponse> saveBankInfo({
    required String geobotanists,
    required String heirship,
    required String bladers,
    required String zips,
    required String acreage,
    required String coinable,
    required String flabby,
    required String rapt,
    String clevises = '',
    String scolloped = '',
    String arrests = '',
  }) async {
    saveRequests.add({
      'geobotanists': geobotanists,
      'heirship': heirship,
      'bladers': bladers,
      'zips': zips,
      'acreage': acreage,
      'coinable': coinable,
      'flabby': flabby,
      'rapt': rapt,
    });
    final requestError = saveError;
    if (requestError != null) {
      throw requestError;
    }
    final pending = pendingSaveResponse;
    if (pending != null) {
      return pending.future;
    }
    return saveResponse ??
        ApiResponse(code: 0, message: 'saved', states: Json(null));
  }

  @override
  Future<ApiResponse> productDetail({required String geobotanists}) async {
    productDetailIds.add(geobotanists);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(productDetailStates),
    );
  }
}

class _FakeToastPresenter implements ToastPresenter {
  final messages = <String>[];
  final errors = <String>[];
  final loadingMessages = <String?>[];
  int dismissCount = 0;

  @override
  Future<void> dismissLoading() async {
    dismissCount += 1;
  }

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      errors.add(message);
      dismissCount += 1;
      return;
    }
    messages.add(message);
  }

  @override
  Future<void> showLoading(String? message) async {
    loadingMessages.add(message);
  }
}

class _RecordingReportManager extends ReportManager {
  _RecordingReportManager()
    : super(
        cache: _FakeReportCache(),
        nativeBridge: _FakeReportNativeBridge(),
        network: _FakeReportNetwork(),
      );

  final riskReports = <Map<String, Object>>[];

  @override
  Future<void> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required int startTimeSeconds,
  }) async {
    riskReports.add({
      'productId': productId,
      'sceneType': sceneType,
      'orderNo': orderNo,
      'startTimeSeconds': startTimeSeconds,
    });
  }
}

class _FakeReportCache implements ReportCache {
  @override
  Future<void> clearSessionReportState() async {}
  @override
  Future<String> getAttributionLastStatus() async => '';
  @override
  Future<String> getLastMarketSignature() async => '';
  @override
  Future<String> getLastPushToken() async => '';
  @override
  Future<int> getLoginAt() async => 0;
  @override
  Future<ReportLocation?> getLocation() async => null;
  @override
  Future<bool> isAttributionInitialized() async => false;
  @override
  Future<bool> isLoggedIn() async => false;
  @override
  Future<bool> markAppOpened() async => false;
  @override
  Future<void> saveLocation(ReportLocation location) async {}
  @override
  Future<void> setAttributionInitialized(bool value) async {}
  @override
  Future<void> setAttributionLastStatus(String value) async {}
  @override
  Future<void> setLastMarketSignature(String signature) async {}
  @override
  Future<void> setLastPushToken(String token) async {}
  @override
  Future<void> setLoginAt(int millis) async {}
}

class _FakeReportNativeBridge implements ReportNativeBridge {
  @override
  Future<NativeDeviceSnapshot> getDeviceSnapshot() async =>
      const NativeDeviceSnapshot();
  @override
  Future<ReportLocation?> getLocation() async => null;
  @override
  Future<String> getPushToken() async => '';
  @override
  Future<String> getTrackingStatus() async => '';
  @override
  Future<void> initializeAttribution(String token) async {}
  @override
  Stream<Json> nativeEvents() => const Stream<Json>.empty();
  @override
  Future<String> requestNotificationPermission() async => '';
  @override
  Future<String> requestTrackingPermission() async => '';
}

class _FakeReportNetwork implements ReportNetwork {
  @override
  Future<void> reportContacts(String encryptedPayload) async {}
  @override
  Future<void> reportDeviceInfo(String encryptedPayload) async {}
  @override
  Future<void> reportFaceResult(FaceReportPayload payload) async {}
  @override
  Future<Json> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) async => Json(null);
  @override
  Future<void> reportLocation(ReportLocation location) async {}
  @override
  Future<void> reportPushToken(String token) async {}
  @override
  Future<void> reportRiskBehavior(Map<String, dynamic> payload) async {}
}
