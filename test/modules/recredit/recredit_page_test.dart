import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';
import 'package:kaibigan_loan/src/modules/recredit/recredit_page.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('renders the 375x812 recredit design and reuses its assets', (
    tester,
  ) async {
    await _pumpPage(tester, const RecreditPage(), topPadding: 44);

    expect(find.byKey(const Key('recredit_return_button')), findsOneWidget);
    expect(find.byKey(const Key('recredit_illustration')), findsOneWidget);
    expect(find.byKey(const Key('recredit_progress_bar')), findsOneWidget);
    expect(find.byKey(const Key('recredit_status_icon')), findsOneWidget);
    expect(
      find.byKey(const Key('recredit_progress_label_container')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Calculating your credit limit, just 30 seconds',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Estimate time'), findsNothing);
    expect(find.text('Please wait patiently'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    expect(
      tester.getSize(find.byKey(const Key('recredit_illustration'))),
      const Size(192, 154),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('recredit_illustration'))).dy,
      closeTo(204, 1),
    );
    expect(
      tester.getSize(find.byKey(const Key('recredit_progress_bar'))),
      const Size(308, 7),
    );
    final returnSize = tester.getSize(
      find.byKey(const Key('recredit_return_button')),
    );
    expect(returnSize.width, greaterThanOrEqualTo(44));
    expect(returnSize.height, greaterThanOrEqualTo(44));

    final returnTopLeft = tester.getTopLeft(
      find.byKey(const Key('recredit_return_button')),
    );
    expect(returnTopLeft.dx, lessThan(80));
    expect(returnTopLeft.dy, lessThan(100));

    final illustration = tester.widget<Image>(
      find.byKey(const Key('recredit_illustration')),
    );
    final illustrationProvider = illustration.image as AssetImage;
    expect(illustrationProvider.assetName, AppAssets.recreditIllustration);

    final marker = tester.widget<Image>(
      find.byKey(const Key('recredit_status_icon')),
    );
    final markerProvider = marker.image as AssetImage;
    expect(markerProvider.assetName, AppAssets.loginAgreementIndicator);
  });

  testWidgets('keeps exact vertical content spacing with a 44px top inset', (
    tester,
  ) async {
    await _pumpPage(tester, const RecreditPage(), topPadding: 44);

    final illustrationRect = tester.getRect(
      find.byKey(const Key('recredit_illustration')),
    );
    final firstLineRect = tester.getRect(
      find.text(
        'Calculating your credit limit, just 30 seconds',
        findRichText: true,
      ),
    );
    final secondLineRect = tester.getRect(find.text('Please wait patiently'));
    final progressSectionRect = tester.getRect(
      find.byKey(const Key('recredit_progress_section')),
    );

    expect(firstLineRect.top - illustrationRect.bottom, closeTo(18, 1));
    expect(secondLineRect.top, closeTo(firstLineRect.bottom, 1));
    expect(progressSectionRect.top - secondLineRect.bottom, closeTo(28, 1));
  });

  testWidgets('keeps illustration at design top without a safe inset', (
    tester,
  ) async {
    await _pumpPage(tester, const RecreditPage());

    expect(
      tester.getTopLeft(find.byKey(const Key('recredit_illustration'))).dy,
      closeTo(204, 1),
    );
  });

  testWidgets('return button exposes accessible back semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpPage(tester, const RecreditPage());

    final back = find.bySemanticsLabel('Back');
    expect(back, findsOneWidget);
    expect(
      tester.getSemantics(back),
      matchesSemantics(label: 'Back', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('320x568 layout remains safe and scrollable', (tester) async {
    await _pumpPage(tester, const RecreditPage(), size: const Size(320, 568));

    expect(tester.takeException(), isNull);
    final returnSize = tester.getSize(
      find.byKey(const Key('recredit_return_button')),
    );
    expect(returnSize.width, greaterThanOrEqualTo(44));
    expect(returnSize.height, greaterThanOrEqualTo(44));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('return button pops to the existing home route', (tester) async {
    await _setViewSize(tester);
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/home',
        getPages: [
          GetPage(
            name: '/home',
            page: () => const SizedBox(key: Key('home_stub')),
          ),
          GetPage(name: '/recredit', page: () => const RecreditPage()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    Get.toNamed<void>('/recredit');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('recredit_return_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('home_stub')), findsOneWidget);
    expect(Get.currentRoute, '/home');
  });

  testWidgets('perceived progress advances deterministically and caps at 99', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      RecreditPage(
        progressDelayGenerator: () => const Duration(seconds: 1),
        progressIncrementGenerator: (_) => 50,
      ),
    );

    expect(find.text('0%'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('50%'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('99%'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('99%'), findsOneWidget);
  });

  testWidgets('starts recredit with trimmed nested cohabiter argument', (
    tester,
  ) async {
    final startedProductIds = <String>[];
    await _pumpNamedPage(
      tester,
      arguments: const {
        'payload': {'cohabiter': ' product-2 '},
      },
      page: RecreditPage(onStartRecredit: startedProductIds.add),
    );

    expect(startedProductIds, ['product-2']);
  });

  testWidgets('empty arguments do not start recredit', (tester) async {
    final startedProductIds = <String>[];
    await _pumpNamedPage(
      tester,
      page: RecreditPage(onStartRecredit: startedProductIds.add),
    );

    expect(startedProductIds, isEmpty);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(375, 812),
  double topPadding = 0,
}) async {
  await _setViewSize(tester, size: size);
  await tester.pumpWidget(
    GetMaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: EdgeInsets.only(top: topPadding)),
          child: child!,
        );
      },
      home: page,
    ),
  );
  await tester.pump();
}

Future<void> _pumpNamedPage(
  WidgetTester tester, {
  required RecreditPage page,
  Object? arguments,
}) async {
  await _setViewSize(tester);
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => const SizedBox()),
        GetPage(name: '/recredit', page: () => page),
      ],
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed<void>('/recredit', arguments: arguments);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _setViewSize(
  WidgetTester tester, {
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
