# Account List Page Design

## Purpose

Implement the native payment-account selection page represented by the Lanhu
design "Loan Application". It lets an applicant choose one of the accounts
already bound to the current product and submit the choice for the current
order.

## Scope

- Add `AccountListPage` as a GetX route.
- Load the account list with `ApiClient.userAccountList(geobotanists:)`.
- Submit the selected account with `ApiClient.changeOrderAccount(dodgy:, smokehouse:)`.
- Render Bank, E-wallet, and Cash Pickup sections with `AppSectionTitle`.
- Rename and move the supplied assets to `assets/account_option_selected.png`,
  `assets/account_option_unselected.png`, and
  `assets/account_add_payment_methods.png`.
- Keep "Add other payment methods" as a visual-only control with no action.

## Route Contract

The route receives a map with the following documented fields:

- `geobotanists`: product ID used by `userAccountList`.
- `dodgy`: order number used by `changeOrderAccount`.

The page returns the selected account model after a successful submission.
If either route argument is absent, loading is skipped and the page renders an
error state instead of issuing an incomplete request.

## Account Data Model

Each item is parsed from the documented account-list fields:

- `smokehouse`: bound account ID submitted on confirmation.
- `overdoer`: account type name used to select the section.
- `dendron`: remote account-type icon URL.
- `postaccident`: provider or bank name.
- `benefits`: account display text, such as a receipt account or customer name.
- `uptime`: main-account flag for the initial selection.

Section matching is case-insensitive and supports the design labels `Bank`,
`E-wallet`, and `Cash Pickup`. Unknown account types remain visible in a final
section titled with the server-provided type.

## UI And Interaction

- The screen uses a white background and the existing back affordance.
- Each section uses `AppSectionTitle`.
- Account cards use the design blue panel, yellow information panel, semantic
  color tokens, and the supplied selected/unselected assets.
- Tapping an account updates the selected `smokehouse` in memory only.
- Confirm remains enabled only when an account is selected and no request is
  in progress. It shows loading while posting and surfaces server/network
  failures through the existing toast mechanism.
- On success, the page dismisses loading, optionally shows the server message,
  and pops with the selected account.

## Error And Empty States

- While loading, the content region displays the standard progress indicator.
- An account-list error shows the resolved API error plus Retry.
- An empty successful result shows the existing app empty-state wording and
  does not permit confirmation.
- A submit failure preserves the selection and lets the applicant retry.

## Testing

- Unit-test account parsing, section grouping, and main-account selection.
- Widget-test list request arguments, server-driven display values, selection,
  confirmation request parameters, success pop, and error/retry states.
- Route-test `NavigationHelper` pushes the page with both required arguments.
