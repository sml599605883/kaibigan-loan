import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/modules/main/home_popup.dart';
import 'package:kaibigan_loan/src/modules/main/home_popup_data.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('upgrade popup opens documented target externally', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Uri? openedUri;
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = HomePopup.show(
      const HomePopupData(
        type: HomePopupType.appUpgrade,
        latestVersion: '2.1.0',
        content: 'Install the latest version.',
        targetUrl: 'https://store.example.test/app',
      ),
      externalOpener: (uri) async {
        openedUri = uri;
        return true;
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('New version released'), findsOneWidget);
    expect(find.text('V2.1.0'), findsOneWidget);
    expect(find.text('Install the latest version.'), findsOneWidget);
    expect(find.byKey(const Key('settingPopupBackground')), findsOneWidget);
    final backgroundRect = tester.getRect(
      find.byKey(const Key('settingPopupBackground')),
    );
    expect(backgroundRect.left, 27.5);
    expect(backgroundRect.top, 164);
    expect(backgroundRect.width, 320);
    expect(backgroundRect.height, 372);

    await tester.tap(find.byKey(HomePopup.upgradeButtonKey));
    await tester.pumpAndSettle();

    expect(await shown, isTrue);
    expect(openedUri, Uri.parse('https://store.example.test/app'));
    expect(find.byType(UpgradePopupContent), findsNothing);
  });

  testWidgets('marketing popup opens documented target in app', (tester) async {
    String? openedUrl;
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = HomePopup.show(
      const HomePopupData(
        type: HomePopupType.marketing,
        imageUrl: 'https://cdn.example.test/popup.png',
        targetUrl: 'https://h5.example.test/promotion',
      ),
      inAppOpener: (url) => openedUrl = url,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomePopup.marketingImageKey), findsOneWidget);

    tester
        .widget<GestureDetector>(find.byKey(HomePopup.marketingImageKey))
        .onTap!();
    await tester.pumpAndSettle();

    expect(await shown, isTrue);
    expect(openedUrl, 'https://h5.example.test/promotion');
    expect(find.byType(MarketingPopupContent), findsNothing);
  });

  testWidgets('unsupported popup is not shown', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = await HomePopup.show(
      const HomePopupData(type: HomePopupType.membershipUpgrade),
    );

    expect(shown, isFalse);
    expect(find.byType(UpgradePopupContent), findsNothing);
    expect(find.byType(MarketingPopupContent), findsNothing);
  });
}
