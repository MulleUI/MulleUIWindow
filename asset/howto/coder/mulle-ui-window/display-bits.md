<!-- keywords: coder, mulle-ui-window, display-bits, needsLayout, needsDisplay, needsStyling, needsAnimation, frame-pipeline, cascade -->
# UIWindow Display Bits

The UIWindow frame pipeline is controlled by atomic display bits stored in
`_needsDisplay`. Setting any bit triggers a frame. UIWindow interprets the
bits inside its frame callback (`UIWindowDefaultRenderViews`).

## Bit Layout

```c
UIWindowDisplayNeedsDisplay    = 0x1   // views push state to layers
UIWindowDisplayNeedsLayout     = 0x2   // reposition views (cascades → NeedsDisplay)
UIWindowDisplayNeedsStyling    = 0x4   // restyle (cascades → NeedsLayout)
UIWindowDisplayNeedsNextFrame  = 0x8   // schedule next frame at animation rate

// Aliases
UIWindowDisplayNeedsAnimation  = UIWindowDisplayNeedsNextFrame
UIWindowDisplayNeedsRedraw     = UIWindowDisplayNeedsDisplay  // deprecated
```

## Cascade

Higher stages automatically trigger lower stages during frame processing:

```
NeedsStyling → [self style] → sets NeedsLayout
NeedsLayout  → [self layoutFrame:] → sets NeedsDisplay + NeedsNextFrame
NeedsDisplay → (future: per-view draw) → frame runs
```

Drawing (render queue rebuild + layer rendering) always happens unconditionally
when a frame runs. The bits only control which *preparation* stages execute.

## View API

```objc
[view setNeedsLayout];   // → [window setNeedsLayout] → sets NeedsLayout (0x2)
[view setNeedsDisplay];  // → [window setNeedsDisplay] → sets NeedsDisplay (0x1)
```

- `setNeedsLayout` = "my geometry changed, re-layout me" (implies display)
- `setNeedsDisplay` = "my content changed, redraw me" (no layout)

## Window API

```objc
[window setNeedsLayout];     // sets NeedsLayout (0x2)
[window setNeedsStyling];    // sets NeedsStyling (0x4)
[window setNeedsAnimation];  // sets NeedsNextFrame (0x8)
[window setNeedsDisplay];    // sets NeedsDisplay (0x1) — inherited from UIPureWindow
```

## Frame Pipeline (UIWindowDefaultRenderViews)

```
1. if NeedsStyling  → [self style]        → sets NeedsLayout
2. if NeedsLayout   → [self layoutFrame:] → sets NeedsDisplay + NeedsNextFrame
3. always           → [self createRenderQueueForFrame:]
4. always           → [self renderLayersInFrame:]
```

## When to use what

| Situation | Call |
| --- | --- |
| View content changed (color, text, image) | `[view setNeedsDisplay]` |
| View geometry changed (frame, bounds) | `[view setNeedsLayout]` |
| Theme/style changed | `[window setNeedsStyling]` |
| Animation needs continuous frames | `[window setNeedsAnimation]` |

## Relationship to UIPureWindow

UIWindow inherits from UIPureWindow. PureWindow only understands:
- `_needsDisplay != 0` → run the frame callback
- `NeedsNextFrame` (0x8) → use shorter sleep timeout

All pipeline semantics (layout, styling, render queue) are UIWindow's concern.
PureWindow just shuttles bits and calls the frame callback.
