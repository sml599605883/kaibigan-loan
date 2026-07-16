import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/core/json/json.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/network/api_response.dart';
import 'package:kaibigan_loan/src/modules/widgets/retention_popup.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shows server retention popup and wires both actions', (
    tester,
  ) async {
    var exitCount = 0;
    final apiClient = _FakeApiClient(
      states: {
        'misaligned': {
          'bloomeries': 'https://example.test/retention.png',
          'ensanguine': 'Leave',
          'sleeved': 'Stay',
        },
      },
    );
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = RetentionPopup.show(
      type: ' 2 ',
      productId: ' product-1 ',
      onExit: () => exitCount++,
      apiClient: apiClient,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(apiClient.requests, [
      {'bellyache': '2', 'seamounts': 'product-1'},
    ]);
    expect(find.byType(RetentionPopupContent), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
    expect(find.text('Stay'), findsOneWidget);

    await tester.tap(find.byKey(RetentionPopup.continueButtonKey));
    await tester.pumpAndSettle();

    expect(await shown, isTrue);
    expect(exitCount, 0);

    final shownAgain = RetentionPopup.show(
      type: '2',
      productId: 'product-1',
      onExit: () => exitCount++,
      apiClient: apiClient,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(RetentionPopup.exitButtonKey));
    await tester.pumpAndSettle();

    expect(await shownAgain, isTrue);
    expect(exitCount, 1);
  });

  testWidgets('returns false when retention image is unavailable', (
    tester,
  ) async {
    final apiClient = _FakeApiClient(states: const {'misaligned': {}});
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = await RetentionPopup.show(
      type: '0',
      productId: 'product-1',
      onExit: () {},
      apiClient: apiClient,
    );

    expect(shown, isFalse);
    expect(find.byType(RetentionPopupContent), findsNothing);
  });

  testWidgets('returns false when retention request fails', (tester) async {
    final apiClient = _FakeApiClient(error: StateError('request failed'));
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = await RetentionPopup.show(
      type: '0',
      productId: 'product-1',
      onExit: () {},
      apiClient: apiClient,
    );

    expect(shown, isFalse);
    expect(find.byType(RetentionPopupContent), findsNothing);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.states = const {}, this.error})
    : super(ApiConfig(), dio: Dio());

  final Map<String, dynamic> states;
  final Object? error;
  final requests = <Map<String, String>>[];

  @override
  Future<ApiResponse> retainPopup({
    required String bellyache,
    required String seamounts,
  }) async {
    requests.add({'bellyache': bellyache, 'seamounts': seamounts});
    if (error != null) {
      throw error!;
    }
    return ApiResponse(code: 0, message: 'success', states: Json(states));
  }
}
