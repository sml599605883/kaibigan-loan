# Certification Address Selection Design

## Goal

Add the Lanhu-designed address selector to Kaibigan Loan while preserving the Funny Loan address-selection state machine exactly and adapting only the API contract and theme tokens to this project.

## Sources of Truth

- Visual: Lanhu design `52b750f0-a30a-463c-a490-3b62a996a255` (`日期选择备份`).
- Interaction: Funny Loan `AddressSelectionSheet`.
- Data: Kaibigan Loan `GET /plater/centerlines` and personal/work field type `prognosticator == "stage"`.

## Component Boundary

Create a standalone `CertificationAddressSelectionSheet`; do not add address-specific behavior to `CertificationSelectionSheet<T>`. Add independent `AddressNode`, `AddressOption`, and `AddressSelection` models under the certification module.

The personal/work page remains responsible for loading, caching, error presentation, field assignment, and API submission. The sheet receives parsed options and returns a completed selection.

## Interaction

- Start at Region with the first option selected.
- Done advances Region to Province, then Province to Municipality, then returns the selection.
- If the selected branch has no children at the next level, Done returns the deepest available path immediately.
- Reached segments are tappable. Returning to Region clears Province and Municipality progress; returning to Province clears Municipality progress.
- Changing a parent resets all descendant indexes.
- Cancel dismisses with `null`.
- Every new sheet starts at Region and does not parse or recall the field's current value.
- Before presentation, release primary focus and yield one event-loop turn so closing the sheet cannot restore an input focus.

## Returned Value

Both `AddressSelection.label` and `AddressSelection.value` contain the selected labels joined with `-`, matching the current API example `Region I-Pangasinan-Alcala`.

## Data Contract

Add `ApiEndpoints.addressInit = "/plater/centerlines"` and `ApiClient.addressInit()` as a GET request.

Parse response state `religiosities` as root options:

- `griding`: node id/code.
- `unwits`: visible label.
- `carburetor`: child nodes, parsed recursively when present.
- `propine`: optional parent code on child nodes; no submission dependency.

Filter empty labels. Preserve a non-empty root even when it has no children so the component supports the three-level UI when the live response contains nested children. If a response branch contains only two levels, the unchanged Funny Loan early-completion behavior returns two joined labels.

## Page Integration

In the shared personal/work information page:

- Treat `controlType == 'stage'` as an address picker, not a text field or enum picker.
- Cache the parsed address options after the first successful request and share an in-flight request to avoid duplicate calls.
- Show loading only for the first uncached request.
- On empty data, show the field placeholder as an error and keep the form unchanged.
- On API failure, resolve the error through the existing `ApiErrorMessage` and `AppToast.error` path.
- On selection, set both visible text and submitted value to the returned joined address.
- Preserve all existing personal/work load, save, validation, and route behavior.

## Personal Information Field Model

Move the page-private field types into independent certification model files:

- `PersonalInfoField` owns its `TextEditingController`, selected submit value, type flags, and lifecycle.
- `PersonalInfoOption` owns enum label/value parsing.
- `displayText` reads the trimmed controller text and falls back to the field placeholder.
- `currentSubmitValue` returns controller text for text fields and the separate selected value for enum/address fields.
- `selectOption()` writes the option label to `controller.text` and the option value to `selectedValue`.
- `selectAddress()` writes `AddressSelection.label` to `controller.text` and `AddressSelection.value` to `selectedValue`, matching Funny Loan display behavior exactly.
- The page removes its controller map and controller synchronization method. It renders `field.controller`, submits `field.currentSubmitValue`, and disposes every field when replacing the list or disposing the page.
- Keep Kaibigan Loan's documented JSON keys and control types (`onto`, `txt`, `stepped`, `enum`, `stage`); only state ownership and display/submit semantics change.

## Verification

- Model tests cover current-project field mapping and recursive children.
- Widget tests cover three-level advancement, segment backtracking, early completion, Cancel, Lanhu colors/sizes, and no reopen-state recall.
- Page tests cover `stage` routing, one cached API request, selected address submission, request failure, and focus cleanup.
- Model tests cover distinct address label/value display and submission, enum label/value separation, and controller disposal ownership.
- Run certification tests serially and run `flutter analyze`.

## Non-goals

- No changes to non-address enum selectors.
- No changes to API field names beyond the documented address endpoint.
- No default address restoration.
- No changes to unrelated certification pages or navigation.
