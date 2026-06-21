<!-- keywords: debugger, mulle-ui-tracking, tracking, hover, entered, exited, quadtree, stale -->
# mulle-ui-tracking

Use this when hover/entered/exited events don't fire, fire on the wrong area, or become stale after view movement.

## Local references (MulleUIWindow)

- `src/UITrackingArea.h`
- `src/UIWindow+UITrackingArea.h`
- `src/UIView+UITrackingArea.h`
- `demo/src/main-trackingarea-animated.m`

## Debugging workflow

1. **No entered/exited events?** Check:
   - Is the tracking area actually added to the view? (`[view addTrackingArea:area]`)
   - Is the area rect non-zero? (zero-area init returns nil)
   - Is `UITrackingActiveWhenFirstResponder` set but the view isn't first responder?

2. **Events fire on wrong region after animation?** Check which animator was used. Only `preLayoutAnimator` invalidates the tracking quadtree. `postLayoutAnimator` leaves tracking geometry stale.

3. **Duplicate mouseEntered: after layout?** This is normal. Invalidating tracking areas forgets the "entered" state, so the next mouse position check delivers a fresh `mouseEntered:`.

4. **Hover never fires?** Default delay is 1.0 second. Override `-hoverTimeInterval` if your test doesn't wait long enough.

5. **Area seems attached but invisible to tracking?** Check `UITrackingVisibleRectOnly` — it resolves through `[window contentView]` hit testing. If the view is obscured, tracking won't fire.
