# Certification Selection Sheet Height Cap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Limit the visible certification options to five rows and scroll later options without moving the action buttons.

**Architecture:** Replace the inline option children with a separated option-list widget whose height is calculated from at most five 46px rows and 15px gaps. Use a `ScrollController` to reveal an initial selection beyond the first viewport while the outer sheet and actions remain fixed.

**Tech Stack:** Flutter, `ListView.separated`, `ScrollController`, widget tests, existing screen-adapter dimensions.

---

### Task 1: Add Height and Scroll Regression Tests

**Files:**
- Modify: `test/modules/certification/certification_selection_sheet_test.dart`

- [ ] **Step 1: Write a failing six-option test**

Pump six keyed options and assert the option-list viewport height equals five rows plus four gaps:

```dart
expect(
  tester.getSize(find.byKey(const Key('certificationSelectionOptionList'))).height,
  5 * 46 + 4 * 15,
);
expect(find.byType(Scrollable), findsOneWidget);
```

Drag the list upward, tap Option 6, tap Done, and assert the returned value is `6`. Also assert the Done button remains at the same vertical position before and after scrolling.

- [ ] **Step 2: Write a failing initial-selection visibility test**

Pump six options with `initialValue: '6'`, settle the sheet, and assert the keyed sixth row is hit-testable and highlighted without a manual drag.

- [ ] **Step 3: Verify RED**

Run `flutter test test/modules/certification/certification_selection_sheet_test.dart`.

Expected: the option-list key/scrollable does not exist and the current unconstrained column displays all six rows.

### Task 2: Implement the Five-Row Scrollable Viewport

**Files:**
- Modify: `lib/src/modules/certification/widgets/certification_selection_sheet.dart`

- [ ] **Step 1: Add explicit layout constants and a controller**

Define `_maximumVisibleOptions = 5`, `_optionHeight = 46.0`, and `_optionSpacing = 15.0`. Create and dispose a `ScrollController` in the sheet state.

- [ ] **Step 2: Calculate the option viewport height**

```dart
final visibleCount = widget.options.length.clamp(0, _maximumVisibleOptions);
final listHeight = visibleCount == 0
    ? 0.0
    : visibleCount * _optionHeight.h +
        (visibleCount - 1) * _optionSpacing.h;
```

Render a keyed `SizedBox` at `listHeight` containing `ListView.separated`. Disable scrolling when there are five or fewer options; use clamping scroll physics when there are more.

- [ ] **Step 3: Reveal an off-screen initial selection**

Find the initial-value index during `initState`. After the first frame, if the index is at least five, jump the controller to `index * (46.h + 15.h)` clamped to `maxScrollExtent`. This keeps the selected row visible when the modal opens.

- [ ] **Step 4: Keep actions outside the list**

Retain the 29px gap and current Cancel/Done row after the fixed-height option viewport. No action widget belongs inside the `ListView`.

- [ ] **Step 5: Verify GREEN**

Run `flutter test test/modules/certification/certification_selection_sheet_test.dart` and require all component tests to pass.

### Task 3: Full Verification

**Files:**
- Verify the component and test files above.

- [ ] **Step 1: Format**

Run `dart format lib/src/modules/certification/widgets/certification_selection_sheet.dart test/modules/certification/certification_selection_sheet_test.dart`.

- [ ] **Step 2: Run certification regressions**

Run `flutter test test/modules/certification` and require zero failures.

- [ ] **Step 3: Run static analysis**

Run `flutter analyze` and require zero issues.

- [ ] **Step 4: Commit**

After verification, stage only the component and test files and commit with `fix: cap certification selection sheet height`.
