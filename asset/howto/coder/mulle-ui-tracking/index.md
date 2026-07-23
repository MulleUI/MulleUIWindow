<!-- keywords: mulle-ui-tracking, tracking, hover, mouseEntered, mouseExited, mouseMoved, UITrackingArea, cursor, quadtree -->
# mulle-ui-tracking

Use this topic when you need hover detection, mouse entered/exited events, or cursor changes based on mouse position.

## Understand first

```bash
mulle-sde api apropos UITrackingArea
mulle-sde api apropos TrackingArea
mulle-sde code search addTrackingArea
mulle-sde code search hoverTimeInterval
mulle-sde code search mouseEntered
```

## Local references (MulleUIWindow)

- `src/UITrackingArea.h`
- `src/UIWindow+UITrackingArea.h`
- `src/UIView+UITrackingArea.h`
- `demo/src/main-trackingarea.m`
- `demo/src/main-trackingarea-animated.m`
- `demo/src/main-cursor.m`
- `test/70-collision/intersecting-rect.m`

## Quick recipe: basic hover tracking

```objc
UITrackingArea   *area;

area = [UITrackingArea trackingAreaWithRect:[self bounds]
                                    options:UITrackingMouseMoved | UITrackingMouseHover
                                      owner:self
                                   userInfo:nil];
[area setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
[self addTrackingArea:area];
```

Then implement handlers:

```objc
- (void) mouseEntered:(UIMouseMotionEvent *) event
{
   // mouse entered the tracking area
}

- (void) mouseExited:(UIMouseMotionEvent *) event
{
   // mouse left the tracking area
}

- (void) mouseHoverStarted:(UIMouseTrackingEvent *) event
{
   // mouse hovered for hoverTimeInterval (default 1.0s)
}

- (void) mouseHoverEnded:(UIMouseTrackingEvent *) event
{
   // mouse stopped hovering or left the area
}
```

## Tracking options

| Option | What it does |
|--------|-------------|
| `UITrackingMouseMoved` | Receive `mouseMoved:` while inside area |
| `UITrackingSetCursor` | Auto-switch cursor to `[area cursor]` on enter |
| `UITrackingMouseHover` | Receive `mouseHoverStarted:` / `mouseHoverEnded:` after hover delay |
| `UITrackingActiveWhenFirstResponder` | Only active when view is first responder |
| `UITrackingVisibleRectOnly` | Track only the visible (unobscured) portion |
| `UITrackingAssignUserInfo` | Disable retain/release on userInfo |

## Multiple tracking areas on one view

Attach several areas with different rects and cursors. Each fires its own events:

```objc
area1 = [UITrackingArea trackingAreaWithRect:outerRect
                                     options:0
                                       owner:self
                                    userInfo:nil];
[area1 setCursor:[UIApp cursorWithStandardShape:UICursorDrag]];
[self addTrackingArea:area1];

area2 = [UITrackingArea trackingAreaWithRect:innerRect
                                     options:0
                                       owner:self
                                    userInfo:nil];
[area2 setCursor:[UIApp cursorWithStandardShape:UICursorCrosshair]];
[self addTrackingArea:area2];
```

See `demo/src/main-cursor.m` for a full example.

## Spatial queries

Query the tracking quadtree directly:

```objc
UITrackingArea   *hits[8];
NSUInteger       n;

n = [window getTrackingAreasIntersectingRect:someRect
                                       areas:hits
                                    maxAreas:8];
```

Returns total intersecting count (may exceed `maxAreas`). See `test/70-collision/intersecting-rect.m`.

## Moving tracked views

When animating a view that has a tracking area, use `preLayoutAnimator`:

```objc
group = [ta commit];
[[window preLayoutAnimator] addAnimation:group];
```

`postLayoutAnimator` will NOT invalidate the tracking quadtree — tracking becomes stale.

## Custom geometry

If area geometry depends on custom layout state, override `-updateTrackingAreas` on the view. The default only handles visible-rect and autoresizing-mask cases.
