<!-- keywords: debugger, mulle-ui-window, uiwindow, uiview, tracking, render-queue, responder, animation -->
# mulle-ui-window

Use this topic when a MulleUIWindow app opens with the wrong content, stops redrawing, loses hover/focus behavior, or behaves differently in the normal app loop versus a manual `processOneFrame` loop.

## Understand first

```bash
mulle-sde api apropos UIWindow
mulle-sde api cat UIWindow
mulle-sde api cat UITrackingArea
mulle-sde api apropos RenderQueue
mulle-sde api apropos TrackingArea
mulle-sde api apropos FirstResponder
mulle-sde code search willRenderLayersCallback
mulle-sde code search createRenderQueue
mulle-sde code search processOneFrame
mulle-sde code search initCategory
```

## Local references

- `asset/dox/TOC.md`
- `demo/README.md`
- `demo/main-demo-multithread.m`
- `demo/main-two-windows.m`
- `demo/src/main-trackingarea-animated.m`
- `test/10-application/sharedInstance.m`
- `test/50-initCategory/init-category.m`
- `test/50-initCategory/init-category.stdout`
- `test/60-invocationqueue/queue.m`
- `src/UIWindow.h`
- `src/UIWindow.m`
- `src/UIWindow+Layout.h`
- `src/UIWindow+Layout.m`
- `src/UIWindow+OneFrame.h`
- `src/UIWindow+Render.m`
- `src/UIWindow+RenderQueue.m`
- `src/UIWindow+UITrackingArea.h`
- `src/UITrackingArea.h`
- `src/UITrackingArea.m`
- `src/UIView+RenderQueue.h`
- `src/UIView+RenderQueue.m`
- `src/UIView+UITrackingArea.h`
- `src/UIView+UITrackingArea.m`
- `src/UIView+UIFirstResponder.h`
- `src/UIView+UIFirstResponderSearch.h`
- `src/UIView+UIFirstResponderSearch.m`
- `src/UIView+UIWindow.h`
- `src/UIView+UIWindow.m`

## Symptom map

| Symptom | Reach for | Local rule |
| --- | --- | --- |
| Window shows stale or missing content | `UIWindow`, `UIWindow+Layout`, `UIWindow+RenderQueue`, `UIWindow+Render` | The real frame path is styling -> pre-layout animation -> layout -> post-layout animation -> render-queue build -> layer render; debug the stage, not just the final draw callback. |
| Content exists but never reaches the framebuffer | `UIView+RenderQueue`, `demo/main-demo-multithread.m` | Drawing normally lives on the view's layer callback, but only `UIWindow` may kick off the full render-queue walk. |
| Hover, entered, exited, or cursor state is wrong | `UITrackingArea`, `UIView+UITrackingArea`, `UIWindow+UITrackingArea`, `demo/src/main-trackingarea-animated.m` | Tracking depends on quadtree upkeep and area geometry; moving tracked views with the wrong animator leaves tracking stale. |
| Tab-like focus moves to the wrong view or nowhere | `UIWindow+UIResponder`, `UIView+UIFirstResponderSearch` | Window fallback search walks `[self contentView]` with fuzzy geometry matching; overlay-plane views are outside that default search. |
| Behavior differs only in manual frame driving | `UIWindow+OneFrame`, `demo/main-two-windows.m` | Single-thread manual loops make per-window frame costs additive; prove the bug in the app-managed loop first. |
| UIWindow instance state is wrong at init/dealloc time | `UIWindow.h`, `UIWindow.m`, `test/50-initCategory/init-category.m` | Direct `UIWindow` categories get `initCategory`/`deallocCategory` automatically, with dependency ordering. |

## Local debugging delta

- Split bugs into window-owned pipeline problems versus view-owned content problems. The window owns display bits, queue creation, animator stages, first-responder fallback, and tracking quadtree updates.
- Start from the smallest reproducer that still uses the real stack: `test/10-application/sharedInstance.m` for bootstrap, `demo/main-demo-multithread.m` for a normal window/content-plane/layer path, `demo/main-two-windows.m` only when loop ownership matters.
- Prefer frame callbacks over ad-hoc logging inside render code. `UIWindow` already exposes hooks before and after layout, queue creation, animation stages, and layer rendering.
- The tests here are mostly lifecycle/leak smoke, not behavioral coverage. When a demo repro exists, it is usually the better debugger anchor than `test/README.md`.

## Reporting guidance

When you hand off a bug here, name the family first: window/frame pipeline, view/layer queue, tracking area, responder search, or UIWindow category lifecycle. Also note whether planes were enabled, whether the window came from `windowWithView:` or `windowWithLayer:`, and whether the failure happens before queue creation, after stage-0/stage-1 animation, or only in a manual `processOneFrame` loop.
