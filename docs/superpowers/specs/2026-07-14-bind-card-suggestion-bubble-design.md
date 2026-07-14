# Bind Card Suggestion Bubble Design

## Goal

Add the Funny Loan suggestion-bubble interaction to the Kaibigan Loan bind-card page while using Kaibigan Loan field semantics and the supplied local Lanhu assets.

## Sources Of Truth

- Visual specification: local Lanhu design `认证-绑定电子钱包-确认姓名`.
- Interaction behavior: Funny Loan bind-card `showSuggestionBubble` flow.
- Field contract: Kaibigan Loan `solonets` is the current value and `whackers` is the suggestion/display value.

## Scope

The change is local to the bind-card page. It adds suggestion state, focus tracking, the visual bubble, bulk application, close/reopen behavior, semantic asset names, and regression tests. It does not change bind-card API payloads, liveness, navigation, enum selection, or other certification pages.

## Assets

Rename the supplied files without downloading duplicate Lanhu assets:

- `assets/形状结合 2@3x.png` to `assets/certification_bind_card_suggestion_bubble.png`.
- `assets/cha@3x.png` to `assets/certification_bind_card_suggestion_close.png`.

Expose both paths through `AppAssets`. The background is a horizontally stretchable 3x asset whose design example is 104 x 40 logical pixels. The close image renders at 12 x 12 logical pixels inside a 24 x 24 touch target.

## Field Semantics

- `solonets` remains the current real value displayed in a text field and submitted to the API.
- `whackers` is the suggestion text used by the bubble.
- Enum fields never show or consume suggestion bubbles.
- Suggestion application never overwrites a non-empty text field.

## Visibility State Machine

Maintain a `FocusNode` for each text field in each payment-method group. At most one suggestion bubble is active.

A bubble is visible only when all conditions are true:

1. The field is a text field.
2. The field currently has focus.
3. Its controller text is empty after trimming.
4. Its `whackers` suggestion is non-empty after trimming.
5. The user has not dismissed the bubble for the field's current empty state.

When a text field becomes non-empty, remove its dismissed marker. If the user later clears it while it is focused, its bubble may appear again.

Closing the bubble records the active field as dismissed and hides it. Merely losing and regaining focus while the field stays empty does not clear that dismissed state.

Switching payment-method groups unfocuses the current field, clears the active bubble, and disposes or rebinds focus listeners safely. Existing per-group controller values remain unchanged.

All listeners and focus nodes are removed during page disposal and when the server-driven form state is replaced.

## Suggestion Application

Tapping the bubble follows Funny Loan behavior:

1. Unfocus the current input.
2. Inspect every field in the currently selected payment-method group.
3. Skip enum fields.
4. Skip text fields whose current controller value is non-empty.
5. For each remaining text field with a non-empty `whackers`, set the controller text to that suggestion.
6. Hide the active bubble.

The action does not fill another payment-method group's fields and does not modify any submit-value mapping.

## Visual Layout

Render the bubble in the text field's stack, aligned over the input container with the Lanhu offsets:

- Height: fixed 40 logical pixels.
- Right offset: 25 logical pixels from the field container.
- Vertical placement: overlap the upper portion of the 40-pixel field, matching the design.
- Width: content-driven, not fixed to the 104-pixel example.
- Minimum width: 44 logical pixels.
- Maximum width: the available width inside the 335-pixel form area.
- Text: one line, 16 logical pixels, semibold, white, ellipsized at the maximum width.
- Left padding: 13 logical pixels.
- Background: semantic bubble asset with `BoxFit.fill` so it stretches horizontally.
- Close icon: semantic close asset at 12 x 12 inside a 24 x 24 accessible touch target.

Use existing screen-adapter conventions. No Lanhu remote URL or hardcoded hexadecimal color is added.

## Accessibility And Interaction Safety

- The bubble text action and close action have distinct keys and button semantics.
- The close touch target is at least 24 x 24 as specified by the design; the surrounding bubble remains easy to tap.
- Long suggestions do not overflow the screen or cover content outside the current field.
- Bubble interaction does not trigger the field's text input action accidentally.

## Testing

Add widget tests that prove:

- A focused empty text field with `whackers` shows the bubble.
- A non-empty field, enum field, unfocused field, or field without `whackers` does not show it.
- Only one bubble is visible at a time.
- Tapping the bubble fills all eligible empty text fields in the current group and preserves non-empty fields.
- Another payment-method group's fields are not filled.
- Closing keeps the bubble hidden while the field remains empty.
- Entering a value and clearing it allows the bubble to appear again.
- Switching groups clears the active bubble without losing form values.
- Dynamic width grows with content, respects minimum width, and remains inside the form width for long content.
- The semantic background and close assets are used.
- Existing submission, liveness, narrow-screen, and large-text tests remain green.

## Success Criteria

- Suggestion behavior matches Funny Loan for text fields in the selected group.
- Kaibigan Loan `solonets` and `whackers` semantics remain correct.
- The visual bubble matches the local Lanhu design while sizing to its content.
- Supplied assets have semantic names and no duplicate remote assets are introduced.
- No existing typed value is overwritten and no other bind-card flow changes.
