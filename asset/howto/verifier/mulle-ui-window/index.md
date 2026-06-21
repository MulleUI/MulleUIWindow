<!-- keywords: frame-callbacks, tracking-area, profiling, debug-private, logging -->
# mulle-ui-window

Use this topic when user code renders through `UIWindow`, misses tracking events, or behaves differently in `runApp` versus one-frame/manual loops. The repo has a few real diagnostics hooks, but most signal comes from debug builds plus the inherited private debug logging surface.

## Understand first

```bash
mulle-sde api apropos UIWindow
mulle-sde api apropos UITrackingArea
mulle-sde code search willRenderLayersCallback
mulle-sde code search getTrackingAreasIntersectingRect
mulle-sde code search debuggingFlags
```

## Local references

- `asset/dox/TOC.md`
- `src/UIWindow.h`
- `src/UIWindow+FrameInfo.h`
- `src/UIWindow+OneFrame.h`
- `src/UIView+UITrackingArea.h`
- `src/UIWindow+UITrackingArea.m`
- `src/UIWindow+DebugPrivate.h`
- `demo/src/main-trackingarea.m`
- `demo/src/main-window-profile.m`
- `demo/main-two-windows.m`
- `test/70-collision/intersecting-rect.m`
- `test/70-collision/intersecting-rect.stdout`

## Main local diagnostics

| Scenario | Reach for |
| --- | --- |
| Frame timing, layout/render ordering | `UIWindow` frame callbacks in `src/UIWindow.h` |
| Hover/entered/exited not firing | `UIView+UITrackingArea`, `UITrackingArea`, `UIMouseTrackingEvent` |
| Hit-testing tracking rectangles | `getTrackingAreasIntersectingRect:areas:maxAreas:` |
| Multi-window timing oddities | `UIWindow(OneFrame)`, `demo/main-two-windows.m` |
| Debug overlay / internal counters | `src/UIWindow+DebugPrivate.h`, `demo/src/main-window-profile.m` |

## Local verifier delta

- There are **no repo-local verifier environment variables** to turn on tracing. For this library, useful output is mostly compile-time: `DEBUG`, inherited `*DebugPrivate` headers, and the logging macros already used in demos.
- `UIWindow` exposes public per-frame callbacks that are the safest probe point: `willLayoutViewsCallback`, `didLayoutViewsCallback`, `didCreateViewsDrawingQueueCallback`, `willRenderLayersCallback`, `didRenderLayersCallback`, `didAnimateLayersCallback`.
- Keep those callbacks tiny. `src/UIWindow.h` explicitly warns they run every frame and should finish ASAP without system-call-heavy work.

## What to check first

### Frame pipeline

- Use the frame callbacks before patching view code. `didAnimateLayersCallback` reports three stages: `0` after pre-layout animation, `1` after post-layout animation, `2` after layer-private animation.
- If a geometry animation only looks wrong after layout, rebuild with `-DDEBUG`: `src/UIWindow+Layout.m` emits a one-time warning when a layout-changing animation was put into `postLayoutAnimator` instead of `preLayoutAnimator`.

```bash
mulle-sde definition set CFLAGS "-DDEBUG -fsanitize=address,undefined"
mulle-sde craft
```

### Tracking areas

- Default `UIView` tracking handlers already log `%#@` through `UIViewMouseTrackingEventLog` in `src/UIView+UITrackingArea.m`. If you override `mouseEntered:`, `mouseMoved:`, `mouseExited:`, `mouseHoverStarted:`, or `mouseHoverEnded:`, call `super` when you want to preserve that debug output.
- `updateTrackingAreas` only auto-syncs areas with `UITrackingVisibleRectOnly`. Other areas go stale unless the view updates them itself.
- Zero-sized tracking rects are ignored and logged in `src/UIWindow+UITrackingArea.m`.
- `UITrackingArea` does **not** support copying, does **not** retain `owner`, and expects you to use `tag`/`userInfo` for identification.
- `test/70-collision/intersecting-rect.stdout` shows a useful quirk: `getTrackingAreasIntersectingRect:areas:maxAreas:` returns the **total** hit count even when `maxAreas` truncates the output buffer (`3` hits with `maxAreas=1`).

### Manual isolation

- `demo/main-two-windows.m` is the local pattern for isolating per-window behavior with `processOneFrame`; it also documents that frame costs are additive in the single-thread loop.
- `src/UIWindow+OneFrame.h` exists for the conventional event/render loop. Use that style when a bug disappears inside normal `runApp` scheduling and you need a tighter repro.

## Private-only hooks

- `src/UIWindow+DebugPrivate.h` only re-exports `UIPureWindow+DebugPrivate.h`. If your app already opts into private debug headers, `UIWindowDebugRenderFrameInfo` is consumed by `src/UIWindow+Render.m` to paint frame count plus active/running/finished animation counters.
- `demo/src/main-trackingarea.m` shows the intended private-debug pattern: copy `[window debuggingFlags]` into the custom tracking view, then log `UIMouseTrackingEvent` objects with `MulleUILog`.
- `demo/src/main-window-profile.m` is the richest in-repo example of frame profiling and `currentFrameInfo` inspection.

## Report with

- whether the bug reproduces in `runApp` and in a one-frame/manual loop
- which callback stage (`0/1/2`) first shows wrong state
- whether the affected tracking area uses `UITrackingVisibleRectOnly`
- the total hit count versus buffered hit count from `getTrackingAreasIntersectingRect:areas:maxAreas:`
