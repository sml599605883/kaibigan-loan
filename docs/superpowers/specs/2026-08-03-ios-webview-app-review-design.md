# iOS WebView App Review Design

## Goal

Handle the WebView `toGrade` action by requesting Apple's in-app rating prompt on iOS. The current WebView stays open when iOS chooses not to display the prompt.

## Scope

- Preserve the existing H5 handler, action name, callback shape, and dispatcher result.
- Reuse the existing `ClientBridge` method channel.
- Add no third-party dependency.
- Do not open the App Store as a fallback.
- Do not change Android behavior as part of this task.

## Architecture

`WebViewPage` injects `ClientBridge.requestAppReview` into `WebViewBridgeDispatcher.requestAppReview`. The dispatcher continues to return success after the native request completes. `ClientBridge` invokes a new `requestAppReview` method on its existing iOS method channel.

`ClientBridgeRegistrar` imports StoreKit and handles the new method on the main thread. On iOS 14 and later, it resolves the foreground active `UIWindowScene` and calls `SKStoreReviewController.requestReview(in:)`. On earlier supported versions, it calls `SKStoreReviewController.requestReview()`.

## Behavior

- H5 sends `kaibigan_loan_x2xWItx6A1zrRnI` through `ph_kaibigan_loan_ios`.
- Flutter requests the native iOS review prompt once per received action.
- Apple controls whether the prompt is actually displayed and may suppress it.
- Suppression is treated as a completed request; the WebView remains unchanged.
- If no active scene is available on iOS 14 or later, the native bridge completes without presenting UI and without crashing.
- An actual method-channel failure follows the existing dispatcher error path.

## Verification

- A Dart method-channel test verifies `ClientBridge.requestAppReview()` invokes `requestAppReview` on iOS.
- A dispatcher test verifies `toGrade` calls its injected review callback and returns success.
- An iOS source contract test verifies StoreKit import, the method case, foreground scene resolution, and `requestReview(in:)` wiring.
- Run focused Flutter tests, focused analysis, and `git diff --check`.

## Known Platform Constraint

`SKStoreReviewController` does not guarantee prompt presentation. iOS applies system eligibility and frequency limits, and the application cannot detect whether the prompt appeared.
