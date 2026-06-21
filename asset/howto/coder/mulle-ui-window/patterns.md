<!-- keywords: coder, mulle-ui-window, patterns, uiwindow, animation, responder, render-queue -->
# Patterns

## Build content under a window, not inside ad-hoc callbacks

```objc
window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 400, 400)
                   titleUTF8String:"Demo"
                         styleMask:UIWindowStyleMaskDefault & ~UIWindowStyleRetained];
[window setRefreshContentMode:CGContentModeTopLeft];
setupSceneInView( [window contentPlane]);
[app addWindow:window];
return( [app runApp]);
```

## Put custom drawing on the view's layer

```objc
view = [UIView viewWithFrame:frame];
[view setBackgroundColor:BLAU];
[(CGGraphicsLayer *) [view layer] setDrawCallback:(CGGraphicsLayerDrawCallback_t *) drawStuff];
[contentPlane addSubview:view];
```

## Override render-queue by extending the inherited walk

```objc
- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
                   context:(struct UIRenderQueueContext *) ctx
{
   [super createRenderQueue:renderQueue context:ctx];
   if( _overlayLayer)
      [self addLayer:_overlayLayer toRenderQueue:renderQueue context:ctx];
}
```

Must call `super` — otherwise inherited transform, alpha, clipping break.

## Animate view state

```objc
[UIView beginAnimations:"move" context:nil];
[UIView setAnimationDuration:0.3];
[view willChange];
[view setFrame:newFrame];
group = [UIView commitAnimations];
[[window preLayoutAnimator] addAnimation:group];
[window setNeedsAnimation];
```

- `preLayoutAnimator` for geometry changes
- `postLayoutAnimator` for layer-only changes
- `commitAnimations` does NOT schedule by itself — must add to animator

## Let the window do directional focus search

```objc
if( [view becomeFirstResponder])
   [[window nextFirstResponder] becomeFirstResponder];
```

## Use `UIWindow` categories for extensions

```objc
@implementation UIWindow( MyCategory)
- (void) initCategory  { /* setup */ }
- (void) deallocCategory { /* teardown */ }
@end
```

Use `MULLE_OBJC_DEPENDS_ON_CATEGORY` for ordering between categories.
