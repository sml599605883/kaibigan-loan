import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/modules/orders/orders_page.dart';
import 'package:kaibigan_loan/src/navigation_helper.dart';
import 'package:kaibigan_loan/src/utils/app_toast.dart';

void main() {
  late _FakeApiClient apiClient;

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    Get.put<SessionStore>(SessionStore.memory());
    Get.put<ApiClient>(apiClient);
    AppToast.presenter = _NoopToastPresenter();
  });

  tearDown(() {
    AppToast.presenter = const EasyLoadingToastPresenter();
    NavigationHelper.locationAccessChecker =
        NavigationHelper.defaultLocationAccessChecker;
    NavigationHelper.locationReporter =
        NavigationHelper.defaultLocationReporter;
    Get.reset();
  });

  testWidgets('tabbar orders page loads API data for selected status', (
    tester,
  ) async {
    apiClient.responses['4'] = Json({
      'religiosities': [
        {
          'omissible': 'All Product',
          'ecumenicalism': 'server amount all',
          'playhouses': 'All Status',
          'spelts': 'all due date',
          'sandpainting': 'server date label',
          'berhyming': 'All Action',
        },
      ],
    });
    apiClient.responses['6'] = Json({
      'religiosities': [
        {
          'omissible': 'Overdue Product',
          'ecumenicalism': 'server amount overdue',
          'playhouses': 'Overdue',
          'spelts': 'overdue due date',
          'sandpainting': 'overdue date label',
          'berhyming': 'Repay Now',
        },
      ],
    });

    await _pumpOrdersPage(tester);
    await tester.pumpAndSettle();

    expect(apiClient.statusRequests, ['4']);
    expect(find.text('All Product'), findsOneWidget);
    expect(find.text('server amount all'), findsOneWidget);
    expect(find.text('All Status'), findsOneWidget);
    expect(find.text('all due date'), findsOneWidget);
    expect(find.text('server date label'), findsOneWidget);
    expect(find.text('All Action'), findsOneWidget);

    await tester.tap(find.text('Overdue').first);
    await tester.pumpAndSettle();

    expect(apiClient.statusRequests, ['4', '6']);
    expect(find.text('Overdue Product'), findsOneWidget);
    expect(find.text('server amount overdue'), findsOneWidget);
    expect(find.text('overdue due date'), findsOneWidget);
    expect(find.text('overdue date label'), findsOneWidget);
    expect(find.text('Repay Now'), findsOneWidget);
  });

  testWidgets('order row opens its card redirect target', (tester) async {
    apiClient.responses['4'] = Json({
      'religiosities': [
        {
          'seamounts': 42,
          'omissible': 'Redirect Product',
          'overrule': 'ph://kaibigan-loan/ios/setting',
        },
      ],
    });

    await _pumpOrdersPage(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redirect Product'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.setting);
    expect(apiClient.productApplyIds, isEmpty);
  });

  testWidgets('order row starts admission when card redirect is empty', (
    tester,
  ) async {
    await SessionStore.instance.setLoggedIn(true);
    NavigationHelper.locationAccessChecker = () async => true;
    NavigationHelper.locationReporter = () async {};
    apiClient.applyStates = {'bloomeries': 'ph://kaibigan-loan/ios/setting'};
    apiClient.responses['4'] = Json({
      'religiosities': [
        {'seamounts': 42, 'omissible': 'Admission Product'},
      ],
    });

    await _pumpOrdersPage(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admission Product'));
    await tester.pumpAndSettle();

    expect(apiClient.productApplyIds, ['42']);
    expect(Get.currentRoute, AppRoutes.setting);
  });
}

Future<void> _pumpOrdersPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    GetMaterialApp(
      home: const Scaffold(body: OrdersPage()),
      getPages: [
        GetPage(
          name: AppRoutes.setting,
          page: () => const SizedBox(key: Key('settingStub')),
        ),
      ],
    ),
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final statusRequests = <String>[];
  final responses = <String, Json>{};
  final productApplyIds = <String>[];
  Map<String, dynamic> applyStates = <String, dynamic>{};

  @override
  Future<ApiResponse> orderList({
    required String mummies,
    String dissipaters = '1',
    String bewaring = '50',
  }) async {
    statusRequests.add(mummies);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: responses[mummies] ?? Json({'religiosities': <dynamic>[]}),
    );
  }

  @override
  Future<ApiResponse> productApply({
    required String geobotanists,
    String succumbs = '0',
  }) async {
    productApplyIds.add(geobotanists);
    return ApiResponse(code: 0, message: 'success', states: Json(applyStates));
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
