import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/modules/main/main_controller.dart';
import 'package:kaibigan_loan/src/modules/main/widgets/order_status_section.dart';
import 'package:kaibigan_loan/src/utils/screen_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  testWidgets('auto advances multiple order status cards every three seconds', (
    tester,
  ) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(id: 'first', amount: '1,000.00'),
      _orderItem(id: 'second', amount: '2,000.00'),
    ]);

    await _pumpSection(tester, controller);

    expect(find.text('1,000.00').hitTestable(), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('2,000.00').hitTestable(), findsOneWidget);
  });

  testWidgets('uses a finite page view for a single order status card', (
    tester,
  ) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(id: 'only', amount: '1,000.00'),
    ]);

    await _pumpSection(tester, controller);

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 1);
  });

  testWidgets('matches Lanhu order status card geometry', (tester) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(id: 'geometry', amount: '1,000.00'),
    ]);

    await _pumpSection(tester, controller);

    final carousel = find.byKey(const ValueKey('home_order_status_carousel'));
    final card = find.byKey(const ValueKey('home_order_status_card'));
    final productBadge = find.byKey(
      const ValueKey('home_order_status_product_badge'),
    );
    final amountPanel = find.byKey(
      const ValueKey('home_order_status_amount_panel'),
    );
    final datePanel = find.byKey(
      const ValueKey('home_order_status_date_panel'),
    );
    final actionBar = find.byKey(
      const ValueKey('home_order_status_action_bar'),
    );

    expect(tester.getSize(carousel), const Size(335, 154));
    expect(tester.getSize(card), const Size(335, 142));
    expect(tester.getTopLeft(card).dy - tester.getTopLeft(carousel).dy, 12);
    expect(tester.getSize(productBadge).height, 37);
    expect(tester.getSize(productBadge).width, lessThanOrEqualTo(200));
    expect(tester.getTopLeft(productBadge).dy, tester.getTopLeft(carousel).dy);
    expect(tester.getSize(amountPanel), const Size(136, 58));
    expect(tester.getSize(datePanel), const Size(136, 58));
    expect(tester.getTopLeft(amountPanel).dx - tester.getTopLeft(card).dx, 25);
    expect(
      tester.getTopLeft(datePanel).dx - tester.getTopRight(amountPanel).dx,
      14,
    );
    expect(tester.getSize(actionBar).height, 41);
  });

  testWidgets('keeps the order card 20 pixels from both screen edges', (
    tester,
  ) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(id: 'responsive', amount: '1,000.00'),
    ]);

    await _pumpSection(tester, controller, viewSize: const Size(390, 844));

    final carousel = find.byKey(const ValueKey('home_order_status_carousel'));
    final card = find.byKey(const ValueKey('home_order_status_card'));

    expect(tester.getSize(carousel).width, 350);
    expect(tester.getSize(card).width, 350);
    expect(tester.getTopLeft(card).dx, 20);
    expect(390 - tester.getTopRight(card).dx, 20);
  });

  testWidgets('limits a long product badge to 200 pixels', (tester) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(
        id: 'long-product-name',
        amount: '1,000.00',
        productName: 'A Very Long Product Name That Must Be Truncated',
      ),
    ]);

    await _pumpSection(tester, controller);

    final productBadge = find.byKey(
      const ValueKey('home_order_status_product_badge'),
    );
    expect(tester.getSize(productBadge).width, 200);
  });

  testWidgets('lets a short product badge use its content width', (
    tester,
  ) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(
        id: 'short-product-name',
        amount: '1,000.00',
        productName: 'A',
      ),
    ]);

    await _pumpSection(tester, controller);

    final productBadge = find.byKey(
      const ValueKey('home_order_status_product_badge'),
    );
    expect(tester.getSize(productBadge).width, lessThan(106));
  });

  testWidgets('repay and details actions use the order status card tap', (
    tester,
  ) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(
        id: 'order',
        amount: '1,000.00',
        actions: const [
          HomeOrderStatusAction(
            type: 'repay',
            text: 'Repay Now',
            url: 'https://h5.example.test/repay',
            visible: true,
          ),
        ],
      ),
    ]);

    await _pumpSection(tester, controller);

    await tester.tap(find.text('Repay Now'));
    await tester.pump();
    expect(controller.tappedItems.single.id, 'order');
    expect(controller.tappedActions, isEmpty);
  });

  testWidgets('retry and change actions use the button callback only', (
    tester,
  ) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(
        id: 'failed-order',
        amount: '1,000.00',
        actions: const [
          HomeOrderStatusAction(
            type: 'retry',
            text: 'Retry Original Card',
            url: '',
            visible: true,
          ),
          HomeOrderStatusAction(
            type: 'change',
            text: 'Change Account',
            url: '',
            visible: true,
          ),
        ],
      ),
    ]);

    await _pumpSection(tester, controller);

    await tester.tap(find.text('Retry Original Card'));
    await tester.pump();

    expect(controller.tappedItems, isEmpty);
    expect(controller.tappedActions.single.$1.id, 'failed-order');
    expect(controller.tappedActions.single.$2.type, 'retry');
  });

  testWidgets('unknown order action has no tap behavior', (tester) async {
    final controller = _RecordingMainController();
    controller.orderStatusItems.assignAll([
      _orderItem(
        id: 'unknown-action',
        amount: '1,000.00',
        actions: const [
          HomeOrderStatusAction(
            type: 'unknown',
            text: 'Unknown Action',
            url: '',
            visible: true,
          ),
        ],
      ),
    ]);

    await _pumpSection(tester, controller);

    await tester.tap(find.text('Unknown Action'));
    await tester.pump();

    expect(controller.tappedItems, isEmpty);
    expect(controller.tappedActions, isEmpty);
  });
}

Future<void> _pumpSection(
  WidgetTester tester,
  _RecordingMainController controller, {
  Size viewSize = const Size(375, 812),
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  Get.put<MainController>(controller);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            ScreenAdapter.init(context);
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: OrderStatusSection(),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
}

HomeOrderStatusItem _orderItem({
  required String id,
  required String amount,
  String productName = 'Kaibigan Loan',
  List<HomeOrderStatusAction> actions = const [],
}) {
  return HomeOrderStatusItem(
    id: id,
    productName: productName,
    productLogo: '',
    amount: amount,
    amountText: 'Loan Amount',
    dueDate: '2026/08/08',
    dateText: 'Due Date',
    statusText: 'Pending',
    buttonText: '',
    linkUrl: 'https://h5.example.test/order/$id',
    productId: 'product-$id',
    orderNo: 'order-$id',
    cardStatus: 1,
    actions: actions,
  );
}

class _RecordingMainController extends MainController {
  final tappedItems = <HomeOrderStatusItem>[];
  final tappedActions = <(HomeOrderStatusItem, HomeOrderStatusAction)>[];

  @override
  void onReady() {}

  @override
  Future<void> handleOrderStatusTap(HomeOrderStatusItem item) async {
    tappedItems.add(item);
  }

  @override
  Future<void> handleOrderStatusButtonTap(
    HomeOrderStatusItem item,
    HomeOrderStatusAction action,
  ) async {
    tappedActions.add((item, action));
  }
}
