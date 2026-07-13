# Certification Selection Sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give personal/work option selection the upload-method design and make that selection sheet reusable across certification flows.

**Architecture:** Add a generic certification-only modal widget and presentation helper in the existing widgets directory. Callers map domain values into immutable options; the sheet owns temporary selection state and returns only the confirmed value.

**Tech Stack:** Flutter, Dart generics, `showModalBottomSheet`, `flutter_test`, existing `AppColors`, `AppAssets`, and `ScreenAdapter` extensions.

---

## File Structure

- Create `lib/src/modules/certification/widgets/certification_selection_sheet.dart`: option model, presenter, sheet UI, option row, and action button.
- Create `test/modules/certification/certification_selection_sheet_test.dart`: isolated selection, confirmation, cancellation, initial-value, icon, and iconless tests.
- Modify `lib/src/modules/certification/certification_upload_page.dart`: map upload methods into the shared sheet and delete private duplicates.
- Modify `lib/src/modules/certification/certification_personal_info_page.dart`: map API options into the shared sheet with the current selection.
- Modify the two corresponding page tests to lock the integrations.

### Task 1: Reusable Selection Sheet

**Files:**
- Create: `test/modules/certification/certification_selection_sheet_test.dart`
- Create: `lib/src/modules/certification/widgets/certification_selection_sheet.dart`

- [ ] **Step 1: Write failing widget tests**

Pump a launcher that calls `showCertificationSelectionSheet<String>`. Assert the shared widget and keyed rows render, tapping Option B changes its decoration to `AppColors.uploadMethodSelected`, and tapping Done completes the future with `b`. Add separate cases for Cancel returning `null`, `initialValue: 'b'` starting highlighted, an icon option rendering `Image`, and iconless text rendering without `Image`.

```dart
expect(find.byType(CertificationSelectionSheet<String>), findsOneWidget);
await tester.tap(find.text('Option B'));
await tester.tap(find.text('Done'));
await tester.pumpAndSettle();
expect(result, 'b');
```

- [ ] **Step 2: Verify RED**

Run `flutter test test/modules/certification/certification_selection_sheet_test.dart`.

Expected: compilation fails because the shared types and presenter do not exist.

- [ ] **Step 3: Implement the generic contract and presenter**

```dart
class CertificationSelectionSheetOption<T> {
  const CertificationSelectionSheetOption({
    required this.value,
    required this.label,
    this.iconAsset,
    this.key,
  });

  final T value;
  final String label;
  final String? iconAsset;
  final Key? key;
}

Future<T?> showCertificationSelectionSheet<T>({
  required BuildContext context,
  required List<CertificationSelectionSheetOption<T>> options,
  T? initialValue,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: Colors.transparent,
  barrierColor: AppColors.uploadMethodBarrier,
  elevation: 0,
  isScrollControlled: true,
  builder: (_) => CertificationSelectionSheet<T>(
    options: options,
    initialValue: initialValue,
  ),
);
```

- [ ] **Step 4: Implement the shared UI**

Implement `CertificationSelectionSheet<T>` as a stateful widget. Initialize its selected value from `initialValue`. Preserve the current 15px horizontal / 13px bottom spacing, 24px white rounded container, 46px rows, selected background, 29px action gap, and Cancel/Done styles. Icon rows keep the existing 45/30/75 layout; iconless rows center the label without fake icon spacing.

- [ ] **Step 5: Verify GREEN and commit**

Run `flutter test test/modules/certification/certification_selection_sheet_test.dart`; expect all tests to pass. Then stage the two Task 1 files and commit with `feat: add reusable certification selection sheet`.

### Task 2: Personal and Work Information Integration

**Files:**
- Modify: `test/modules/certification/certification_personal_info_page_test.dart`
- Modify: `lib/src/modules/certification/certification_personal_info_page.dart`

- [ ] **Step 1: Update the page test to require styled confirmation**

After opening Gender, assert `find.byType(CertificationSelectionSheet)` plus Cancel and Done. Assert Female starts with `AppColors.uploadMethodSelected`. Tap male and verify the field still displays Female until Done is tapped, then verify male is displayed and submitted as value `1`.

- [ ] **Step 2: Verify RED**

Run `flutter test test/modules/certification/certification_personal_info_page_test.dart --plain-name "selects enum value and submits dynamic payload keys"`.

Expected: the current `ListTile` picker lacks the shared widget/action buttons and changes immediately.

- [ ] **Step 3: Replace `_selectOption` with the shared presenter**

```dart
final option = await showCertificationSelectionSheet<_PersonalInfoOption>(
  context: context,
  options: field.options
      .map((option) => CertificationSelectionSheetOption(
            value: option,
            label: option.label,
          ))
      .toList(growable: false),
  initialValue: field.selectedOption,
);
```

Add a read-only `selectedOption` getter to `_PersonalInfoField` that matches the current submitted value, or returns `null`. Keep the mounted check and `field.select(option)` update.

- [ ] **Step 4: Verify GREEN and commit**

Run `flutter test test/modules/certification/certification_personal_info_page_test.dart`; expect all personal/work tests to pass. Stage the two Task 2 files and commit with `refactor: reuse styled certification option sheet`.

### Task 3: Upload Method Integration and Cleanup

**Files:**
- Modify: `test/modules/certification/certification_upload_page_test.dart`
- Modify: `lib/src/modules/certification/certification_upload_page.dart`

- [ ] **Step 1: Require the shared sheet in the upload test**

Import the shared widget and assert `CertificationSelectionSheet<CertificationUploadMethod>` after tapping Submit. Keep the barrier, selection color, Cancel, Done, camera, and album checks.

- [ ] **Step 2: Verify RED**

Run `flutter test test/modules/certification/certification_upload_page_test.dart --plain-name "submit opens upload method sheet and confirms selected method"`.

Expected: the private `_UploadMethodSheet` renders, so the shared sheet finder fails.

- [ ] **Step 3: Map upload methods into the shared presenter**

```dart
final selectedMethod = await showCertificationSelectionSheet(
  context: context,
  options: const [
    CertificationSelectionSheetOption(
      value: CertificationUploadMethod.photoAlbum,
      label: 'Photo album',
      iconAsset: AppAssets.certificationUploadAlbum,
      key: Key('certificationUploadPhotoAlbumOption'),
    ),
    CertificationSelectionSheetOption(
      value: CertificationUploadMethod.camera,
      label: 'Photograph',
      iconAsset: AppAssets.certificationUploadCamera,
      key: Key('certificationUploadPhotographOption'),
    ),
  ],
);
```

Delete `_UploadMethodSheet`, `_UploadMethodSheetState`, `_UploadMethodOption`, and `_UploadMethodActionButton`. Preserve callback and upload sequencing.

- [ ] **Step 4: Verify GREEN and commit**

Run `flutter test test/modules/certification/certification_upload_page_test.dart`; expect all upload tests to pass. Stage the two Task 3 files and commit with `refactor: share certification upload selection sheet`.

### Task 4: Full Verification

**Files:**
- Verify every file changed in Tasks 1-3.

- [ ] **Step 1: Format changed Dart files**

Run `dart format` on the three production files and three test files listed above.

- [ ] **Step 2: Run certification tests serially**

Run `flutter test test/modules/certification` and require zero failures.

- [ ] **Step 3: Run static analysis**

Run `flutter analyze` and require zero issues.

- [ ] **Step 4: Inspect the final diff**

Run `git diff --check`, `git status --short`, and `git log -5 --oneline`. Confirm no API, navigation, security configuration, color token, or unrelated file changed.
