import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/modules/orders/mine_order_list_page.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeApiClient apiClient;

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    Get.put<ApiClient>(apiClient);
    AppToast.presenter = _NoopToastPresenter();
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    Get.reset();
  });

  testWidgets('loads selected status and renders API strings unchanged', (
    tester,
  ) async {
    apiClient.orderListStates = Json({
      'religiosities': [
        {
          'omissible': 'Cash Bee',
          'ecumenicalism': '₱ 88,888.01 raw',
          'playhouses': 'Custom Status',
          'spelts': 'raw due date',
          'restless': 'Server Action',
        },
      ],
    });

    await _pumpMineOrderList(tester, arguments: {'initialStatus': '7'});
    await tester.pumpAndSettle();

    expect(apiClient.statusRequests, ['7']);
    expect(find.text('Outstanding'), findsWidgets);
    expect(find.text('Cash Bee'), findsOneWidget);
    expect(find.text('₱ 88,888.01 raw'), findsOneWidget);
    expect(find.text('Custom Status'), findsOneWidget);
    expect(find.text('raw due date'), findsOneWidget);
    expect(find.text('Server Action'), findsOneWidget);
  });

  testWidgets('shows empty design state when API returns no orders', (
    tester,
  ) async {
    apiClient.orderListStates = Json({
      'religiosities': <Map<String, dynamic>>[],
    });

    await _pumpMineOrderList(tester);
    await tester.pumpAndSettle();

    expect(apiClient.statusRequests, ['4']);
    expect(find.text('No information available'), findsOneWidget);
  });
}

Future<void> _pumpMineOrderList(
  WidgetTester tester, {
  Object? arguments,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.main,
      getPages: [
        GetPage(name: AppRoutes.main, page: () => const SizedBox()),
        GetPage(
          name: AppRoutes.mineOrderList,
          page: () => const MineOrderListPage(),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>(AppRoutes.mineOrderList, arguments: arguments);
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final statusRequests = <String>[];
  Json orderListStates = Json(null);

  @override
  Future<ApiResponse> orderList({
    required String mummies,
    String dissipaters = '1',
    String bewaring = '50',
  }) async {
    statusRequests.add(mummies);
    return ApiResponse(code: 0, message: 'success', states: orderListStates);
  }
}

class _NoopToastPresenter implements ToastPresenter {
  @override
  Future<void> dismissLoading() async {}

  @override
  Future<void> show(String message, {required bool isError}) async {}

  @override
  Future<void> showLoading(String? message) async {}
}
