<!-- keywords: coder, mulle-ui-window, uiwindow, uiview, animation, first-responder, render-queue -->
# mulle-ui-window

Use this topic for `UIWindow`-driven view hierarchy: creating windows, choosing planes, attaching drawing to view layers, animation timing, and first-responder focus. For specific event activities, see the focused subtopics:

- **mulle-ui-tracking** — hover, entered/exited, mouse tracking areas

## Understand first

```bash
mulle-sde api apropos UIWindow
mulle-sde api apropos animation
mulle-sde code search windowWithView
mulle-sde code search createRenderQueue
mulle-sde code search firstResponderSearch
```

## Local references

- `src/UIWindow.h`
- `src/UIWindow+Layout.h`
- `src/UIWindow+OneFrame.h`
- `src/UIView+RenderQueue.h`
- `src/UIView+CAAnimation.h`
- `src/UIView+UIFirstResponder.h`
- `src/UIView+UIFirstResponderSearch.h`
- `demo/main-demo-multithread.m`
- `demo/main-two-windows.m`
- `test/10-application/sharedInstance.m`
- `test/50-initCategory/init-category.m`

## Main local surfaces

| Scenario | Reach for |
| --- | --- |
| Create window, choose planes | `UIWindow`, `contentPlane`, `windowWithView:` |
| Attach drawing to content | `UIView` layer callback, `UIView+RenderQueue` |
| Animate geometry or layer state | `UIView+CAAnimation`, `preLayoutAnimator`, `postLayoutAnimator` |
| Move keyboard focus | `UIView+UIFirstResponder`, `UIView+UIFirstResponderSearch` |
| Direct window extensions | `UIWindow` categories with `initCategory`/`deallocCategory` |

## Key patterns

### Build content under a window

```objc
app = [UIApplication sharedInstance];
window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 400, 400)
                   titleUTF8String:"Demo"
                         styleMask:UIWindowStyleMaskDefault & ~UIWindowStyleRetained];
setupSceneInView( [window contentPlane]);
[app addWindow:window];
return( [app runApp]);
```

### Animate view state

```objc
[UIView beginAnimations:"move" context:nil];
[UIView setAnimationDuration:0.3];
[view willChange];
[view setFrame:newFrame];
group = [UIView commitAnimations];
[[window preLayoutAnimator] addAnimation:group];
[window setNeedsAnimation];
```

- `preLayoutAnimator` for frame/bounds/margin changes
- `postLayoutAnimator` for layer-only changes

### Let window do directional focus search

```objc
if( [view becomeFirstResponder])
   [[window nextFirstResponder] becomeFirstResponder];
```

`UIView` default returns nil; the window searches `[self contentView]` tree by geometry.
