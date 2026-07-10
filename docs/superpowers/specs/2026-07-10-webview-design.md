# WebView Design

## Goal

Add an in-app WebView container with a replaceable JavaScript bridge for the
Kaibigan Loan H5 flows.

## Architecture

The feature lives in `lib/src/modules/webview/` and is split into a UI
container, bridge protocol models/constants, and an action dispatcher. The
container owns browser lifecycle, loading/error UI, navigation interception,
and WebView history. The dispatcher owns native business actions and keeps
those branches out of the page widget.

`AppRoutes` exposes `/webview`; `NavigationHelper.toWebView()` opens it; and
`NavigationHelper.navigateRawTarget()` opens HTTP(S) targets in the in-app
container. Non-web targets continue through the existing controlled navigation
or external launcher paths.

## Protocol

The bridge accepts JSON objects with `action`, optional `callbackId`, and a
`data`/`payload`/`params` payload. It returns a stable result structure:

```json
{"code": 0, "message": "success", "data": {}}
```

The handler name and nine action values are centralized in
`webview_bridge_constants.dart`. They are temporary random strings and must be
replaced only in that file when the H5 contract arrives.

Supported actions are: risk reporting, external-browser opening, internal
scheme navigation, close page, return home, app review, signed common params,
original-card retry, and collection-account change.

## Safety And Lifecycle

Only HTTP(S), about, data, javascript, and file URLs can load inside the
container. Other schemes are sent to the existing external URL launcher.
Certificate trust is not bypassed. Browser permission requests are denied by
default. JavaScript handlers are installed while the page is foregrounded and
removed when it backgrounds or is disposed.

The page shows an indeterminate load indicator, user-visible retry UI on load
failure, and uses WebView history before closing the Flutter route.

## Business Integrations

Risk reporting calls `ReportManager`. Internal URLs use `NavigationHelper`.
Signed common parameters are built with `ApiSignature`. Original-card retry
calls `ApiClient.originalCardRetry()` and opens the response URL in the current
WebView. Account change uses the existing account API and routes to the
certification/bank flow available in this checkout.

Each API branch closes loading on both success and failure, turns errors into a
user-visible message through `AppToast`, and returns a bridge failure result.

## Verification

Tests cover protocol parsing and result encoding, URL handling and back rules,
bridge action dispatch including unsupported actions, and navigation-route
arguments. The implementation follows red-green-refactor: each behavior gets a
failing test before production code.
