import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/main.dart';
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

    await tester.pumpWidget(const KaibiganLoanApp());

    expect(find.text('Hi! Welcome'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);

    await tester.tap(
      find.image(const AssetImage('assets/bar/orders_normal.png')),
    );
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
