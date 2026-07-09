import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/main.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('main shell renders three GetX tabs', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sessionStore = SessionStore.memory();
    await sessionStore.setLoggedIn(true);
    Get.put<SessionStore>(sessionStore);
    final apiClient = _FakeApiClient();
    apiClient.orderResponses['4'] = Json({
      'religiosities': [
        {
          'omissible': 'All Product',
          'ecumenicalism': 'server amount all',
          'playhouses': 'Outstanding',
          'spelts': 'all due date',
          'sandpainting': 'server due label',
          'berhyming': 'Server Details',
        },
      ],
    });
    apiClient.orderResponses['6'] = Json({
      'religiosities': [
        {
          'omissible': 'Overdue Product',
          'ecumenicalism': 'server amount overdue',
          'playhouses': 'Overdue',
          'spelts': 'overdue due date',
          'sandpainting': 'overdue due label',
          'berhyming': 'Repay Now',
        },
      ],
    });
    apiClient.orderResponses['5'] = Json({'religiosities': <dynamic>[]});
    Get.put<ApiClient>(apiClient);

    await tester.pumpWidget(const KaibiganLoanApp());

    expect(find.text('Hi! Welcome'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);

    await tester.tap(
      find.image(const AssetImage('assets/bar/orders_normal.png')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi! Welcome'), findsOneWidget);
    expect(find.text('All order'), findsOneWidget);
    expect(apiClient.orderStatusRequests, ['4']);
    expect(find.text('All Product'), findsOneWidget);
    expect(find.text('server amount all'), findsOneWidget);
    expect(find.text('Outstanding'), findsNWidgets(2));
    expect(find.text('Server Details'), findsOneWidget);
    expect(find.text('Loan Amount'), findsOneWidget);
    expect(find.text('server due label'), findsOneWidget);

    await tester.tap(find.text('Overdue').first);
    await tester.pumpAndSettle();

    expect(apiClient.orderStatusRequests, ['4', '6']);
    expect(find.text('Overdue Product'), findsOneWidget);
    expect(find.text('server amount overdue'), findsOneWidget);
    expect(find.text('Loan Amount'), findsOneWidget);
    expect(find.text('Repay Now'), findsOneWidget);
    expect(find.text('Server Details'), findsNothing);

    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 320));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(apiClient.orderStatusRequests, ['4', '6', '6']);
    expect(find.text('Loan Amount'), findsOneWidget);

    await tester.tap(find.text('Settled'));
    await tester.pumpAndSettle();

    expect(apiClient.orderStatusRequests, ['4', '6', '6', '5']);
    expect(find.text('Loan Amount'), findsNothing);
    expect(find.text('No orders yet'), findsOneWidget);

    await tester.tap(
      find.image(const AssetImage('assets/bar/profile_normal.png')),
    );
    await tester.pumpAndSettle();

    expect(find.text('962****1300'), findsOneWidget);
    expect(find.text('All order'), findsOneWidget);
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('Settled'), findsOneWidget);
    expect(find.text('Our Service'), findsOneWidget);
    expect(find.text('Online Services'), findsOneWidget);
    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('Privacy Agreement'), findsOneWidget);

    await tester.tap(find.text('Setting'));
    await tester.pumpAndSettle();

    expect(find.text('Kaibigan Loan'), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('V1.1.1'), findsOneWidget);
    expect(find.text('Deactivate Account'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig(), dio: Dio());

  final orderStatusRequests = <String>[];
  final orderResponses = <String, Json>{};

  @override
  Future<ApiResponse> homePage() async {
    return ApiResponse(code: 0, message: 'success', states: Json(null));
  }

  @override
  Future<ApiResponse> dialog({required int loungy}) async {
    return ApiResponse(code: 0, message: 'success', states: Json(null));
  }

  @override
  Future<ApiResponse> orderList({
    required String mummies,
    String dissipaters = '1',
    String bewaring = '50',
  }) async {
    orderStatusRequests.add(mummies);
    return ApiResponse(
      code: 0,
      message: 'success',
      states: orderResponses[mummies] ?? Json({'religiosities': <dynamic>[]}),
    );
  }
}
