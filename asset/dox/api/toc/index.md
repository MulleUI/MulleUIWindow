# MulleUIWindow Library Documentation for AI
<!-- Keywords: window, view, styling, tracking, animation, rendering, events -->

## 1. Introduction & Purpose

MulleUIWindow provides the UIWindow class and extends UIView functionality to create a complete windowing and view hierarchy system for MulleUI applications. It serves as the grand orchestrator that manages the overall screen real estate, coordinates display of content, and acts as the root container for user interfaces. The framework elegantly separates concerns between drawing (CALayer), event handling (UIView), and overall window management (UIWindow). 

Key features include:
- Hierarchical view management with UIWindow at the top
- Mouse tracking areas with hover and entered/exited events
- Animation system integration with pre-layout and post-layout animators
- Render queue management for efficient layer rendering
- First responder chain for keyboard and mouse input handling
- Threading support for responsive UI (separate window/render thread)
- Integration with CALayer for visual rendering and animation

This library is part of the MulleUI framework stack and depends on MulleUIPureWindow (base window functionality), MulleUIView (view hierarchy), and MulleCA (Core Animation-like layer system).

## 2. Key Concepts & Design Philosophy

**Clear Separation of Responsibilities:**
- **UIWindow**: Top-level orchestrator managing the screen, coordinating display, handling events, and managing the view hierarchy
- **UIView**: Interactive canvas handling user interactions, events, layout, and managing subviews
- **CALayer (id <UILayer>)**: Visual virtuoso focused solely on drawing and rendering, with no user interaction handling

**Frame-based Rendering Pipeline:**
A "frame" is the timespan taken to fill the framebuffer contents that will be displayed by swapBuffers. The UIWindow frame processing follows this sequence:
1. **Pre-layout animations** - Animations that run before layout
2. **Layout** - View hierarchy layout with `-layout` calls
3. **Post-layout animations** - Animations that run after layout
4. **Render queue creation** - Collect layers from view hierarchy
5. **Layer animations** - Animate properties in collected layers
6. **Rendering** - Draw layers to framebuffer

**Threading Model:**
The architecture is designed to support multi-threaded rendering where animation and drawing of layers can run in a separate process/thread. This limits callbacks to view code, enhances performance, and enables smoother animations by providing a clear boundary between visual rendering and logical operations.

**Display Bits System:**
UIWindow uses a display bits system (`UIWindowDisplayBits`) to track what needs updating:
- `NeedsDisplay` (0x1) - Framebuffer needs redrawing
- `NeedsLayout` (0x2) - View hierarchy needs layout (cascades to NeedsDisplay)
- `NeedsStyling` (0x4) - View hierarchy needs styling (cascades to NeedsLayout)
- `NeedsNextFrame` (0x8) - Schedule another frame (for continuous animation)

**Styling System:**
UIWindow integrates a styling subsystem where a `styleSheet` object can apply styles to views. Styling runs before layout in the frame pipeline: Styling → Layout → Animation → Render. Views and windows expose `-style` and `-setNeedsStyling`/`-needsStyling` methods to participate in this pipeline.

**Controller as Maestro:**
View controllers act as managers for one or multiple views, coordinating behavior and data flow. They can be added to the window's controller array for automatic retention.

**Tracking Areas and Mouse Events:**
UIWindow provides a sophisticated tracking area system using quadtrees for efficient spatial queries. Tracking areas enable views to receive mouseEntered, mouseExited, mouseMoved, and hover events based on cursor position.

## 3. Core API & Data Structures

### 3.1. `UIWindow.h`

#### `@interface UIWindow : UIPureWindow`

**Purpose:** The main window class that orchestrates the entire UI hierarchy, manages events, animations, layout, and rendering.

**Key Properties:**

- `@property( retain) UIView *view` - The root view (has window frame/bounds)
- `@property( retain) UIPasteboard *pasteboard` - Pasteboard for copy/paste
- `@property( assign) BOOL trackingAreasEnabled` - Enable/disable tracking areas
- `@property( assign) BOOL loadDefaultFont` - Whether to load default font (default: YES)
- `@property( retain) id styleSheet` - Optional style sheet object for view styling (renamed from `styler`)
- `@property( retain) UIView *contentView` - Convenience accessor to content view

**Window Planes** (available when `UIWindowStylePlanes` is set in style mask):
- `@property( readonly) UIWindowPlane *contentPlane` - Main content area
- `@property( readonly) UIWindowPlane *alertPlane` - Alert overlay plane
- `@property( readonly) UIWindowPlane *dragAndDropPlane` - Drag and drop plane
- `@property( readonly) UIWindowPlane *menuPlane` - Menu overlay plane
- `@property( readonly) UIWindowPlane *toolTipPlane` - Tooltip overlay plane

**Frame Callbacks** (for custom rendering/animation integration):
- `@property void (*willRenderLayersCallback)(UIWindow *, id <UIGraphicsContext>, struct CGFrameInfo *)` - Called before rendering layers
- `@property void (*didRenderLayersCallback)(UIWindow *, id <UIGraphicsContext>, struct CGFrameInfo *)` - Called after rendering layers
- `@property void (*willLayoutViewsCallback)(UIWindow *, struct CGFrameInfo *)` - Called before layout
- `@property void (*didLayoutViewsCallback)(UIWindow *, struct CGFrameInfo *)` - Called after layout
- `@property void (*didCreateViewsDrawingQueueCallback)(UIWindow *, struct CGFrameInfo *)` - Called after render queue creation
- `@property BOOL (*didAnimateLayersCallback)(UIWindow *, struct CGFrameInfo *, NSInteger stage)` - Called after each animation stage

**Factory Methods:**

```objc
+ (instancetype) windowWithView:(UIView *) view
                titleUTF8String:(char *) title
                      styleMask:(NSUInteger) styleMask;

+ (instancetype) windowWithView:(UIView *) view
                 titleUTF8String:(char *) title;

+ (instancetype) windowWithLayer:(id <UILayer>) layer
                 titleUTF8String:(char *) title
                       styleMask:(NSUInteger) styleMask;

+ (instancetype) windowWithLayer:(id <UILayer>) layer
                 titleUTF8String:(char *) title;
```

**Core Operations:**

```objc
// Display management (thread-safe)
// needsDisplay bits: NeedsDisplay(0x1), NeedsLayout(0x2), NeedsStyling(0x4), NeedsNextFrame(0x8)
- (void) setNeedsLayout      MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) needsLayout         MULLE_OBJC_THREADSAFE_METHOD;
- (void) setNeedsAnimation   MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) needsAnimation      MULLE_OBJC_THREADSAFE_METHOD;
- (void) setNeedsRenderLayers                MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) needsRenderLayers                   MULLE_OBJC_THREADSAFE_METHOD;
// Previously named setNeedsRedraw / needsRedraw
// Content view management
- (UIView *) contentView;
- (void) setContentView:(UIView *) view;

// Tracking state
- (BOOL) isTracking;
- (BOOL) receivesMouseMotionEvents;

// Animator access
- (CAAnimator *) preLayoutAnimator;
- (CAAnimator *) postLayoutAnimator;

// Layout delegate management (delegates are not retained)
- (void) addToLayoutDelegates:(id <UIWindowLayoutDelegate>) delegate;
- (void) removeFromLayoutDelegates:(id <UIWindowLayoutDelegate>) delegate;

// View controller management (controllers are retained)
- (void) addToViewControllers:(UIViewController *) controller;
- (void) removeFromViewControllers:(UIViewController *) controller;

// Plane checking
- (BOOL) isWindowPlane:(UIView *) view;
```

### 3.1.5. `UIWindow+Styling.h`

**Purpose:** Styling subsystem for applying a style sheet to the view hierarchy. Styling runs before layout in the frame pipeline.

```objc
@interface UIWindow( Styling)

// Trigger the styling pass on the view hierarchy (runs before layout)
- (void) style;

// Request styling on next render (cascades to NeedsLayout and NeedsDisplay)
- (void) setNeedsStyling;
- (BOOL) needsStyling;

@end
```

### 3.2. `UITrackingArea.h`

#### `@interface UITrackingArea : NSObject <UIAutoresizing>`

**Purpose:** Defines a rectangular region in a view that can track mouse events. When the cursor enters, exits, moves within, or hovers over the area, the owner receives tracking events.

**Key Properties:**

- `@property( assign) id owner` - Object receiving tracking events (not retained)
- `@property( assign) UICursor *cursor` - Cursor to display over area
- `@property( assign) CGRect rect` - Tracking rectangle in view coordinates
- `@property( retain) id userInfo` - User-defined data
- `@property( assign) UITrackingAreaOptions trackingAreaOptions` - Tracking options
- `@property( assign) UIView *view` - Owning view (not retained)
- `@property( assign) NSInteger tag` - User-defined tag for identification
- `@property( retain) NSTimer *hoverTimer` - Timer for hover events
- `@property( assign) NSUInteger autoresizingMask` - How area resizes with view

**Tracking Area Options:**

```objc
typedef NS_OPTIONS( NSUInteger, UITrackingAreaOptions)
{
   UITrackingIgnoreMouseEnteredAndExited = 0x1,    // Don't send entered/exited events
   UITrackingMouseMoved                  = 0x2,    // Send mouseMoved: events
   UITrackingSetCursor                   = 0x8,    // Update cursor when entering
   UITrackingVisibleRectOnly             = 0x10,   // Track only visible rect
   UITrackingAssignUserInfo              = 0x20,   // Don't retain userInfo
   UITrackingAreaReceivesObscuredEvents  = 0x100,  // Receive events even if obscured
   UITrackingActiveWhenFirstResponder    = 0x200,  // Only active when first responder
   UITrackingMouseHover                  = 0x400   // Send hover events after delay
};
```

**Factory Methods:**

```objc
+ (instancetype) trackingAreaWithRect:(CGRect) rect;

+ (instancetype) trackingAreaWithRect:(CGRect) rect
                              options:(UITrackingAreaOptions) options
                                owner:(id) owner
                             userInfo:(id) userInfo;
```

**Lifecycle:**

```objc
- (instancetype) initWithRect:(CGRect) rect
                      options:(UITrackingAreaOptions) options
                        owner:(id) owner
                     userInfo:(id) userInfo;
```

**Operations:**

```objc
// Check if tracking is active at location
- (BOOL) isTrackingActiveAtLocation:(CGPoint) location
                           inWindow:(UIWindow *) window;

// Hover timer management
- (void) stopHoverTimerWithWindow:(UIWindow *) window;
- (void) startHoverTimerWithWindow:(UIWindow *) window;
- (void) resetHoverTimerWithWindow:(UIWindow *) window;
```

#### `@protocol UITrackingAreaOwner`

**Purpose:** Protocol that tracking area owners must implement to receive tracking events.

**Required Methods:**

```objc
- (void) mouseMoved:(UIMouseTrackingEvent *) event;
- (void) mouseEntered:(UIMouseTrackingEvent *) event;
- (void) mouseExited:(UIMouseTrackingEvent *) event;
```

**Optional Methods:**

```objc
- (void) mouseHoverStarted:(UIMouseTrackingEvent *) event;
- (void) mouseHoverEnded:(UIMouseTrackingEvent *) event;
```

### 3.3. `UIWindow+UIEvent.h`

**Purpose:** Event handling for UIWindow.

```objc
@interface UIWindow( UIEvent)

// Process mouse motion event through window's view hierarchy
- (UIMouseMotionEvent *) acceptMouseMotionEvent:(UIMouseMotionEvent *) event;

@end
```

### 3.4. `UIWindow+Layout.h`

**Purpose:** Layout and animation orchestration during frame rendering.

```objc
@interface UIWindow( Layout)

// Debug method to track which views were laid out (thread-safe)
- (void) addLayoutedView:(UIView *) view     MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) isLayoutedView:(UIView *) view      MULLE_OBJC_THREADSAFE_METHOD;

// Animation and layout pipeline
- (UIWindowDisplayBits) preLayoutAnimations:(struct CGFrameInfo *) info;
- (void) layoutFrame:(struct CGFrameInfo *) info;
- (UIWindowDisplayBits) postLayoutAnimations:(struct CGFrameInfo *) info;
- (UIWindowDisplayBits) animateRenderQueueLayersInFrame:(struct CGFrameInfo *) info
                                            displayBits:(UIWindowDisplayBits) displayBits;

@end

// Standard layout function used by default frame callback
MULLE_UI_WINDOW_GLOBAL
UIWindowDisplayBits
   UIWindowDefaultLayoutViews( UIWindow *self,
                               struct CGFrameInfo *info,
                               UIWindowDisplayBits displayBits);
```

### 3.5. `UIWindow+RenderQueue.h`

**Purpose:** Manage the render queue - collecting layers from the view hierarchy for rendering.

```objc
@interface UIWindow( RenderQueue)

// Notify window of potential layout needs before frame starts
- (UIWindowDisplayBits) willLayoutWithAbsoluteTime:(mulle_absolutetime_t) renderStart;

// Create render queue from view hierarchy
- (void) createRenderQueueForFrame:(struct CGFrameInfo *) info
                   graphicsContext:(id <UIGraphicsContext>) context;

- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
           graphicsContext:(id <UIGraphicsContext>) context;

@end

// Standard render queue preparation
MULLE_UI_WINDOW_GLOBAL
UIWindowDisplayBits
   UIWindowDefaultPrepareRenderQueue( UIWindow *self,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *info,
                                      UIWindowDisplayBits displayBits);
```

### 3.6. `UIWindow+Render.h`

**Purpose:** Rendering layers to graphics context.

```objc
@interface UIWindow( Render)

// Render all layers in the render queue
- (void) renderLayersInFrame:(struct CGFrameInfo *) info
            graphicsContext:(id <UIGraphicsContext>) context;

@end

// Complete render pipeline (layout + prepare + draw)
MULLE_UI_WINDOW_GLOBAL
UIWindowDisplayBits
   UIWindowDefaultRenderViews( UIPureWindow *self_in,
                             id <UIGraphicsContext> context,
                             struct CGFrameInfo *info,
                             UIWindowDisplayBits displayBits);

struct UIWindowDebugInfo
{
   struct CGFrameInfo  *info;
   NSUInteger          numberOfFrames;
   NSUInteger          activeAnimations;
   NSUInteger          runningAnimations;
   NSUInteger          finishedAnimations;
};
```

### 3.7. `UIWindow+UITrackingArea.h`

**Purpose:** Tracking area management and mouse tracking event processing.

**Mouse Tracking Event Types:**

```objc
enum
{
   UIMouseTrackingMovedEventType        = 0,
   UIMouseTrackingEnteredEventType      = 1,
   UIMouseTrackingExitedEventType       = 2,
   UIMouseTrackingHoverStartedEventType = 3,
   UIMouseTrackingHoverEndedEventType   = 4
};
```

#### `@interface UIMouseTrackingEvent : UIInputEvent`

**Purpose:** Event object for mouse tracking events.

**Properties:**

- `@property( assign) NSUInteger type` - Event type (moved/entered/exited/hover)
- `@property( assign) UITrackingArea *trackingArea` - Associated tracking area (not retained)

**Methods:**

```objc
- (void) updateWithInputEvent:(UIInputEvent *) event;
- (void) updateTrackingArea:(UITrackingArea *) area
                       type:(NSUInteger) type;
```

#### `@interface UIWindow( UITrackingArea)`

```objc
// Quadtree management for efficient spatial queries
- (void) setupQuadtree;
- (void) invalidateQuadTree;

// Tracking view management (use UIView methods, not these directly)
- (void) addTrackingView:(UIView *) view;
- (void) removeTrackingView:(UIView *) view;

// Invalidate tracking for a specific view
- (void) invalidateTrackingAreasForView:(UIView *) view;

// Process tracking events
- (void) handleTrackingAreaForInputEvent:(UIInputEvent *) event
                                  inDrag:(BOOL) inDrag;

// Start hover timer
- (void) startMouseHoverOverTrackingArea:(UITrackingArea *) area;

// Query tracking areas intersecting a rect in window coordinates
- (NSUInteger) getTrackingAreasIntersectingRect:(CGRect) rect
                                          areas:(UITrackingArea **) buf
                                       maxAreas:(NSUInteger) maxAreas;
// Returns total number of intersecting areas.
// Fills buf with up to maxAreas results. Return value may exceed maxAreas.

@end
```

### 3.8. `UIView+UIWindow.h`

**Purpose:** UIView extensions for window integration.

```objc
@interface UIView( UIWindow)

// Get the window plane containing this view (if window uses planes)
- (UIWindowPlane *) windowPlane;

// Get pixels per inch of the screen containing the view (thread-safe)
- (CGFloat) pixelsPerInchOfCurrentScreen  MULLE_OBJC_THREADSAFE_METHOD;

// Request display update (thread-safe)
- (void) setNeedsDisplay                  MULLE_OBJC_THREADSAFE_METHOD;

// Request layout (forwarded to window)
- (void) setNeedsLayout;
- (BOOL) needsLayout;

// Trigger styling pass from this view (new in latest version)
- (void) style;

@end
```

### 3.9. `UIView+UITrackingArea.h`

**Purpose:** UIView extensions for managing tracking areas.

```objc
@interface UIView( UITrackingArea)

// Query tracking areas
- (NSUInteger) numberOfTrackingAreas;
- (UITrackingArea *) trackingAreaAtIndex:(NSUInteger) i;

// Add tracking area (you retain ownership)
- (void) addRetainedTrackingArea:(UITrackingArea *) item
                        toWindow:(UIWindow *) window;

- (void) addRetainedTrackingArea:(UITrackingArea *) area;

// Convenience (uses [self window], sets owner to self if not set, retains area)
- (void) addTrackingArea:(UITrackingArea *) area;

// Remove tracking areas
- (void) removeTrackingArea:(UITrackingArea *) item;
- (void) removeAllTrackingAreas;

// Update tracking areas when layout changes
- (void) updateTrackingAreas;

// Hover time interval
- (mulle_relativetime_t) hoverTimeInterval;

// Tracking event methods (default implementations trace only)
- (void) mouseEntered:(UIMouseTrackingEvent *) event;
- (void) mouseMoved:(UIMouseTrackingEvent *) event;
- (void) mouseExited:(UIMouseTrackingEvent *) event;
- (void) mouseHoverStarted:(UIMouseTrackingEvent *) event;
- (void) mouseHoverEnded:(UIMouseTrackingEvent *) event;

@end
```

### 3.10. `UIView+UIFirstResponder.h`

**Purpose:** First responder management for views.

```objc
@interface UIView( UIFirstResponder)

// First responder chain navigation
- (id <UIResponder>) previousFirstResponder;
- (id <UIResponder>) nextFirstResponder;

// Become or resign first responder status
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (BOOL) isFirstResponder;

@end
```

### 3.10.5. `UIView+UIFirstResponderSearch.h`

**Purpose:** Spatial search for navigating the first responder chain based on geometric direction, enabling keyboard-based focus movement between views.

```objc
struct UIFirstResponderSearch
{
   UIView        *referenceView;
   CGRect        referenceViewFrame;

   UIView        *best;
   CGRect        bestScreenFrame;

   CADirection   primaryDirection;
   CADirection   secondaryDirection;

   CGFloat       fummelX;
   CGFloat       fummelY;
};

MULLE_UI_WINDOW_GLOBAL
void  UIFirstResponderSearchInit( struct UIFirstResponderSearch *p,
                                   id <UIResponder> responder,
                                   CADirection primaryDirection,
                                   CADirection secondaryDirection);

static inline UIView   *UIFirstResponderSearchGetResult( struct UIFirstResponderSearch *p)
{
   return( p ? p->best : nil);
}

static inline void  UIFirstResponderSearchDone( struct UIFirstResponderSearch *p)
{
}

@interface UIView( UIFirstResponderSearch)

- (void) _firstResponderSearch:(struct UIFirstResponderSearch *) search;

@end
```

### 3.11. `UIView+CAAnimation.h`

**Purpose:** Implicit animation support for UIView using CAAnimation.

**Animation Curve Types:**

```objc
typedef NS_ENUM( NSUInteger, UIViewAnimationCurve)
{
   UIViewAnimationCurveEaseInOut = CAAnimationCurveEaseInOut,
   UIViewAnimationCurveEaseIn    = CAAnimationCurveEaseIn,
   UIViewAnimationCurveEaseOut   = CAAnimationCurveEaseOut,
   UIViewAnimationCurveLinear    = CAAnimationCurveLinear
};

typedef NS_OPTIONS( NSUInteger, UIViewForgetImplicitAnimationsMode)
{
   UIViewForgetImplicitAnimationsAll          = 0x0,
   UIViewForgetImplicitAnimationsSkipSelf     = 0x1,
   UIViewForgetImplicitAnimationsSkipLayers   = 0x2,
   UIViewForgetImplicitAnimationsSkipSubviews = 0x4,
};
```

#### `@interface UIView( CAAnimation) <CAImplicitlyAnimatableObject>`

**Purpose:** Provides UIKit-style animation API that generates CAAnimationGroup objects.

**Class Methods for Animation Context:**

```objc
// Begin/commit animation block
+ (void) beginAnimations:(char *) animationID
                 context:(id) context;
+ (CAAnimationGroup *) commitAnimations;  // Returns animation group to add to window

// Animation enabled state
+ (BOOL) areAnimationsEnabled;

// Animation callbacks (delegate pattern — set delegate on CAAnimationGroup)
+ (void) setAnimationDelegate:(id) delegate;

// Animation parameters
+ (NSUInteger) animationCurve;
+ (void) setAnimationCurve:(NSUInteger) curve;

+ (CATweenFunction *) animationTweenFunction;
+ (void) setAnimationTweenFunction:(CATweenFunction *) curve;

+ (mulle_relativetime_t) animationDelay;
+ (void) setAnimationDelay:(mulle_relativetime_t) delay;

+ (mulle_relativetime_t) animationDuration;
+ (void) setAnimationDuration:(mulle_relativetime_t) duration;

+ (mulle_relativetime_t) animationOffset;
+ (void) setAnimationOffset:(mulle_relativetime_t) offset;

+ (BOOL) animationRepeatAutoreverses;
+ (void) setAnimationRepeatAutoreverses:(BOOL) flag;

+ (BOOL) animationIsAdditive;
+ (void) setAnimationIsAdditive:(BOOL) flag;

+ (BOOL) mulleAnimationRepeats;
+ (void) mulleSetAnimationRepeats:(BOOL) flag;

+ (void) setAnimationRepeatCount:(float) repeatCount;
+ (float) animationRepeatCount;

+ (void) addAnimatableObject:(id <CAImplicitlyAnimatableObject>) object;
```

**Instance Methods:**

```objc
// Signal that properties will change (creates implicit animations)
- (void) willChange;

// Remove implicit animations
- (void) forgetImplicitAnimations:(UIViewForgetImplicitAnimationsMode) mode;
```

**Helper Function:**

```objc
static inline BOOL UIViewAreAnimationsEnabled( void)
{
   return( CATransactionGetCurrentTransaction() != nil);
}
```

### 3.12. `UIView+RenderQueue.h`

**Purpose:** View participation in render queue creation.

```objc
struct UIRenderQueueContext
{
   id <UIGraphicsContext>  context;
   CGAffineTransform       xform;
   CGRect                  clipRect;
   CGFloat                 alpha;
};

@interface UIView( RenderQueue)

// Collect layers from this view and subviews into render queue
- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
           graphicsContext:(id <UIGraphicsContext>) context;

// Debug render queue contents
- (void) dumpRenderQueue:(struct mulle_pointerarray *) renderQueue;

// Override to customize how layers are collected (call super!)
- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
                   context:(struct UIRenderQueueContext *) ctx;

// Override to customize layer addition to render queue
- (void) addLayer:(id <UILayer>) layer
    toRenderQueue:(struct mulle_pointerarray *) renderQueue
          context:(struct UIRenderQueueContext *) v;

@end
```

### 3.13. `UIWindow+FrameInfo.h`

**Purpose:** Internal frame processing support.

```objc
@interface UIWindow( FrameInfo)

// Setup initial first responder if needed
- (void) render_setupInitialFirstResponderIfNeeded;

// Adjust frame timing/display bits
- (UIWindowDisplayBits) render_adjustFrameWithFrameInfo:(struct CGFrameInfo *) info
                                            displayBits:(UIWindowDisplayBits) displayBits;

@end
```

### 3.14. `UIWindow+OneFrame.h`

**Purpose:** Support for single-frame rendering (legacy GLFW-style loop).

```objc
@interface UIWindow( OneFrame)

// Handle events for one frame iteration
- (void) eventHandlingWithFrameRate:(mulle_relativetime_t) frameRate;

@end
```

## 4. Performance Characteristics

**View Hierarchy Traversal:**
- Layout: O(n) where n is number of views needing layout
- Render queue creation: O(n) where n is number of views with layers
- Rendering: O(m) where m is number of layers in render queue

**Tracking Area Management:**
- Quadtree spatial indexing provides O(log n) average case for point queries
- Setup cost: O(n) where n is number of tracking areas
- Invalidation and rebuild: O(n)
- Mouse event processing: O(log n) for spatial query + O(k) for k matching areas

**Animation System:**
- Pre-layout animator: O(a) where a is number of active animations
- Post-layout animator: O(a) 
- Layer animations: O(l) where l is number of animated layers
- Animation updates run every frame at display refresh rate (typically 60Hz)

**Thread-Safety:**
- Display bit operations (setNeedsLayout, setNeedsStyling, setNeedsRenderLayers, setNeedsAnimation) are thread-safe
- Layouted view tracking uses a concurrent pointerset for thread safety
- View hierarchy modifications require the viewHierarchyLock (recursive lock)
- Rendering occurs on dedicated window thread if multi-threaded
- Main thread can safely request display updates via thread-safe methods

**Memory Characteristics:**
- Tracking areas are not retained by owner/view (weak references)
- Controllers added to window are retained
- Layout delegates are not retained
- Render queue is rebuilt every frame (temporary allocation)
- Window maintains separate arrays for tracking views, entered areas, layout delegates, controllers

**Frame Budget:**
- Target: 16.67ms per frame at 60Hz
- Layout phase: Should complete in <5ms for typical UIs
- Animation phase: <2ms for moderate animation counts
- Render phase: Depends on layer complexity and graphics backend
- If frame exceeds budget, consider multi-threaded rendering approach

## 5. AI Usage Recommendations & Patterns

**Best Practices:**

1. **Window Lifecycle:**
   - Create windows with factory methods for convenience
   - Use `windowWithView:titleUTF8String:` for simple cases
   - Use planes (`UIWindowStylePlanes`) for complex overlays (alerts, menus, tooltips)
   - Set up callbacks (willRenderLayersCallback, etc.) before showing window

2. **View Hierarchy:**
   - Always modify view hierarchy from main thread or with viewHierarchyLock
   - Use `setNeedsLayout` to request layout, don't call `-layout` directly
   - Use `setNeedsDisplay` to request redraw, don't call render methods directly
   - Views added to window planes are automatically managed

3. **Tracking Areas:**
   - Use `-[UIView addTrackingArea:]` convenience method
   - Update tracking areas in `-updateTrackingAreas` when view geometry changes
   - Set appropriate autoresizingMask on tracking areas
   - Use tags to identify tracking areas in events
   - Implement `UITrackingAreaOwner` protocol methods in your view
   - Don't retain UITrackingArea objects given in events (they use assign semantics)

4. **Animation:**
   - Use `[UIView beginAnimations:context:]` / `commitAnimations` for implicit animations
   - Call `-willChange` on objects before changing animatable properties
   - Add animation group to appropriate animator (preLayoutAnimator or postLayoutAnimator)
   - Pre-layout animations run before view layout (good for view geometry changes)
   - Post-layout animations run after layout (good for layer properties)
   - Use `-forgetImplicitAnimations:` to cancel unwanted animations

5. **First Responder:**
   - Use `-becomeFirstResponder` / `-resignFirstResponder` to manage focus
   - Check `-isFirstResponder` to determine current focus
   - Navigate responder chain with `-nextFirstResponder` / `-previousFirstResponder`
   - Window automatically manages first responder when views are added/removed

6. **Layout Delegates:**
   - Implement `UIWindowLayoutDelegate` protocol
   - Add delegate with `-addToLayoutDelegates:` (not retained)
   - Receive `-willLayoutWithAbsoluteTime:` before each frame
   - Return appropriate UIWindowDisplayBits to request layout/animation/redraw
   - Remove delegate before deallocation

7. **Threading:**
   - Use thread-safe methods (marked with MULLE_OBJC_THREADSAFE_METHOD)
   - Don't directly access window internals from non-window thread
   - Use invocation queues for cross-thread communication
   - Callbacks run on window thread, be mindful of thread affinity

8. **Styling:**
   - Set `styleSheet` property to provide a style sheet object
   - Use `-setNeedsStyling` to request a styling pass (cascades to layout)
   - Views implement `-style` to apply style sheet properties
   - Styling runs before layout in the frame pipeline
   - Call `-[UIView style]` to trigger styling on individual views

**Common Pitfalls:**

1. **Tracking Area Ownership:**
   - Don't retain UITrackingArea objects given in events (owner/view properties are assign)
   - Tracking areas are retained by the view, but references are weak
   - If you store a tracking area, be aware it might be deallocated

2. **Display Bits Confusion:**
   - Display bits cascade: NeedsStyling → NeedsLayout → NeedsDisplay
   - `setNeedsRenderLayers` re-renders layers without layout
   - `setNeedsLayout` also sets NeedsDisplay
   - `setNeedsStyling` also sets NeedsLayout
   - `setNeedsAnimation` schedules next frame at animation rate
   - Usually need to set multiple bits for complete update

3. **Layout Reentrancy:**
   - Don't call `-layout` directly, use `setNeedsLayout`
   - Don't modify view hierarchy during layout (causes recursive layout)
   - Window tracks layouted views to detect accidental re-layout

4. **Animation Timing:**
   - Animation context is class-level (affects all views in block)
   - Must call `commitAnimations` and add to animator
   - Animations only run during frame processing
   - Duration/delay specified in mulle_relativetime_t (not seconds directly)

5. **Thread Affinity:**
   - Graphics contexts have thread affinity
   - Don't share graphics resources across threads
   - Window renders on its own thread in multi-threaded mode

6. **Planes vs. Simple View:**
   - Planes are only available if window created with `UIWindowStylePlanes`
   - If not using planes, contentView == view
   - Planes provide separate layers for UI elements (content, alerts, menus, etc.)
   - Choose plane architecture at window creation time

**Idiomatic Usage:**

1. **Use convenience methods for common patterns:**
   ```objc
   // Instead of manually creating view and window
   UIWindow *window = [UIWindow windowWithView:myView titleUTF8String:"My Window"];
   ```

2. **Use callback properties for custom rendering:**
   ```objc
   [window setWillRenderLayersCallback:myRenderCallback];
   ```

3. **Use tracking areas for interactive regions:**
   ```objc
   UITrackingArea *area = [UITrackingArea trackingAreaWithRect:rect
                                                       options:UITrackingMouseHover
                                                         owner:self
                                                      userInfo:nil];
   [view addTrackingArea:area];
   ```

4. **Use implicit animations for smooth transitions:**
   ```objc
   [UIView beginAnimations:"move" context:nil];
   [UIView setAnimationDuration:0.3];
   [view willChange];
   [view setFrame:newFrame];
   CAAnimationGroup *group = [UIView commitAnimations];
   [[window postLayoutAnimator] addAnimation:group];
   ```

## 6. Integration Examples

### Example 1: Creating a Basic Window with View

```c
#import <MulleUIWindow/MulleUIWindow.h>

int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;
   UIView          *contentView;
   CGRect          frame;
   
   app    = [UIApplication sharedInstance];
   
   // Create content view
   frame        = CGRectMake( 0, 0, 400, 300);
   contentView  = [UIView viewWithFrame:frame];
   [contentView setBackgroundColor:CGColorMakeRGB( 0.2, 0.2, 0.3, 1.0)];
   
   // Create window with view
   window = [UIWindow windowWithView:contentView
                     titleUTF8String:"My Window"];
   
   [window orderFront];
   [app run];
   
   return( 0);
}
```

### Example 2: Creating Window with Planes for Complex UI

```c
#import <MulleUIWindow/MulleUIWindow.h>

int   main( void)
{
   UIApplication    *app;
   UIWindow         *window;
   UIView           *contentView;
   UIView           *menuView;
   UIWindowPlane    *contentPlane;
   UIWindowPlane    *menuPlane;
   CGRect           frame;
   
   app = [UIApplication sharedInstance];
   
   // Create window with planes enabled
   frame  = CGRectMake( 100, 100, 640, 480);
   window = [[UIWindow alloc] initWithFrame:frame
                             titleUTF8String:"Plane Window"
                                   styleMask:UIWindowStylePlanes|UIWindowStyleResizable];
   
   // Setup content plane
   contentPlane = [window contentPlane];
   contentView  = [UIView viewWithFrame:[contentPlane bounds]];
   [contentView setBackgroundColor:CGColorMakeRGB( 0.9, 0.9, 0.9, 1.0)];
   [contentView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [contentPlane addSubview:contentView];
   
   // Setup menu plane (initially hidden)
   menuPlane = [window menuPlane];
   menuView  = [UIView viewWithFrame:CGRectMake( 10, 10, 200, 100)];
   [menuView setBackgroundColor:CGColorMakeRGB( 1.0, 1.0, 1.0, 0.95)];
   [menuView setHidden:YES];
   [menuPlane addSubview:menuView];
   
   [window orderFront];
   [app run];
   
   return( 0);
}
```

### Example 3: Using Tracking Areas for Mouse Interaction

```c
#import <MulleUIWindow/MulleUIWindow.h>

@interface InteractiveView : UIView <UITrackingAreaOwner>
@property CGColor   normalColor;
@property CGColor   hoverColor;
@end

@implementation InteractiveView

- (instancetype) initWithFrame:(CGRect) frame
{
   UITrackingArea   *area;
   CGRect           rect;
   
   self = [super initWithFrame:frame];
   
   [self setNormalColor:CGColorMakeRGB( 0.3, 0.5, 0.7, 1.0)];
   [self setHoverColor:CGColorMakeRGB( 0.5, 0.7, 0.9, 1.0)];
   [self setBackgroundColor:[self normalColor]];
   
   // Add tracking area covering entire view
   rect = [self bounds];
   area = [UITrackingArea trackingAreaWithRect:rect
                                       options:UITrackingMouseHover
                                         owner:self
                                      userInfo:nil];
   [area setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [self addTrackingArea:area];
   
   return( self);
}

- (void) mouseEntered:(UIMouseTrackingEvent *) event
{
   [self setBackgroundColor:[self hoverColor]];
   [self setNeedsDisplay];
}

- (void) mouseExited:(UIMouseTrackingEvent *) event
{
   [self setBackgroundColor:[self normalColor]];
   [self setNeedsDisplay];
}

- (void) mouseHoverStarted:(UIMouseTrackingEvent *) event
{
   printf( "Hover started!\n");
}

@end
```

### Example 4: Animating View Properties

```c
#import <MulleUIWindow/MulleUIWindow.h>

void   animateViewToPosition( UIView *view, CGPoint newOrigin, UIWindow *window)
{
   CAAnimationGroup   *group;
   CGRect             newFrame;
   
   // Begin animation block
   [UIView beginAnimations:"moveView" context:nil];
   [UIView setAnimationDuration:0.5];
   [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
   
   // Change view property (will be animated implicitly)
   [view willChange];
   newFrame         = [view frame];
   newFrame.origin  = newOrigin;
   [view setFrame:newFrame];
   
   // Commit and add to window's post-layout animator
   group = [UIView commitAnimations];
   [[window postLayoutAnimator] addAnimation:group];
   
   // Request window update
   [window setNeedsAnimation];
}
```

### Example 5: Using Layout Delegates

```c
#import <MulleUIWindow/MulleUIWindow.h>

@interface AnimationController : NSObject <UIWindowLayoutDelegate>
@property( assign) UIView   *targetView;
@property( assign) BOOL     isAnimating;
@end

@implementation AnimationController

- (UIWindowDisplayBits) willLayoutWithAbsoluteTime:(mulle_absolutetime_t) renderStart
{
   UIWindowDisplayBits   bits;
   
   bits = 0;
   
   if( [self isAnimating])
   {
      // Update animation state
      // Request animation and redraw
      bits = UIWindowDisplayAnimation | UIWindowDisplayRedraw;
   }
   
   return( bits);
}

- (instancetype) init
{
   self = [super init];
   [self setIsAnimating:NO];
   return( self);
}

@end

// Usage:
void   setupLayoutDelegate( UIWindow *window, UIView *view)
{
   AnimationController   *controller;
   
   controller = [[AnimationController alloc] init];
   [controller setTargetView:view];
   
   // Add to window (not retained, so keep strong reference elsewhere)
   [window addToLayoutDelegates:controller];
   
   // Also add to controllers for retention
   [window addToViewControllers:controller];
}
```

### Example 6: Custom Render Callback

```c
#import <MulleUIWindow/MulleUIWindow.h>

void   customRenderCallback( UIWindow *window,
                             id <UIGraphicsContext> context,
                             struct CGFrameInfo *info)
{
   // Custom drawing on top of normal UI
   // This runs after all layers are rendered
   
   CGRect   bounds;
   
   bounds = [window bounds];
   
   // Draw debug info or custom overlay
   // using context's drawing methods
}

void   setupWindow( void)
{
   UIWindow   *window;
   CGRect     frame;
   
   frame  = CGRectMake( 0, 0, 800, 600);
   window = [[UIWindow alloc] initWithFrame:frame
                             titleUTF8String:"Custom Render"
                                   styleMask:0];
   
   // Install custom render callback
   [window setDidRenderLayersCallback:customRenderCallback];
   
   [window orderFront];
}
```

## 7. Dependencies

MulleUIWindow directly depends on:

- **MulleUIPureWindow** - Provides base window functionality (UIPureWindow class) without view hierarchy
- **MulleUIView** - Provides UIView class and view hierarchy management  
- **MulleCA** - Provides Core Animation-like functionality (CALayer, CAAnimator, CAAnimation classes)
- **mulle-objc-list** - Runtime tool for listing Objective-C runtime information

These dependencies form a hierarchy in the MulleUI framework stack:
```
MulleUIWindow (this library)
    ├── MulleUIPureWindow (base window without views)
    ├── MulleUIView (view hierarchy)
    └── MulleCA (animation and layers)
```

MulleUIWindow sits near the top of the MulleUI stack, integrating windowing, view hierarchy, and animation systems into a cohesive UI framework.
