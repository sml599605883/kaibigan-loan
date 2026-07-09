import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/modules/orders/orders_page.dart';

void main() {
  late _FakeApiClient apiClient;

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    Get.put<ApiClient>(apiClient);
  });

  tearDown(Get.reset);

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
}

Future<void> _pumpOrdersPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const GetMaterialApp(home: Scaffold(body: OrdersPage())),
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final statusRequests = <String>[];
  final responses = <String, Json>{};

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
}
