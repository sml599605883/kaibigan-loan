import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_exception.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_identity_page.dart';
import 'package:kaibigan_loan/src/modules/certification/certification_upload_page.dart';
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

  testWidgets('loads recommended id types from first postepileptic group', (
    tester,
  ) async {
    apiClient.states = {
      'postepileptic': [
        ['PRC', 'SSS', 'PASSPORT'],
        ['TIN', 'VOTERID'],
      ],
    };

    await _pumpPage(tester, arguments: {'geobotanists': 'product-1'});
    await tester.pumpAndSettle();

    expect(apiClient.basicPersonInfoIds, ['product-1']);
    expect(find.text('Recommended ID Type'), findsOneWidget);
    expect(find.text('Other Options'), findsOneWidget);
    expect(find.text('PRC'), findsOneWidget);
    expect(find.text('SSS'), findsOneWidget);
    expect(find.text('PASSPORT'), findsOneWidget);
    expect(find.text('TIN ID'), findsNothing);
  });

  testWidgets('shows remaining postepileptic groups in other options', (
    tester,
  ) async {
    apiClient.states = {
      'postepileptic': [
        ['PRC'],
        ['TIN', 'VOTERID'],
        ['HEALTHCARD'],
      ],
    };

    await _pumpPage(tester, arguments: {'geobotanists': 'product-2'});
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other Options'));
    await tester.pumpAndSettle();

    expect(find.text('PRC'), findsNothing);
    expect(find.text('TIN'), findsOneWidget);
    expect(find.text('VOTERID'), findsOneWidget);
    expect(find.text('HEALTHCARD'), findsOneWidget);
  });

  testWidgets('opens upload page with selected id type', (tester) async {
    apiClient.states = {
      'postepileptic': [
        ['PRC', 'SSS'],
      ],
    };

    await _pumpPage(tester, arguments: {'geobotanists': 'product-5'});
    await tester.pumpAndSettle();

    await tester.tap(find.text('PRC'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.certificationUpload);
    expect(Get.arguments, containsPair('geobotanists', 'product-5'));
    expect(Get.arguments, containsPair('cardType', 'PRC'));
    expect(
      (Get.arguments as Map)['scene3StartTimeSeconds'],
      isA<int>().having((value) => value, 'positive', greaterThan(0)),
    );
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets(
    'uses empty state instead of crashing when id types are missing',
    (tester) async {
      apiClient.states = {'postepileptic': <dynamic>[]};

      await _pumpPage(tester, arguments: {'geobotanists': 'product-3'});
      await tester.pumpAndSettle();

      expect(find.text('No ID types available'), findsOneWidget);
    },
  );

  testWidgets('adapts to compact screens without layout overflow', (
    tester,
  ) async {
    apiClient.states = {
      'postepileptic': [
        [
          'DRIVINGLICENSE',
          'PRC',
          'SSS',
          'PASSPORT',
          'POSTALID',
          'UMID',
          'NATIONALID',
          'TYPE-A',
          'TYPE-B',
          'TYPE-C',
          'TYPE-D',
          'TYPE-E',
          'TYPE-F',
        ],
      ],
    };

    await _pumpPage(
      tester,
      arguments: {'geobotanists': 'product-compact'},
      size: const Size(320, 568),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('DRIVINGLICENSE'), findsOneWidget);
    expect(find.text('UMID'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('TYPE-F'), findsOneWidget);
  });

  testWidgets('shows API error when identity info request fails', (
    tester,
  ) async {
    apiClient.error = ApiBusinessException('identity failed');

    await _pumpPage(tester, arguments: {'geobotanists': 'product-4'});
    await tester.pumpAndSettle();

    expect(toastPresenter.errors, ['identity failed']);
    expect(find.text('No ID types available'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required Object? arguments,
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
        GetPage(
          name: '/certification-identity',
          page: () => const CertificationIdentityPage(),
        ),
        GetPage(
          name: AppRoutes.certificationUpload,
          page: () => const CertificationUploadPage(),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>('/certification-identity', arguments: arguments);
  await tester.pump();
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final basicPersonInfoIds = <String>[];
  Map<String, dynamic> states = <String, dynamic>{};
  Object? error;

  @override
  Future<ApiResponse> basicPersonInfo({required String geobotanists}) async {
    basicPersonInfoIds.add(geobotanists);
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    return ApiResponse(code: 0, message: 'success', states: Json(states));
  }
}

class _FakeToastPresenter implements ToastPresenter {
  final errors = <String>[];

  @override
  Future<void> show(String message, {required bool isError}) async {
    if (isError) {
      errors.add(message);
    }
  }

  @override
  Future<void> showLoading(String? message) async {}

  @override
  Future<void> dismissLoading() async {}
}
