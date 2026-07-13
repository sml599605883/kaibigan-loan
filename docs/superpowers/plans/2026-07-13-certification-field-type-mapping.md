# Certification Field Type Mapping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Parse certification fields using the documented obfuscated component types only.

**Architecture:** Add a small typed enum parser and make `PersonalInfoField` derive all UI flags from it. Tests and fixtures use the exact API mapping values.

**Tech Stack:** Dart enum, project `Json`, Flutter widget tests.

---

### Task 1: Add Typed Mapping Tests

**Files:**
- Create: `lib/src/modules/certification/models/personal_info_field_type.dart`
- Modify: `test/modules/certification/personal_info_field_test.dart`

- [ ] **Step 1: Write failing mapping tests**

Assert:

```dart
expect(PersonalInfoFieldType.fromRaw('Metallike'), PersonalInfoFieldType.enumeration);
expect(PersonalInfoFieldType.fromRaw('Foxfishes'), PersonalInfoFieldType.text);
expect(PersonalInfoFieldType.fromRaw('Unnecessarily'), PersonalInfoFieldType.citySelect);
expect(PersonalInfoFieldType.fromRaw('stage'), PersonalInfoFieldType.unknown);
```

- [ ] **Step 2: Verify RED**

Run `flutter test test/modules/certification/personal_info_field_test.dart` and require failure because the type model does not exist.

- [ ] **Step 3: Implement the enum parser**

Add `text`, `enumeration`, `citySelect`, and `unknown`; map only the three documented obfuscated values.

- [ ] **Step 4: Verify GREEN**

Run the model tests and require them to pass.

### Task 2: Migrate PersonalInfoField and Page Fixtures

**Files:**
- Modify: `lib/src/modules/certification/models/personal_info_field.dart`
- Modify: `test/modules/certification/personal_info_field_test.dart`
- Modify: `test/modules/certification/certification_personal_info_page_test.dart`

- [ ] **Step 1: Add failing behavior assertions**

Construct fields using `Metallike`, `Foxfishes`, and `Unnecessarily`; assert the correct picker/input flags. Construct an old `stage` field and assert all supported flags are false.

- [ ] **Step 2: Verify RED**

Run the model tests. Expected: current string comparisons do not recognize the documented values.

- [ ] **Step 3: Store the typed field type**

Replace `controlType: String` with `fieldType: PersonalInfoFieldType`, parse `prognosticator` in `fromJson`, and implement flags through enum equality.

- [ ] **Step 4: Update page fixtures**

Replace:

- `stepped` with `Metallike`.
- `onto` with `Foxfishes`.
- `stage` with `Unnecessarily`.

Do not keep tests for undocumented aliases except the explicit unknown fallback unit test.

- [ ] **Step 5: Verify page behavior**

Run personal/work page tests and require enum, text, and address flows to pass.

### Task 3: Full Verification and Commit

**Files:**
- Verify all files above.

- [ ] **Step 1: Format changed Dart files**

Run `dart format` on the type model, field model, and changed tests.

- [ ] **Step 2: Run all tests**

Run `flutter test` and require zero failures.

- [ ] **Step 3: Run static analysis**

Run `flutter analyze` and require zero issues.

- [ ] **Step 4: Commit**

Inspect the diff and commit with `fix: use documented certification field types`.
