import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/core/network/api_client.dart';
import 'package:kaibigan_loan/src/core/network/api_config.dart';
import 'package:kaibigan_loan/src/modules/main/widgets/home_header.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ApiClient>(
      ApiClient(ApiConfig(webBaseUrl: 'https://h5.example.test'), dio: Dio()),
    );
  });

  tearDown(Get.reset);

  testWidgets('service image opens the personal-center customer service page', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(body: HomeHeader()),
        getPages: [
          GetPage(
            name: AppRoutes.webView,
            page: () => const SizedBox(key: Key('webViewStub')),
          ),
        ],
      ),
    );

    await tester.tap(find.image(const AssetImage(AppAssets.homeServiceIcon)));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://h5.example.test/#/OverfloodBigamously',
      'title': null,
    });
  });
}
