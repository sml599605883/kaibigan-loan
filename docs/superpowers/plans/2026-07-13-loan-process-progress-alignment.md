# Loan Process Progress Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the home Loan Process marker and yellow fill with the center of the last unlocked loan amount card.

**Architecture:** Keep the existing `LoanProcessSection` structure and controller contract. Give the amount cards and marker stable keys for geometry testing, then use a full-width `LayoutBuilder` to calculate the selected slot center while preserving the design track inset and all existing visual tokens.

**Tech Stack:** Flutter, Dart, GetX, `flutter_test`

---

## File Structure

- Create `test/modules/main/loan_process_section_test.dart`: focused widget geometry regression tests for first, later, single, and fallback progress stages.
- Modify `lib/src/modules/main/widgets/loan_process_section.dart`: add stable test keys and replace endpoint-based progress placement with slot-center geometry.

### Task 1: Add Failing Geometry Tests

**Files:**
- Create: `test/modules/main/loan_process_section_test.dart`

- [ ] **Step 1: Write the focused widget tests**

Create the test file with a shared pump helper and center comparison helper:

```dart
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
    await _pumpLoanProcess(
      tester,
      selected: const [true, false, false, false],
    );

    _expectMarkerCenteredOnAmount(tester, 0);
  });

  testWidgets('centers marker over the last unlocked amount card', (
    tester,
  ) async {
    await _pumpLoanProcess(
      tester,
      selected: const [true, true, false, false],
    );

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
    const GetMaterialApp(
      home: Scaffold(body: LoanProcessSection()),
    ),
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
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
flutter test test/modules/main/loan_process_section_test.dart
```

Expected: FAIL because `home_loan_process_progress_marker` and `home_loan_process_amount_<index>` do not exist yet. This confirms the regression test is exercising the missing geometry contract.

- [ ] **Step 3: Commit the failing test**

```bash
git add test/modules/main/loan_process_section_test.dart
git commit -m "test: cover loan progress alignment"
```

### Task 2: Implement Slot-Center Progress Geometry

**Files:**
- Modify: `lib/src/modules/main/widgets/loan_process_section.dart:68-125`
- Modify: `lib/src/modules/main/widgets/loan_process_section.dart:159-218`

- [ ] **Step 1: Replace endpoint progress with slot-center geometry**

Inside `_LoanProcessProgress.build`, calculate the selected index and render the stack through `LayoutBuilder`. Keep the full stack width equal to the amount row width, inset only the visible track by `3.w`, and center the marker on the selected slot:

```dart
final selectedIndex = _selectedIndex(items);
return SizedBox(
  height: 16.h,
  child: LayoutBuilder(
    builder: (context, constraints) {
      final trackInset = 3.w;
      final markerSize = 16.w;
      final markerCenter =
          constraints.maxWidth * ((selectedIndex + 0.5) / items.length);
      return Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: trackInset,
            right: trackInset,
            child: Container(
              height: 7.h,
              decoration: BoxDecoration(
                color: AppColors.homeProcessTrack,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Positioned(
            left: trackInset,
            width: markerCenter - trackInset,
            child: Container(
              height: 7.h,
              decoration: BoxDecoration(
                color: AppColors.ordersYellow,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Positioned(
            key: const ValueKey('home_loan_process_progress_marker'),
            left: markerCenter - markerSize / 2,
            width: markerSize,
            height: markerSize,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.homeProcessDot,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: const BoxDecoration(
                    color: AppColors.homeProcessPanel,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  ),
);
```

Remove the old outer `Padding`, `FractionallySizedBox`, and `Align` implementation.

- [ ] **Step 2: Add stable keys to amount cards**

Change `_LoanProcessAmounts` to iterate with indexes and key each visible card container:

```dart
children: items.asMap().entries.map((entry) {
  final index = entry.key;
  final item = entry.value;
  return Expanded(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: Container(
        key: ValueKey('home_loan_process_amount_$index'),
        height: 36.h,
        decoration: BoxDecoration(
          color: item.selected
              ? AppColors.ordersYellow
              : AppColors.homeProcessTrack,
          borderRadius: BorderRadius.circular(4.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.amount,
                maxLines: 1,
                style: TextStyle(
                  color: item.selected
                      ? AppColors.ordersTitleText
                      : AppColors.tabBackground,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Loan amount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.selected
                    ? AppColors.homeProcessAmountMuted
                    : AppColors.tabBackground,
                fontSize: 8.sp,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}).toList(),
```

- [ ] **Step 3: Replace `_selectedProgress` with `_selectedIndex`**

Use the last selected item so the marker follows the final unlocked stage even if the payload marks all unlocked stages as selected:

```dart
int _selectedIndex(List<HomeLoanProcessItem> items) {
  final selectedIndex = items.lastIndexWhere((item) => item.selected);
  return selectedIndex < 0 ? 0 : selectedIndex;
}
```

- [ ] **Step 4: Format the changed files**

```bash
dart format lib/src/modules/main/widgets/loan_process_section.dart test/modules/main/loan_process_section_test.dart
```

Expected: both files are formatted without errors.

- [ ] **Step 5: Run the focused test and verify GREEN**

```bash
flutter test test/modules/main/loan_process_section_test.dart
```

Expected: all four tests PASS, proving the marker center matches the selected amount-card center.

- [ ] **Step 6: Commit the implementation**

```bash
git add lib/src/modules/main/widgets/loan_process_section.dart
git commit -m "fix: align loan progress with unlocked amount"
```

### Task 3: Regression Verification

**Files:**
- Verify: `lib/src/modules/main/widgets/loan_process_section.dart`
- Verify: `test/modules/main/loan_process_section_test.dart`
- Verify: `test/modules/main/main_controller_test.dart`

- [ ] **Step 1: Run the focused home tests serially**

```bash
flutter test test/modules/main/loan_process_section_test.dart
flutter test test/modules/main/main_controller_test.dart
```

Expected: both commands PASS with no uncaught Flutter exceptions.

- [ ] **Step 2: Run static analysis on the changed source and test**

```bash
flutter analyze lib/src/modules/main/widgets/loan_process_section.dart test/modules/main/loan_process_section_test.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Check the final diff**

```bash
git diff HEAD~2 --check
git status --short
```

Expected: no whitespace errors; only the intentionally untracked `.superpowers/` visual companion directory may remain outside the committed feature files.
