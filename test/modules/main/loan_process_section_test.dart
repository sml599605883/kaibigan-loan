import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaibigan_loan/src/modules/main/main_controller.dart';
import 'package:kaibigan_loan/src/modules/main/widgets/loan_process_section.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('centers marker over the first unlocked amount card', (
    tester,
  ) async {
    await _pumpLoanProcess(tester, selected: const [true, false, false, false]);

    _expectMarkerCenteredOnAmount(tester, 0);
  });

  testWidgets('centers marker over the last unlocked amount card', (
    tester,
  ) async {
    await _pumpLoanProcess(tester, selected: const [true, true, false, false]);

    _expectMarkerCenteredOnAmount(tester, 1);
  });

  testWidgets('centers marker for a single amount card', (tester) async {
    await _pumpLoanProcess(tester, selected: const [true]);

    _expectMarkerCenteredOnAmount(tester, 0);
  });

  testWidgets('falls back to the first amount card when none is selected', (
    tester,
  ) async {
    await _pumpLoanProcess(
      tester,
      selected: const [false, false, false, false],
    );

    _expectMarkerCenteredOnAmount(tester, 0);
  });
}

Future<void> _pumpLoanProcess(
  WidgetTester tester, {
  required List<bool> selected,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = Get.put(MainController());
  controller.loanProcessItems.assignAll(
    List.generate(
      selected.length,
      (index) => HomeLoanProcessItem(
        title: selected[index] ? 'Limit granted' : 'Verify to unlock',
        amount: '₱ ${(index + 3) * 10000}',
        selected: selected[index],
      ),
    ),
  );

  await tester.pumpWidget(
    const GetMaterialApp(home: Scaffold(body: LoanProcessSection())),
  );
  await tester.pump();
}

void _expectMarkerCenteredOnAmount(WidgetTester tester, int index) {
  final markerCenter = tester.getCenter(
    find.byKey(const ValueKey('home_loan_process_progress_marker')),
  );
  final amountCenter = tester.getCenter(
    find.byKey(ValueKey('home_loan_process_amount_$index')),
  );

  expect(markerCenter.dx, closeTo(amountCenter.dx, 0.01));
}
