<!-- keywords: mulle-ui-tracking, quirks, zero-area, assign, hover, invalidate -->
# Quirks

- `initWithRect:options:owner:userInfo:` returns `nil` for zero-area rectangles.
- `UITrackingArea owner`, `view`, and `UIMouseTrackingEvent trackingArea` are **assign** references. Do not retain or copy the tracking event.
- `UITrackingAssignUserInfo` disables retain/release of `userInfo` — lifetime is yours from that point.
- Default hover delay is `1.0` second. Override `-hoverTimeInterval` to change it.
- Invalidating tracking areas forgets which areas were "entered", so a repeat `mouseEntered:` after layout is normal.
- `UITrackingActiveWhenFirstResponder` checks `[window firstResponder] == view` — hover bugs can actually be focus bugs.
- `UITrackingVisibleRectOnly` resolves visibility through `[window contentView]` hit-testing.
