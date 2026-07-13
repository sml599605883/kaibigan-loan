# Certification Field Type Mapping Design

## Goal

Replace the guessed personal/work certification component types with the exact obfuscated values defined by the current `认证项组件` API mapping.

## Source of Truth

`read_api` document `值映射 → 认证项组件`:

- `Metallike` maps to original `enum`.
- `Foxfishes` maps to original `txt`.
- `Unnecessarily` maps to original `citySelect`.

The older sample values `stage`, `stepped`, and `onto` are not retained as compatibility aliases because the documented mapping supersedes those assumptions.

## Model

Add `PersonalInfoFieldType` under the certification models directory with values `text`, `enumeration`, `citySelect`, and `unknown`. `PersonalInfoField.fromJson` parses `prognosticator` once and stores the typed value instead of exposing string comparisons throughout the model.

Behavior:

- `text`: render `TextField`; submit trimmed controller text.
- `enumeration`: render the shared option picker; submit selected option value.
- `citySelect`: render the address picker; submit selected address value.
- `unknown`: do not render it as a text input or selectable field and do not include an empty value in submission.

## Verification

- Unit-test all three documented mappings and the unknown fallback.
- Update personal/work page fixtures to use the documented obfuscated values.
- Verify enum, text, and address page flows still render and submit correctly.
- Run all tests and `flutter analyze`.

## Non-goals

- No changes to field JSON keys, API endpoints, address selection behavior, or enum selection styling.
- No compatibility aliases for undocumented component types.
