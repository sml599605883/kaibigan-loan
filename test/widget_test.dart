import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_loan/main.dart';
import 'package:kaibigan_loan/src/assets/app_assets.dart';

void main() {
  testWidgets('main shell renders three GetX tabs', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KaibiganLoanApp());

    expect(find.text('Kaibigan Loan'), findsOneWidget);

    await tester.tap(find.image(const AssetImage(AppAssets.ordersNormal)));
    await tester.pumpAndSettle();

    expect(find.text('Hi! Welcome'), findsOneWidget);
    expect(find.text('All order'), findsOneWidget);
    expect(find.text('Overdue'), findsNWidgets(2));
    expect(find.text('Outstanding'), findsNWidgets(4));
    expect(find.text('Repay\nNow'), findsNWidgets(2));
    expect(find.text('Details'), findsNWidgets(2));
    expect(find.text('Loan Amount'), findsNWidgets(4));
    expect(find.text('Due Date'), findsNWidgets(4));

    await tester.tap(find.text('Overdue').first);
    await tester.pumpAndSettle();

    expect(find.text('Loan Amount'), findsOneWidget);
    expect(find.text('Repay\nNow'), findsOneWidget);
    expect(find.text('Details'), findsNothing);

    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 320));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Loan Amount'), findsOneWidget);

    await tester.tap(find.text('Settled'));
    await tester.pumpAndSettle();

    expect(find.text('Loan Amount'), findsNothing);
    expect(find.text('No orders yet'), findsOneWidget);
  });
}
