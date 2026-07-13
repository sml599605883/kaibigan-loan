# Certification Address Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Lanhu address sheet and wire `stage` personal/work fields to the current address API with Funny Loan interaction parity.

**Architecture:** Keep address models, UI, and page orchestration separate. The API client returns raw `ApiResponse`; certification models parse the current obfuscated keys; the shared page caches options and presents a standalone stateful address sheet.

**Tech Stack:** Flutter, Dart, Dio-backed `ApiClient`, project `Json`, `flutter_test`, Lanhu design tokens, existing `AppColors` and `ScreenAdapter`.

---

## File Structure

- Create `lib/src/modules/certification/models/address_node.dart`: recursive address node.
- Create `lib/src/modules/certification/models/address_option.dart`: root response parser.
- Create `lib/src/modules/certification/models/address_selection.dart`: returned label/value.
- Create `lib/src/modules/certification/widgets/certification_address_selection_sheet.dart`: Funny Loan state machine with Lanhu visuals and modal presenter.
- Create `test/modules/certification/certification_address_selection_sheet_test.dart`: model and widget behavior.
- Create `assets/certification_address_sheet_background.png`: semantic local copy of Lanhu `box_1.png`.
- Modify `lib/src/core/network/api_endpoints.dart`: address endpoint constant.
- Modify `lib/src/core/network/api_client.dart`: GET wrapper.
- Modify `lib/src/assets/app_assets.dart`: semantic address-sheet background constant.
- Modify `lib/src/theme/app_colors.dart`: named address-sheet tokens matching Lanhu RGBA values.
- Modify `lib/src/modules/certification/certification_personal_info_page.dart`: recognize `stage`, cache/load options, present sheet, and assign selection.
- Modify `test/modules/certification/certification_personal_info_page_test.dart`: API and form integration regressions.

### Task 1: Address Models and API Contract

**Files:**
- Create: `lib/src/modules/certification/models/address_node.dart`
- Create: `lib/src/modules/certification/models/address_option.dart`
- Create: `lib/src/modules/certification/models/address_selection.dart`
- Modify: `lib/src/core/network/api_endpoints.dart`
- Modify: `lib/src/core/network/api_client.dart`
- Test: `test/modules/certification/certification_address_selection_sheet_test.dart`

- [ ] **Step 1: Write failing parser and endpoint tests**

Construct `Json` with `religiosities`, nested `carburetor`, `griding`, and `unwits`. Assert recursive labels/ids and add a fake `ApiClient` transport assertion that `addressInit()` performs GET against `/plater/centerlines`.

```dart
final options = AddressOption.parseList(Json({
  'religiosities': [
    {
      'griding': 'region-1',
      'unwits': 'Region I',
      'carburetor': [
        {
          'griding': 'province-1',
          'unwits': 'Pangasinan',
          'carburetor': [
            {'griding': 'municipality-1', 'unwits': 'Alcala'},
          ],
        },
      ],
    },
  ],
}));
expect(options.single.children.single.children.single.label, 'Alcala');
```

- [ ] **Step 2: Verify RED**

Run `flutter test test/modules/certification/certification_address_selection_sheet_test.dart`.

Expected: address model files and `addressInit()` do not exist.

- [ ] **Step 3: Implement models**

`AddressNode.fromJson` maps `griding`, `unwits`, and recursively maps `carburetor`. `AddressOption.parseList` maps `states['religiosities']`, filters empty labels, and does not require children. `AddressSelection` exposes immutable `label` and `value`.

- [ ] **Step 4: Implement endpoint wrapper**

Add `ApiEndpoints.addressInit = '/plater/centerlines'` and:

```dart
Future<ApiResponse> addressInit() => get(ApiEndpoints.addressInit);
```

- [ ] **Step 5: Verify GREEN**

Run the new model/API tests and require them to pass.

### Task 2: Funny Loan State Machine with Lanhu Visuals

**Files:**
- Create: `assets/certification_address_sheet_background.png`
- Create: `lib/src/modules/certification/widgets/certification_address_selection_sheet.dart`
- Modify: `lib/src/assets/app_assets.dart`
- Modify: `lib/src/theme/app_colors.dart`
- Modify: `test/modules/certification/certification_address_selection_sheet_test.dart`

- [ ] **Step 1: Download and register the Lanhu background asset**

Download Lanhu `box_1.png` from the mapping returned for design `52b750f0-a30a-463c-a490-3b62a996a255`, save it as `assets/certification_address_sheet_background.png`, and register `AppAssets.certificationAddressSheetBackground`. Inspect the bitmap locally before layout work.

- [ ] **Step 2: Add failing widget behavior tests**

Cover:

- Three Done taps return `Region I-Pangasinan-Alcala`.
- A two-level branch returns after the Province Done tap.
- Returning to Region clears descendant progress.
- Cancel returns `null`.
- A new sheet starts at Region even after a previous selection.
- Opening releases input focus.

- [ ] **Step 3: Add failing Lanhu visual assertions**

At a 375×812 test surface assert:

- Modal barrier is `rgba(96,96,96,0.6)`.
- Outer horizontal spacing is 15 and bottom spacing is 13.
- Sheet width is 345 and visible design height is 393.
- Radius is 30.
- Segment active background is `rgba(72,188,255,1)` and text is `rgba(255,242,117,1)`.
- Inactive segment background is `rgba(236,236,236,1)` and text is `rgba(181,181,181,1)`.
- Selected row background is `rgba(255,242,117,1)`.
- Action buttons are 152×48 with 20 spacing, gray Cancel and blue Done.

- [ ] **Step 4: Verify RED**

Run the address-sheet test file and require the missing widget/token failures.

- [ ] **Step 5: Add theme tokens**

Add semantically named `AppColors` constants for address barrier, active/inactive segments, active/inactive segment text, row text, selected row, Cancel background/text, Done background/text, and sheet background. Reuse identical existing constants only when the RGBA value matches exactly.

- [ ] **Step 6: Implement presenter and sheet**

Add `showCertificationAddressSelectionSheet` with focus cleanup, mounted check, transparent modal background, current barrier color, elevation 0, and scroll control. Port Funny Loan's `_AddressLevel`, selected indexes, max-reached behavior, early completion, segment backtracking, and joined value logic without changing transitions.

Build the Lanhu layout with fixed constraints and list scrolling inside the content area. Use the downloaded background asset as the panel background and preserve the CSS crop/background-size behavior through a clipped `DecorationImage`; overlay the interactive segments, rows, and actions with no remote URL.

- [ ] **Step 7: Verify GREEN**

Run all address-sheet tests and require them to pass.

### Task 3: Personal and Work Page Integration

**Files:**
- Modify: `lib/src/modules/certification/certification_personal_info_page.dart`
- Modify: `test/modules/certification/certification_personal_info_page_test.dart`

- [ ] **Step 1: Add failing stage-field integration tests**

Extend the personal-info response with:

```dart
{
  'primogenitor': 'Residential Address',
  'suppletive': 'Please select address',
  'griding': 'residential_address',
  'prognosticator': 'stage',
  'hairbreadth': 0,
  'solonets': 'Old Region-Old Province-Old Municipality',
}
```

Fake `addressInit()` with recursive `religiosities`. Tap the address field, assert the sheet starts at Region rather than restoring Old Region, walk through three levels, submit, and assert `residential_address: 'Region I-Pangasinan-Alcala'`.

Add tests that reopening uses cached options and that an API failure calls `AppToast.error` without changing the field.

- [ ] **Step 2: Verify RED**

Run the focused personal-info tests. Expected: `stage` currently falls through to text input and no address API is called.

- [ ] **Step 3: Extend field behavior**

Add `usesAddressPicker => controlType == 'stage'`. Ensure `usesTextInput` excludes `stage`, enum `usesPicker` excludes address, and `_PersonalInfoFieldView` routes address and enum fields through the picker surface.

Add `selectAddress(AddressSelection)` to update visible and submitted values with the joined address.

- [ ] **Step 4: Add cached address loading**

Store `_cachedAddressOptions` and `_addressOptionsFuture`. Share the in-flight request, cache successful non-empty results, clear only the in-flight future in `finally`, and resolve failures through existing toast semantics.

- [ ] **Step 5: Present the address sheet**

In the field tap dispatcher, call `_selectAddress` for `stage` and `_selectOption` for enums. Show loading only for the first uncached request, handle empty options with the field placeholder, and assign the returned selection only when mounted.

- [ ] **Step 6: Verify GREEN**

Run all personal/work page tests and require them to pass.

### Task 4: Full Verification and Commit

**Files:**
- Verify every file changed above.

- [ ] **Step 1: Format changed Dart files**

Run `dart format` on the new models/widget/tests and modified API/theme/page files.

- [ ] **Step 2: Run certification tests serially**

Run `flutter test test/modules/certification` and require zero failures.

- [ ] **Step 3: Run static analysis**

Run `flutter analyze` and require zero issues.

- [ ] **Step 4: Fidelity audit**

Compare every Lanhu CSS size, spacing, radius, font, and color used by the sheet against the Flutter implementation. Correct any non-platform-adaptation drift.

- [ ] **Step 5: Commit focused changes**

Stage only the address selector feature files and commit with `feat: add certification address selector`.
