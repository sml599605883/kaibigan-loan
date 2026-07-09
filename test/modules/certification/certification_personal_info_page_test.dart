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
import 'package:kaibigan_loan/src/modules/certification/certification_personal_info_page.dart';
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

  testWidgets('loads personal info fields from second item endpoint', (
    tester,
  ) async {
    apiClient.personalInfoStates = _personalInfoStates();

    await _pumpPage(tester, arguments: {'geobotanists': 'product-1'});
    await tester.pumpAndSettle();

    expect(apiClient.personalInfoIds, ['product-1']);
    expect(find.text('Identity verification'), findsOneWidget);
    expect(
      find.text('Fill in personal information truthfully.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('personalInfoProgressImage')), findsOneWidget);
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('personalInfoProgressImage')),
                  )
                  .image
              as AssetImage)
          .assetName,
      AppAssets.certificationPersonalProgress,
    );
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects enum value and submits dynamic payload keys', (
    tester,
  ) async {
    apiClient.personalInfoStates = _personalInfoStates();
    apiClient.productDetailStates = {'wofuller': 'next step'};

    await _pumpPage(tester, arguments: {'geobotanists': 'product-2'});
    await tester.pumpAndSettle();

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('male').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('personalInfoInput_offer')),
      'john@example.com',
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiClient.savePersonalInfoPayloads, [
      {'geobotanists': 'product-2', 'copies': '1', 'offer': 'john@example.com'},
    ]);
    expect(toastPresenter.loadingMessages, [null, null]);
    expect(toastPresenter.dismissCount, 2);
    expect(toastPresenter.messages, ['saved', 'next step']);
    expect(apiClient.productDetailIds, ['product-2']);
  });

  testWidgets('requires mandatory fields before submitting', (tester) async {
    apiClient.personalInfoStates = {
      'enthrones': [
        {
          'primogenitor': 'Email',
          'suppletive': 'Please input email',
          'griding': 'offer',
          'prognosticator': 'onto',
          'hairbreadth': 0,
        },
      ],
    };

    await _pumpPage(tester, arguments: {'geobotanists': 'product-3'});
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiClient.savePersonalInfoPayloads, isEmpty);
    expect(toastPresenter.errors, ['Please input email']);
  });

  testWidgets('shows API error when personal info request fails', (
    tester,
  ) async {
    apiClient.error = ApiBusinessException('personal info failed');

    await _pumpPage(tester, arguments: {'geobotanists': 'product-4'});
    await tester.pumpAndSettle();

    expect(toastPresenter.errors, ['personal info failed']);
    expect(find.text('No personal information available'), findsOneWidget);
  });

  testWidgets('work info route uses work info APIs with the same UI', (
    tester,
  ) async {
    apiClient.jobInfoStates = {
      'mourningly': 'Complete the filling and increase the borrowing limit.',
      'enthrones': [
        {
          'primogenitor': 'Company Name',
          'suppletive': 'Please input company name',
          'griding': 'freshly',
          'prognosticator': 'onto',
          'hairbreadth': 0,
          'solonets': 'SPSS',
        },
        {
          'primogenitor': 'Profession',
          'suppletive': 'Profession',
          'griding': 'profit',
          'prognosticator': 'stepped',
          'hairbreadth': 0,
          'solonets': 'Ofw',
          'metallurgists': [
            {'unwits': 'Doctor', 'commensurate': 3},
            {'unwits': 'Ofw', 'commensurate': 7},
          ],
        },
      ],
    };
    apiClient.productDetailStates = {'wofuller': 'work next step'};

    await _pumpPage(
      tester,
      routeName: AppRoutes.certificationWorkInfo,
      page: () => const CertificationPersonalInfoPage.work(),
      arguments: {'geobotanists': 'product-work'},
    );
    await tester.pumpAndSettle();

    expect(apiClient.jobInfoIds, ['product-work']);
    expect(find.text('Identity verification'), findsOneWidget);
    expect(find.text('Company Name'), findsOneWidget);
    expect(find.text('SPSS'), findsOneWidget);
    expect(find.text('Profession'), findsOneWidget);
    expect(find.text('Ofw'), findsOneWidget);
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('personalInfoProgressImage')),
                  )
                  .image
              as AssetImage)
          .assetName,
      AppAssets.certificationWorkProgress,
    );

    await tester.enterText(
      find.byKey(const Key('personalInfoInput_freshly')),
      'OpenAI PH',
    );
    await tester.tap(find.text('Ofw'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Doctor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(apiClient.saveJobInfoPayloads, [
      {'geobotanists': 'product-work', 'freshly': 'OpenAI PH', 'profit': '3'},
    ]);
    expect(apiClient.productDetailIds, ['product-work']);
    expect(toastPresenter.messages, ['saved work', 'work next step']);
  });
}

Map<String, dynamic> _personalInfoStates() {
  return {
    'mourningly': 'Fill in personal information truthfully.',
    'enthrones': [
      {
        'primogenitor': 'Gender',
        'suppletive': 'Gender',
        'griding': 'copies',
        'prognosticator': 'stepped',
        'hairbreadth': 0,
        'solonets': 'Female',
        'metallurgists': [
          {'unwits': 'male', 'commensurate': 1},
          {'unwits': 'Female', 'commensurate': 2},
        ],
      },
      {
        'primogenitor': 'Email',
        'suppletive': 'Please input email',
        'griding': 'offer',
        'prognosticator': 'onto',
        'hairbreadth': 0,
        'solonets': 'jane@example.com',
      },
    ],
  };
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required Object? arguments,
  String routeName = AppRoutes.certificationPersonalInfo,
  Widget Function() page = _personalInfoPage,
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(name: routeName, page: page),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>(routeName, arguments: arguments);
  await tester.pump();
}

Widget _personalInfoPage() => const CertificationPersonalInfoPage();

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final personalInfoIds = <String>[];
  final jobInfoIds = <String>[];
  final savePersonalInfoPayloads = <Map<String, dynamic>>[];
  final saveJobInfoPayloads = <Map<String, dynamic>>[];
  final productDetailIds = <String>[];
  Map<String, dynamic> personalInfoStates = <String, dynamic>{};
  Map<String, dynamic> jobInfoStates = <String, dynamic>{};
  Map<String, dynamic> productDetailStates = <String, dynamic>{};
  Object? error;

  @override
  Future<ApiResponse> personalInfo({required String geobotanists}) async {
    personalInfoIds.add(geobotanists);
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(personalInfoStates),
    );
  }

  @override
  Future<ApiResponse> jobInfo({required String geobotanists}) async {
    jobInfoIds.add(geobotanists);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(jobInfoStates),
    );
  }

  @override
  Future<ApiResponse> savePersonalInfo({
    required Map<String, dynamic> data,
  }) async {
    savePersonalInfoPayloads.add(Map<String, dynamic>.from(data));
    return ApiResponse(code: 0, message: 'saved', states: Json(null));
  }

  @override
  Future<ApiResponse> saveJobInfo({required Map<String, dynamic> data}) async {
    saveJobInfoPayloads.add(Map<String, dynamic>.from(data));
    return ApiResponse(code: 0, message: 'saved work', states: Json(null));
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
  final loadingMessages = <String?>[];
  final messages = <String>[];
  final errors = <String>[];
  int dismissCount = 0;

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      dismissCount++;
      errors.add(message);
    } else {
      messages.add(message);
    }
  }

  @override
  Future<void> showLoading(String? message) async {
    loadingMessages.add(message);
  }

  @override
  Future<void> dismissLoading() async {
    dismissCount++;
  }
}
