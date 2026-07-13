# Certification Selection Sheet Focus Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent a text field from regaining focus after the shared certification selection sheet closes.

**Architecture:** Put focus cleanup in `showCertificationSelectionSheet` so every current and future caller gets the behavior. Release `FocusManager.instance.primaryFocus`, yield one event-loop turn, then present the modal.

**Tech Stack:** Flutter focus system, `showModalBottomSheet`, `flutter_test`.

---

### Task 1: Reproduce Focus Restoration

**Files:**
- Modify: `test/modules/certification/certification_selection_sheet_test.dart`

- [ ] **Step 1: Add a failing focus regression test**

Pump a `TextField` with an owned `FocusNode` and a button that opens the shared sheet. Focus the input, open the sheet, close it with Cancel, and assert the node remains unfocused:

```dart
await tester.tap(find.byType(TextField));
await tester.pump();
expect(focusNode.hasFocus, isTrue);

await tester.tap(find.text('Open'));
await tester.pumpAndSettle();
await tester.tap(find.text('Cancel'));
await tester.pumpAndSettle();

expect(focusNode.hasFocus, isFalse);
```

- [ ] **Step 2: Verify RED**

Run `flutter test test/modules/certification/certification_selection_sheet_test.dart --plain-name "does not restore input focus after closing"`.

Expected: the current presenter never unfocuses the input, so the final assertion fails.

### Task 2: Clean Focus in the Shared Presenter

**Files:**
- Modify: `lib/src/modules/certification/widgets/certification_selection_sheet.dart`

- [ ] **Step 1: Make the presenter asynchronous**

Change the function body to `async`, then add before `showModalBottomSheet`:

```dart
FocusManager.instance.primaryFocus?.unfocus();
await Future<void>.delayed(Duration.zero);
```

Return the awaited modal result without changing its options, styling, or generic value.

- [ ] **Step 2: Verify GREEN**

Run the focused test, then the full `certification_selection_sheet_test.dart`; require all tests to pass.

### Task 3: Verify and Commit

**Files:**
- Verify the component and test files above.

- [ ] **Step 1: Format**

Run `dart format` on both changed files.

- [ ] **Step 2: Run certification regressions**

Run `flutter test test/modules/certification` and require zero failures.

- [ ] **Step 3: Run static analysis**

Run `flutter analyze` and require zero issues.

- [ ] **Step 4: Commit**

Stage only the component and test files and commit with `fix: prevent selection sheet focus rebound`.
