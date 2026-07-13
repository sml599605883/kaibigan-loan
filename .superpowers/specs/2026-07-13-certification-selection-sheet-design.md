# Certification Selection Sheet Design

## Goal

Replace the unstyled personal/work information option picker with the same visual and interaction pattern used by the upload-method sheet, while keeping one reusable implementation for future certification selectors.

## Scope

- Add a reusable generic `CertificationSelectionSheet<T>` under `lib/src/modules/certification/widgets/`.
- Move the upload-method sheet onto the shared component.
- Move personal/work information option selection onto the shared component.
- Preserve the existing field models, API payloads, image-picking flow, and upload behavior.

## Component Contract

Each `CertificationSelectionSheetOption<T>` contains:

- `value`: the business value returned to the caller.
- `label`: the visible option text.
- `iconAsset`: an optional asset path used by upload choices.
- `key`: an optional test/interaction key.

The sheet accepts a list of options and an optional initial value. It owns only temporary selection state. Selecting a row updates its highlight; `Done` returns the selected value; `Cancel`, swipe dismissal, or barrier dismissal returns `null`.

## Visual Behavior

- Use the existing transparent modal background, barrier color, elevation, spacing, white rounded container, selected-row background, typography, and action-button colors from `_UploadMethodSheet`.
- Options with icons preserve the upload layout.
- Options without icons render centered text while retaining the same row height and selected background.
- The personal/work picker initializes its selected row from the field's current selected value when available.
- The upload picker remains initially unselected.

## Option List Height

- Show up to five option rows at once.
- For one through five options, size the option area to its content.
- For more than five options, constrain the option area to five 46px rows and four 15px gaps.
- Scroll only the option area; keep the Cancel and Done actions fixed below it.
- When the initial selection is beyond the first five options, reveal it automatically when the sheet opens.

## Integration

- Expose one shared helper for presenting the modal so every caller receives identical modal configuration.
- `certification_upload_page.dart` maps the two upload methods to icon options and removes its private sheet/row/button widgets.
- `certification_personal_info_page.dart` maps `_PersonalInfoOption` values into shared options and keeps the existing `field.select(...)` update after confirmation.

## Verification

- Widget-test the shared sheet's selection highlight, `Done` result, `Cancel` result, and iconless layout.
- Widget-test the five-row height cap, scrolling to later options, and initial-selection visibility.
- Update page tests to verify the personal/work selector uses the styled shared sheet and preserves the selected field value.
- Run focused certification tests, formatting, and Flutter static analysis.

## Non-goals

- No changes to certification APIs, route flow, field parsing, upload permission handling, or unrelated UI.
- No new colors or third-party dependencies.
