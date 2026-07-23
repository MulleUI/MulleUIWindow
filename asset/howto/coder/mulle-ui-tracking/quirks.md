<!-- keywords: mulle-ui-tracking, quirks, zero-area, assign, hover, invalidate, mouseHoverStarted, UIMouseTrackingEvent -->
# Quirks

- `initWithRect:options:owner:userInfo:` returns `nil` for zero-area rectangles.
- `UITrackingArea owner`, `view`, and `UIMouseTrackingEvent trackingArea` are **assign** references. Do not retain or copy the tracking event.
- `UIMouseTrackingEvent type` field contains: `UIMouseTrackingMovedEventType` (0), `UIMouseTrackingEnteredEventType` (1), `UIMouseTrackingExitedEventType` (2), `UIMouseTrackingHoverStartedEventType` (3), `UIMouseTrackingHoverEndedEventType` (4).
- `UITrackingAssignUserInfo` disables retain/release of `userInfo` — lifetime is yours from that point.
- Hover event methods are `mouseHoverStarted:` / `mouseHoverEnded:` (not `mouseHovered:`).
- `UIView` default implementations of all tracking handlers (`mouseEntered:`, `mouseMoved:`, `mouseExited:`, `mouseHoverStarted:`, `mouseHoverEnded:`) do nothing except trace. No need to call `super`.
- Default hover delay is `1.0` second. Override `-hoverTimeInterval` to change it.
- `UITrackingSetCursor` auto-switches cursor on enter — if set, the cursor property on the area is ignored in favor of the option.
- Invalidating tracking areas forgets which areas were "entered", so a repeat `mouseEntered:` after layout is normal.
- `UITrackingActiveWhenFirstResponder` checks `[window firstResponder] == view` — hover bugs can actually be focus bugs.
- `UITrackingVisibleRectOnly` resolves visibility through `[window contentView]` hit-testing.
- Layout (`-layout`) invalidates the tracking quadtree, keeping rects in sync. Without layout, stale quadtree entries are not updated.
- Tracking areas without `UITrackingVisibleRectOnly` are NOT repositioned by the default `-updateTrackingAreas`. Override `-updateTrackingAreas` to update their rects.
