import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/app_routes.dart';
import 'package:kaibigan_loan/src/modules/profile/profile_page.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

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
      ],
    ),
  );
  await tester.pumpAndSettle();
}
