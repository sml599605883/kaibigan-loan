# iOS Push Routing Design

## Goal

Add iOS notification receipt and click routing to Kaibigan Loan with the same
observable behavior as Funny Loan while implementing it through Kaibigan Loan's
existing native bridge and navigation boundaries.

## Scope

The feature handles alert notifications delivered while the app is in the
foreground and notification responses produced when the user taps a delivered
notification. It does not change APNs token registration, token upload,
notification permission timing, silent push processing, or backend payload
contracts.

## Required Behavior

- When a foreground notification contains a supported non-empty URL, suppress
  the system banner and immediately send the URL to Flutter for navigation.
- When a foreground notification has no supported URL, show the banner, badge,
  and sound normally.
- When the user taps a notification containing a supported URL, send the URL to
  Flutter for navigation and always complete the native response callback.
- Accept a URL from any of these payload shapes:
  - top-level `url`
  - `params` as a dictionary containing `url`
  - `params` as a JSON string containing `url`
- Trim URL whitespace and ignore empty or non-string URL values.
- Preserve notification routes received before Flutter starts listening.
- Preserve FIFO ordering when multiple routes arrive.
- Wait until GetX navigation has a mounted context before opening a route.
- Route all accepted URLs through `NavigationHelper.navigateRawTarget()` so the
  current app-scheme, product-detail, and web routing rules remain authoritative.

## Architecture

### AppDelegate

`AppDelegate` assigns itself as `UNUserNotificationCenter.current().delegate`
and implements the two system notification callbacks. It does not parse payload
formats or own a route queue. It forwards each notification payload to
`ClientBridgeRegistrar` and selects the foreground presentation options from the
registrar's result.

### ClientBridgeRegistrar

`ClientBridgeRegistrar` owns native push payload interpretation because it
already owns the `kaibigan_loan/report_event` EventChannel. It will:

- extract and normalize the supported URL shapes;
- emit a `push_route` event when Flutter is listening;
- queue normalized routes while no event sink is attached;
- drain queued routes in arrival order when Flutter attaches;
- retain the existing `push_token` and `tracking_status_changed` event behavior.

Keeping parsing and delivery here avoids reproducing Funny Loan's monolithic
AppDelegate structure and gives the native bridge one clear event-delivery
responsibility.

### Flutter Push Navigation Coordinator

A focused Flutter coordinator subscribes to the existing report native-event
stream. It accepts only `push_route` events with a non-empty URL, queues them,
and drains the queue serially when navigation is ready. A scheduled post-frame
retry handles cold-start navigation initialization without busy waiting.

The coordinator delegates the actual route interpretation to
`NavigationHelper.navigateRawTarget()`. It does not duplicate scheme parsing,
authentication decisions, or product-flow logic.

The coordinator is bound during application startup before `runApp()`. Native
events remain protected by the native queue until the EventChannel listener is
attached, and Flutter events remain protected by the coordinator queue until
navigation is ready.

## Error Handling

- Malformed payloads and blank URLs are ignored without throwing.
- EventChannel errors remain contained by the existing native bridge stream.
- A route is removed from the Flutter queue only when its handling begins;
  subsequent routes are still processed serially.
- Native notification completion handlers are invoked exactly once.
- Existing navigation error handling remains owned by `NavigationHelper`.

## Similarity Constraint

Behavioral parity is required, but implementation parity is not. The feature
must follow Kaibigan Loan's existing bridge structure and split responsibilities
between `AppDelegate`, `ClientBridgeRegistrar`, and the Flutter coordinator.
Code must not be transformed solely through renaming, statement reordering, or
other cosmetic changes derived from Funny Loan.

## Verification

Focused tests will verify:

- supported payload shapes and normalization;
- missing, malformed, and empty URL handling;
- filtering of unrelated native events;
- queuing while navigation is unavailable;
- FIFO route processing;
- foreground presentation behavior with and without a route;
- preservation of existing push-token event behavior.

Run focused Flutter tests, `flutter analyze`, and an iOS simulator build without
code signing. Existing unrelated worktree changes are excluded from this
feature's edits and commit scope.
