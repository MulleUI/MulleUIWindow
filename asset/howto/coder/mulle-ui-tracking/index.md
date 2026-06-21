<!-- keywords: mulle-ui-tracking, tracking, hover, mouseEntered, mouseExited, mouseMoved, UITrackingArea, cursor -->
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
- `demo/src/main-trackingarea-animated.m`

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

- (void) mouseHovered:(UIMouseMotionEvent *) event
{
   // mouse hovered for hoverTimeInterval (default 1.0s)
}
```

## Tracking options

| Option | What it does |
|--------|-------------|
| `UITrackingMouseMoved` | Receive `mouseMoved:` while inside area |
| `UITrackingMouseHover` | Receive `mouseHovered:` after hover delay |
| `UITrackingActiveWhenFirstResponder` | Only active when view is first responder |
| `UITrackingVisibleRectOnly` | Track only the visible (unobscured) portion |
| `UITrackingAssignUserInfo` | Disable retain/release on userInfo |

## Moving tracked views

When animating a view that has a tracking area, use `preLayoutAnimator`:

```objc
group = [ta commit];
[[window preLayoutAnimator] addAnimation:group];
```

`postLayoutAnimator` will NOT invalidate the tracking quadtree — tracking becomes stale.

## Custom geometry

If area geometry depends on custom layout state, override `-updateTrackingAreas` on the view. The default only handles visible-rect and autoresizing-mask cases.
