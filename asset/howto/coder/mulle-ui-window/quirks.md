<!-- keywords: coder, mulle-ui-window, quirks, uiwindow, animation, planes, responder -->
# Quirks

## UIWindow and plane setup

- `contentPlane`, `menuPlane`, `toolTipPlane`, `dragAndDropPlane`, `alertPlane` only exist when style mask enables planes.
- `windowWithView:` may wrap a margined view in a new root with zero margins.
- `setNeedsLayout` asserts if the view is not in a window yet.
- In single-thread manual loops, per-window frame costs are additive.

## Render queue and animation timing

- Only `UIWindow` may kick off the full render-queue walk. `-createRenderQueue:graphicsContext:` on UIView aborts.
- If you override `-createRenderQueue:context:`, call `super`.
- Layout-changing animations belong in `preLayoutAnimator`. Debug builds warn if they end up in `postLayoutAnimator`.
- `commitAnimations` does NOT schedule; you must add the group to a window animator.
- `willChange` only snapshots state while a transaction is active.

## First responder

- `UIView` default `nextFirstResponder`/`previousFirstResponder` return nil.
- Window fallback search walks `[self contentView]` — overlay-plane views are outside it.
- Search is fuzzy with "fummel" rounding, not strict row/column.

## Categories

- Direct `UIWindow` categories get `initCategory`/`deallocCategory` automatically.
- Use `MULLE_OBJC_DEPENDS_ON_CATEGORY` for ordering.
