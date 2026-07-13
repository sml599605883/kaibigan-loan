# Loan Process Progress Alignment Design

## Goal

Make `_LoanProcessProgress` reflect the unlocked loan amount stage and horizontally center its marker over the last unlocked `_LoanProcessAmounts` card, matching the Lanhu design `首页-已登录未做认证项`.

## Scope

- Change only the progress geometry in `lib/src/modules/main/widgets/loan_process_section.dart`.
- Preserve the existing panel, labels, amount cards, colors, typography, spacing, and compliance logos.
- Continue using `HomeLoanProcessItem.selected` as the unlocked-stage source of truth.

## Layout Model

The progress track, labels, and amount cards share the same equal-width slots.

- The marker targets the center of the last selected slot.
- For `itemCount` items and selected index `i`, the marker center factor is `(i + 0.5) / itemCount`.
- The yellow fill starts at the track's left edge and ends at the marker center.
- The full track spans the same horizontal content width as the amount-card row.
- If no item is selected, use the first slot as the safe fallback, preserving current behavior.
- If the list contains one item, center the marker over that single slot.

## Implementation Shape

Use `LayoutBuilder` inside `_LoanProcessProgress` to convert the center factor into an exact horizontal position. Render the track, fill, and marker in the existing `Stack`; position the marker with `Positioned` so its center, rather than its left edge, lands on the selected slot center.

No runtime widget measurement, `GlobalKey`, post-frame callback, or additional controller state is needed.

## Verification

Add a widget-level regression test that renders four items and verifies:

- With only the first item selected, the marker center equals the first amount-card center.
- With the first two items selected, the marker center equals the second amount-card center.
- The behavior remains valid for a single item and for a list with no selected items.

Run the focused widget test, formatting checks, and Flutter analysis for the changed files.

## Acceptance Criteria

- The marker is horizontally centered over the last unlocked amount card at every stage.
- The yellow fill ends at the marker center.
- Locked and unlocked visual styling remains unchanged.
- No unrelated homepage behavior or layout is modified.
