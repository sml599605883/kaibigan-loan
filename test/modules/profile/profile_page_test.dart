import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/core/session/session_store.dart';
import 'package:kaibigan_loan/src/modules/profile/profile_page.dart';

void main() {
  late SessionStore sessionStore;

  setUp(() async {
    Get.testMode = true;
    sessionStore = SessionStore.memory();
    Get.put<SessionStore>(sessionStore);
  });

  tearDown(Get.reset);

  testWidgets('shows the cached phone number with the middle masked', (
    tester,
  ) async {
    await sessionStore.savePhone('09175551234');

    await _pumpProfileWithRoutes(tester);

    expect(find.text('091***1234'), findsOneWidget);
    expect(find.text('09175551234'), findsNothing);
  });

  testWidgets('order shortcuts open mine order list with matching tab', (
    tester,
  ) async {
    await _pumpProfileWithRoutes(tester);

    await tester.tap(find.text('All order'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.mineOrderList);
    expect(Get.arguments, {'initialStatus': '4'});

    Get.back<void>();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Outstanding'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.mineOrderList);
    expect(Get.arguments, {'initialStatus': '7'});

    Get.back<void>();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settled'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.mineOrderList);
    expect(Get.arguments, {'initialStatus': '5'});
  });

  testWidgets('online services opens configured web page', (tester) async {
    Get.put<ApiClient>(
      ApiClient(
        ApiConfig(webBaseUrl: 'https://h5.example.test'),
        dio: Dio(),
      ),
    );
    await _pumpProfileWithRoutes(tester);

    await tester.tap(find.text('Online Services'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://h5.example.test/#/OverfloodBigamously',
      'title': null,
    });
  });

  testWidgets('privacy agreement opens configured web page', (tester) async {
    Get.put<ApiClient>(
      ApiClient(
        ApiConfig(webBaseUrl: 'https://h5.example.test'),
        dio: Dio(),
      ),
    );
    await _pumpProfileWithRoutes(tester);

    await tester.tap(find.text('Privacy Agreement'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://h5.example.test/#/Pastitsios',
      'title': null,
    });
  });
}

Future<void> _pumpProfileWithRoutes(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.main,
      getPages: [
        GetPage(name: AppRoutes.main, page: () => const ProfilePage()),
        GetPage(
          name: AppRoutes.mineOrderList,
          page: () => const SizedBox(key: Key('mineOrderListStub')),
        ),
        GetPage(
          name: AppRoutes.webView,
          page: () => const SizedBox(key: Key('webViewStub')),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}
