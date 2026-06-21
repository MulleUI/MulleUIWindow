<!-- keywords: debugger, mulle-ui-window, quirks, render-queue, tracking-area, responder, categories -->
# Quirks

## Window and content ownership

- `contentPlane`, `menuPlane`, `toolTipPlane`, `dragAndDropPlane`, and `alertPlane` only exist when the style mask enabled planes.
- `-[UIWindow contentView]` returns `contentPlane` when present, otherwise the root `view`; debugger assumptions that hard-code one or the other go wrong quickly.
- `+[UIWindow windowWithView:titleUTF8String:styleMask:]` may wrap a margined view in a new root view, then forces that root view to scale-to-fill with zero margins.
- `-[UIView setNeedsLayout]` forwards to the enclosing window and asserts if the view is not in a window yet.

## Render queue and animation timing

- The full queue build is window-owned. Calling `-[UIView createRenderQueue:graphicsContext:]` aborts by design in `src/UIView+RenderQueue.m`.
- `src/UIView+RenderQueue.h` means it literally: if you override `-createRenderQueue:context:`, call `super` or inherited transform, alpha, clipping, and subview traversal break.
- `+[UIView commitAnimations]` does not schedule anything on its own; you still have to add the returned group to a window animator.
- `-[UIView willChange]` only snapshots useful state while a transaction is active.
- `src/UIWindow+Layout.m` warns in debug builds when layout-changing animations sit in `postLayoutAnimator`.

## Tracking-area state and lifetime

- `-[UITrackingArea initWithRect:options:owner:userInfo:]` returns `nil` for zero-area rects.
- `UITrackingArea owner`, `view`, and `UIMouseTrackingEvent trackingArea` are assign references. `src/UIWindow+UITrackingArea.h` explicitly says not to retain or copy the tracking event.
- `UITrackingAssignUserInfo` disables retain/release of `userInfo`; from that point on, lifetime is yours.
- The default `-updateTrackingAreas` only refreshes visible-rect tracking and autoresized areas. Custom geometry needs a view override.
- Invalidating tracking areas forgets which areas were already "entered", so an immediate repeat `mouseEntered:` after layout is normal.

## Responder search surprises

- `UIWindow` fallback search walks `[self contentView]`, not the menu, tooltip, drag-and-drop, or alert planes.
- The search is fuzzy on purpose: `UIView+UIFirstResponderSearch.m` rounds candidate distances with local `fummel` factors instead of using strict row/column comparisons.
- Initial first-responder setup in `src/UIWindow+FrameInfo.m` falls back to `[[self contentView] nextFirstResponder]` when no explicit initial responder was set.

## Manual frame loops and categories

- `demo/main-two-windows.m` calls out the local manual-loop trap: in one thread, per-window frame costs add up. A timing bug that only shows there may be loop ownership, not rendering.
- Direct categories on `UIWindow` get `initCategory` and `deallocCategory` automatically.
- `test/50-initCategory/init-category.stdout` shows the ordering rule: init follows dependency order, dealloc runs in reverse order.
- `test/60-invocationqueue/queue.m` uses the private `_initInvocationQueues` helper; keep that test as an internal smoke reproducer, not as the normal app pattern.
