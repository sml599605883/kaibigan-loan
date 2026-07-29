# Native Location Request Queue Design

## Goal

Prevent concurrent Flutter `getLocation` calls from overwriting each other's
native callbacks while preserving the current permission, reporting, and
product-admission behavior.

## Scope

The implementation is limited to the iOS location handling in
`ClientBridgeRegistrar.swift` and focused regression tests.

It will not:

- add a native location timeout;
- add a native location cache;
- make product admission wait for location reporting;
- change when location permission is requested;
- change location report payload fields or API contracts.

## Design

Replace the single `pendingLocationResult` callback with a collection of
pending callbacks identified by request IDs. Add an `isRequestingLocation`
flag so the registrar starts at most one `CLLocationManager.requestLocation()`
operation at a time.

When an authorized `getLocation` call arrives:

1. Add its Flutter result callback to the pending collection.
2. Start native location only when no location operation is already active.
3. If a location operation is active, leave the callback queued for the same
   result.

When location succeeds, reverse geocode the selected location once and return
the resulting payload to every queued callback. A reverse-geocoding failure
must still return the coordinates with empty address fields.

When location fails, or authorization changes to a non-authorized terminal
state, return the existing empty location payload to every queued callback.
Every completion path clears the queue and resets `isRequestingLocation` so a
later call can start a new native request.

Calls received while reverse geocoding is active join the current queue and
receive the same result. The implementation must not cancel the active reverse
geocode merely because another caller requests location.

## Data Flow

```text
Flutter getLocation A -> enqueue A -> start native location
Flutter getLocation B -> enqueue B -> reuse active native location
native callback        -> reverse geocode once
                       -> complete A and B
                       -> clear queue and reset state
```

## Error Handling

- Unauthorized calls continue returning immediately with the existing status
  payload and are not queued.
- An empty native locations array completes all queued callbacks with the
  existing empty location payload.
- `didFailWithError` completes all queued callbacks and resets request state.
- Reverse-geocoding errors return valid coordinates and empty address fields.
- No timeout is introduced. Completion remains driven by Core Location and
  geocoder delegate callbacks.

## Verification

Focused tests will verify:

- the source no longer stores a single `pendingLocationResult`;
- concurrent callbacks are retained in a collection;
- native location starts only when `isRequestingLocation` is false;
- success and failure paths complete all pending callbacks;
- completion clears pending callbacks and resets the active flag;
- a new request does not cancel an active reverse geocode;
- existing permission and navigation tests remain passing;
- product admission continues to launch location reporting without awaiting it.
