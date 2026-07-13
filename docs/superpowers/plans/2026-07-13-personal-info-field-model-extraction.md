# Personal Info Field Model Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Match Funny Loan's personal-field display/submission semantics and move page-private field models into independent files.

**Architecture:** `PersonalInfoField` becomes the single owner of its controller, displayed label, submitted value, and disposal. The page orchestrates API/UI only and no longer mirrors field state in a controller map.

**Tech Stack:** Flutter `TextEditingController`, project `Json`, existing address models, `flutter_test`.

---

## File Structure

- Create `lib/src/modules/certification/models/personal_info_option.dart`: enum label/value model.
- Create `lib/src/modules/certification/models/personal_info_field.dart`: field parsing, type flags, controller, display/submit state, selection methods, disposal.
- Create `test/modules/certification/personal_info_field_test.dart`: isolated model semantics.
- Modify `lib/src/modules/certification/certification_personal_info_page.dart`: consume public models and remove page-owned controllers/private models.
- Modify `test/modules/certification/certification_personal_info_page_test.dart`: regression coverage for distinct address label/value behavior.
- Modify `.gitignore`: ignore the root `.superpowers/` directory.
- Untrack `.superpowers/specs/*` while preserving local files.

### Task 1: Lock Funny Loan Display and Submit Semantics

**Files:**
- Create: `test/modules/certification/personal_info_field_test.dart`

- [ ] **Step 1: Write failing address semantics test**

Parse a `stage` field, call:

```dart
field.selectAddress(
  const AddressSelection(
    label: 'Region I / Pangasinan / Alcala',
    value: 'Region I-Pangasinan-Alcala',
  ),
);
```

Assert `field.displayText` is the slash-separated label while `field.currentSubmitValue` is the hyphen-separated value.

- [ ] **Step 2: Write failing enum and text tests**

Assert enum selection writes option label to the controller and option value to submission. Assert text input submission reads trimmed controller text. Assert `displayText` falls back to placeholder when the controller is empty.

- [ ] **Step 3: Verify RED**

Run `flutter test test/modules/certification/personal_info_field_test.dart`.

Expected: the independent models do not exist.

### Task 2: Extract and Implement Models

**Files:**
- Create: `lib/src/modules/certification/models/personal_info_option.dart`
- Create: `lib/src/modules/certification/models/personal_info_field.dart`

- [ ] **Step 1: Implement `PersonalInfoOption`**

Map Kaibigan fields `unwits` to label and `commensurate` to value. Preserve empty-value string conversion behavior from the existing private model.

- [ ] **Step 2: Implement `PersonalInfoField`**

Map existing keys and create one controller initialized with matched enum label or the raw `solonets` value. Expose:

```dart
bool get usesAddressPicker;
bool get usesPicker;
bool get usesTextInput;
String get displayText;
String get currentSubmitValue;
PersonalInfoOption? get selectedOption;
void selectOption(PersonalInfoOption option);
void selectAddress(AddressSelection selection);
void dispose();
```

The display/submit behavior must match Funny Loan: controller text is display, selected value is submit for selectable fields.

- [ ] **Step 3: Verify GREEN**

Run the model test file and require all tests to pass.

### Task 3: Migrate the Shared Personal/Work Page

**Files:**
- Modify: `lib/src/modules/certification/certification_personal_info_page.dart`
- Modify: `test/modules/certification/certification_personal_info_page_test.dart`

- [ ] **Step 1: Add page regression for model-backed display/submission**

Keep the isolated model test as the proof for distinct address label/value. In the page test, assert picker UI reads the model's `displayText` and submission reads `currentSubmitValue` without adding a production-only injection seam.

- [ ] **Step 2: Verify RED**

Run the model regression. Expected: the current page-private field model is unavailable to the test and its `selectAddress` behavior cannot satisfy the public display/submit contract.

- [ ] **Step 3: Replace private models and controller map**

Import the two public model files. Change `_fields` to `List<PersonalInfoField>`. Remove `_controllers`, `_syncControllers`, `_PersonalInfoField`, and `_PersonalInfoOption`. Pass `field.controller` to text inputs, use `field.displayText` in picker UI, and use `field.currentSubmitValue` during submit.

- [ ] **Step 4: Own disposal in the model**

Before replacing `_fields` after a reload/error, dispose the previous fields. In page `dispose()`, dispose every current field. Avoid disposing freshly parsed fields when the page becomes unmounted before assignment.

- [ ] **Step 5: Update selector generics and method signatures**

Use `PersonalInfoOption` in `showCertificationSelectionSheet`, call `field.selectOption`, and retain all current address/API caching behavior.

- [ ] **Step 6: Verify GREEN**

Run `flutter test test/modules/certification/certification_personal_info_page_test.dart` and require all tests to pass.

### Task 4: Full Verification and Commit

**Files:**
- Verify all changed files above.

- [ ] **Step 1: Format**

Run `dart format` on new models/tests and the modified page/test.

- [ ] **Step 2: Run all tests**

Run `flutter test` and require zero failures.

- [ ] **Step 3: Run static analysis**

Run `flutter analyze` and require zero issues.

- [ ] **Step 4: Inspect diff and commit**

Confirm the private model/controller-map code is removed and no unrelated file changed. Commit with `refactor: extract personal info field model`.

### Task 5: Ignore Local Superpowers Specifications

**Files:**
- Modify: `.gitignore`
- Untrack: `.superpowers/specs/2026-07-13-certification-address-selection-design.md`
- Untrack: `.superpowers/specs/2026-07-13-certification-selection-sheet-design.md`

- [ ] **Step 1: Add the root ignore rule**

Add `/.superpowers/` to `.gitignore`. Do not ignore `docs/superpowers/`.

- [ ] **Step 2: Remove tracked specifications from the Git index only**

Run `git rm --cached` for the tracked `.superpowers` files. Confirm the files still exist locally and `git check-ignore -v .superpowers/specs/...` reports the new rule.

- [ ] **Step 3: Include the ignore cleanup in the focused commit**

Stage `.gitignore` and the index removals with the model refactor. Do not delete local `.superpowers` content.
