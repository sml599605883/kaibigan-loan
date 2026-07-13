# Bind Card Page Design

## Goal

Add the Kaibigan Loan bind-card certification page. Match the Lanhu design named `认证-绑定电子钱包`, follow the proven Funny Loan interaction flow, and use only Kaibigan Loan's local API documentation and field mappings for data contracts.

## Scope

The feature includes the normal fifth certification step, dynamic payment-method groups, documented field validation, bind submission, required liveness handling, risk reporting, and continuation of the product-detail flow.

The existing H5 `changeAccount` action remains unavailable. This task does not add or change the account-replacement flow.

## Sources Of Truth

- Visual specification: local Lanhu project `Kaibigan Loan`, design `认证-绑定电子钱包`.
- API behavior: `read_api` prefix `ph_kaibigan_loan_ios`.
- Endpoint and field mapping: `project_docs/kaibigan_loan_ios.php` and `project_docs/kaibigan_loan_ios-fields_map.php`.
- Interaction reference only: Funny Loan bind-card page. Funny Loan request keys and response keys must not be copied.

## Architecture

Create a focused bind-card model and a stateful certification page under the existing certification module. The model owns parsing and normalizing the server-driven form schema. The page owns loading, group-local form state, validation, selection, submission, liveness orchestration, and rendering. `ApiClient` remains responsible for endpoint calls and generated protocol fields.

Register a dedicated bind-card route and connect both product-detail next-step values `bank` and `CocoShorting` to it. The route carries the normalized product ID as `geobotanists`.

## Data Model

Load the form with `GET /plater/cabdrivers` using:

- `geobotanists`: product ID as `String`.
- `flowerers`: generated protocol field as `String`.
- `multivariate`: generated protocol field as `String`.

Parse `fas.enthrones` as the payment-method group list:

- `primogenitor`: group label.
- `commensurate`: card type, normalized to `String` even when the response contains a number.
- nested `enthrones`: dynamic fields for that group.

Parse each dynamic field as:

- `primogenitor`: field label.
- `griding`: semantic submit key.
- `suppletive`: placeholder and validation message.
- `prognosticator`: `enum` or `txt` control type.
- `metallurgists`: enum choices.
- `hairbreadth`: `1` means optional; all other values mean required.
- `solonets` and `whackers`: initial display/value data when present.

Parse enum choices as:

- `commensurate`: submitted value, always normalized to `String`.
- `unwits`: displayed name.
- `vocalically`: remote business logo URL.
- `bondmen`: maintenance status. Maintenance does not prevent selection, matching the API contract.

Only render groups returned by the API with valid fields. Do not hardcode Cash Pickup. If the server later returns it, the same model and UI render it automatically.

Each group keeps its own input and selection state while the user switches tabs. Invalid groups, fields without labels or submit keys, and invalid enum choices are ignored without crashing.

## Visual Design

Implement the Lanhu layout at the 375 x 812 reference size using the existing `ScreenAdapter` conventions:

- Existing certification header and prompt-banner visual language.
- Server-provided top message from `fas.mourningly`.
- Payment-method tabs generated from the returned groups.
- Labels and 40-pixel-high rounded field containers.
- Enum fields open the existing certification selection-sheet style and show the option name and business logo.
- Server-provided footer message from `fas.pollywogs`.
- Fixed bottom submit area with duplicate-submit protection.

Rename `assets/编组 3@3x.png` to `assets/certification_bind_card_progress.png`, expose it through `AppAssets`, and use it for the progress image. Do not download or duplicate this asset.

Add required colors to `AppColors`. The page must not contain hardcoded hexadecimal color literals. Preserve the exact Lanhu RGBA values when adding tokens.

The layout must remain usable on narrow screens and with larger text. Content may scroll, while the footer remains stable and fields, labels, and buttons must not overlap or resize unexpectedly.

## Submission

Before submitting:

1. Require all fields except those with `hairbreadth == 1`.
2. Compare `cardNo` and `confirmCardNo` exactly when both fields exist.
3. Ignore a second submit while a request is active.

Submit `POST /plater/bloomeries` with string values:

- `geobotanists`: product ID.
- `heirship`: selected group card type.
- `bladers`: `channelCode`.
- `zips`: `firstName`.
- `acreage`: `middleName` when provided.
- `coinable`: `lastName`.
- `flabby`: `cardNo`.
- `rapt`: `confirmCardNo`.
- `jills`: generated protocol field.

The page uses the server field's semantic `griding` value and a Kaibigan Loan mapping to obtain the documented obfuscated submit key. Only `channelCode`, `firstName`, `middleName`, `lastName`, `cardNo`, and `confirmCardNo` are submitted. Unknown keys are omitted, and Funny Loan mappings are never used.

On normal success, report risk scene `8` with the product ID and cached order number, then call `NavigationHelper.continueProductDetailFlow(productId)`.

## Liveness Flow

Treat response code `20000` as liveness required, not as final success.

1. Read the order number from the current product-detail cache.
2. If it is empty, stop and show an explicit error.
3. Call `POST /plater/viruliferous` with `dodgy` set to the order number and `commensurate` set to `'1'`; generated protocol fields remain owned by `ApiClient`.
4. Require result code `200`, non-empty license, and face type `7`.
5. Launch the existing TrustDecision native bridge with the license.
6. If liveness succeeds, resubmit the original bind payload with `clevises='7'`, `scolloped=<livenessId>`, and `arrests=<license>`.
7. Do not send image/file parameters for type `7`, because the Kaibigan Loan bind-card API contract does not require them.
8. If the second submission again returns `20000`, remain on the page and show an error instead of looping.

Token failures, unsupported liveness types, native failures, missing liveness IDs, and network failures keep the user on the current page and do not advance certification.

## Loading, Error, And Empty States

- Initial load: centered progress indicator with the current certification theme.
- Load failure: resolved API error plus Retry action.
- Empty groups: stable empty state explaining that no payment method is available.
- Submit: loading indicator and disabled submit button.
- Validation: field-specific toast using the server placeholder when available.
- Request/liveness failure: `AppToast.error`, without an adjacent redundant loading dismissal because that helper already closes loading.

All async callbacks check widget mounted state before mutating UI.

## Testing

### Model Tests

- Parse groups, fields, optional rules, initial values, and enum choices.
- Normalize numeric and string `commensurate` values to `String`.
- Filter malformed groups, fields, and options.

### Widget Tests

- Loading, successful load, load error with retry, and empty response.
- Render only groups returned by the API.
- Switch groups and render the correct dynamic fields.
- Preserve group-local form state through tab switches.
- Select an enum by displayed label while submitting its normalized string value.
- Validate required fields and mismatched account values.
- Prevent duplicate submits.
- Assert the exact Kaibigan Loan request body.

### Liveness Tests

- Code `20000` requests a bind-card token using cached order number and type `'1'`.
- Missing order number stops before token loading.
- Native failure prevents a second bind request.
- Success resubmits with `clevises`, `scolloped`, and `arrests`.
- A second `20000` ends with an error and does not loop.

### Navigation And Visual Tests

- `bank` and `CocoShorting` both open the bind-card route with `geobotanists`.
- Normal success continues the product-detail flow.
- Existing H5 `changeAccount` behavior remains unchanged.
- Verify the renamed progress asset is used.
- Compare the implemented page against the Lanhu HTML/CSS at 375 x 812 and inspect narrow-screen and large-text layouts for clipping, overlap, and footer movement.

Run focused bind-card model/widget tests, navigation tests, and `flutter analyze`. Report pre-existing failures separately and do not modify unrelated files to make verification green.

## Success Criteria

- The page visually matches the supplied Lanhu bind-card design.
- The UI is fully driven by groups and fields returned from the Kaibigan Loan API.
- Every documented `commensurate` value is represented and submitted as `String`.
- Request fields and response handling match the current project's documentation.
- Normal success, liveness-required success, loading, error, empty, and validation paths are covered by tests.
- No Funny Loan protocol key, remote Lanhu asset URL, hardcoded Hex color, or unrelated account-change behavior is introduced.
