<!-- keywords: debugger, mulle-ui-window, patterns, render, tracking, responder, categories -->
# Patterns

## Bracket the frame pipeline with the built-in callbacks

`UIWindow` already exposes the useful checkpoints:

```objc
[window setWillLayoutViewsCallback:willLayout];
[window setDidLayoutViewsCallback:didLayout];
[window setDidCreateViewsDrawingQueueCallback:didQueue];
[window setDidAnimateLayersCallback:didAnimate];
[window setWillRenderLayersCallback:willRender];
[window setDidRenderLayersCallback:didRender];
```

- Treat stage `0` in `didAnimateLayersCallback` as pre-layout animator output and stage `1` as post-layout animator output.
- If `willRenderLayersCallback` fires but nothing appears, inspect the queue/layer side next.
- If queue creation never happens, stay in `UIWindow+Layout.m` / `UIWindow+RenderQueue.m`; do not start with layer code.

## Reproduce render bugs with the smallest real window shape

`demo/main-demo-multithread.m` is the clean baseline:

```objc
window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400.0, 400.0)
                   titleUTF8String:"Demo"
                         styleMask:styleMask];
setupSceneInView( [window contentPlane]);
[app addWindow:window];
```

- Put content under `[window contentPlane]` when planes are enabled.
- Attach drawing to `[view layer]`, not to ad-hoc window callbacks, if you are debugging ordinary authored content.
- If the repro only exists with `windowWithView:` or `windowWithLayer:`, check their convenience wrapping in `src/UIWindow.m` before blaming layout.

## Treat render-queue crashes as ownership bugs first

The safe override point is the context variant:

```objc
- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
                   context:(struct UIRenderQueueContext *) ctx
{
   [super createRenderQueue:renderQueue
                    context:ctx];
}
```

- `src/UIView+RenderQueue.m` aborts in `-createRenderQueue:graphicsContext:`; that entry point is window-only.
- Missing `super` usually means lost inherited layer walk, transform propagation, alpha accumulation, or clipping.
- If a view disappears only when nested or clipped, debug `clipRect` and transformed child frames before chasing the draw callback.

## Debug moving tracking areas with pre-layout animation

`demo/src/main-trackingarea-animated.m` shows the important local rule:

```objc
group = [ta commit];
animator = [window preLayoutAnimator];
[animator addAnimation:group];
```

- Use `preLayoutAnimator` when the animation moves a tracked view or changes layout-relevant geometry.
- The demo comment is literal: `postLayoutAnimator` will not invalidate the tracking quadtree the way layout does.
- If hover or entered/exited events go stale after motion, inspect `updateTrackingAreas`, quadtree invalidation, and which animator owns the animation.

## Debug tracking geometry through the view helper, not by poking the window

The local happy-path setup is:

```objc
area = [UITrackingArea trackingAreaWithRect:[view contentRect]
                                    options:0
                                      owner:view
                                   userInfo:nil];
[view addTrackingArea:area];
```

- `-[UIView addTrackingArea:]` fills in `owner` and `view` for you when needed.
- If the area follows visible rect or autoresizing, the default `-updateTrackingAreas` is enough; otherwise override it on the view.
- For hover debugging, remember the default `hoverTimeInterval` is `1.0` second.

## Start focus bugs from the window side

The useful public path is window fallback search:

```objc
if( [view becomeFirstResponder])
   [[window nextFirstResponder] becomeFirstResponder];
```

- `UIView` default `nextFirstResponder` / `previousFirstResponder` return `nil`; the geometry search lives on `UIWindow`.
- `UIWindow+UIResponder.m` searches from `[self contentView]`, so overlay-only focus targets are invisible to that fallback.
- `UIView+UIFirstResponderSearch.m` uses rounded "fummel" distances, so near-aligned views can swap order unexpectedly.

## Use the lifecycle tests before inventing a bigger reproducer

- `test/10-application/sharedInstance.m` is the fastest proof that basic app bootstrap still works.
- `test/50-initCategory/init-category.m` is the right reproducer for missing default category state or wrong dealloc ordering.
- `test/60-invocationqueue/queue.m` is the narrow queue/lifetime smoke test when named window queues are involved.
