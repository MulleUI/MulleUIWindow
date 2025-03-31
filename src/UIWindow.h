#import "import.h"

// TODO: remove UIView from UIWindow. Let UIWindow base on UIApplication and
//       UIView then be based on UIWindow.
//
//       So a UIViewlessWindow in its pristine state, would just accept event
//       and do nothing with them (pretty much). Rendering would be by callback.
//       Trackingareas would just be flat on the window surface.
//
//       This would be easier for testing and for very simple code, that
//       doesn't need layouting at all.



// A "frame" is the timespan taken to fill the contents of the "framebuffer"
// that will then be displayed by swapBuffers. It doesn't contain the time
// needed to handle events.
//
// In UIWindow a "frame" usually does, "layout", "animation", "rendering" in
// this sequence.
//
#define MULLE_UI_WINDOW_THREAD_ONLY    MULLE_OBJC_THREADSAFE_METHOD

struct CGFrameInfo;

typedef UIView   UIWindowPlane;

@class GLFWOSWindow;  // move to private some time
@class UIPasteboard;
@class UIWindow;


//
// UIWindow will forward to _OSWindow, so it implements UIOSWindow
// protocol UIWindow is implemented by +Frame.h
//
// If you want to add a category to UIWindow (directly, not subclasses), you
// will get "initCategory" and "deallocCategory" calls for free.
//
@interface UIWindow : UIPureWindow
{
   // need to setNeedsDisplay to get the renderer out of the lock and start
   // the render. The _contextLock still needs to be observed when
   // attempting to modify the view hierarchy ?
   BOOL                            _isLayouting;

// These ivars are used by the rendering thread only to manage the view
// hierarchy, layout, handle events and draw stuff. If there is no windowThread
// then the mainThread can access this
//
@protected
   BOOL                            _quadtreeNeedsSetup;
   void                            *_quadtree;

   struct mulle_pointerarray       _trackingViews;    // views with tracking areas
   struct mulle_pointerarray       _enteredAreas;     // areas with mouseEntered: sent
   struct mulle_pointerarray       _layoutDelegates;  // objects with get willLayoutWithAbsoluteTime: sent
   struct mulle_pointerarray       _controllers;      // viewcontroller retain point

   CAAnimator                      *_preLayoutAnimator;
   CAAnimator                      *_postLayoutAnimator;
   struct mulle_pointerarray       _drawingQueue; // layers to render

@protected
   //
   // this lock is given to the root view, you don't interact with it
   // directly from UIWindow (especially, you don't lock it)
   //
   NSRecursiveLock                 *_viewHierarchyLock;

@private
   // each view, that gets a -layout call can add itself here, and then
   // check that -layout isn't called twice during a layout
   struct mulle__pointerset        _layoutedViews;

// these values are only accessible to the main thread
@private
   // the profile entries are 64 bytes, at 60 Hz thats 3840 bytes, so one hour
   // of tracing consumes 13,824,000 bytes 13 MB (not caring) :)
   // activate with special window flag

   // used by LED display... so ugly
   NSUInteger                      _debugDisplayBits;
   NSUInteger                      _debugReturnBits;

   // used for showing menus
   char                            _oldUserInteractionEnabled;
   char                            _oldMenuPlaneHidden;
}


// TODO: pasteboard is a global resource and is on Application ?
@property( retain) UIPasteboard                    *pasteboard;

@property( assign, getter=areTrackingAreasEnabled) BOOL   trackingAreasEnabled;

// default yes
@property( assign, getter=isLoadingDefaultFont) BOOL   loadDefaultFont;

//
// This is useful to add custom drawing stuff on the bottom.
//
@property void  (*willDrawViewsCallback)( UIWindow *window,
                                          id <UIGraphicsContext> context,
                                          struct CGFrameInfo *info);

//
// This is useful to add custom nanovg drawing stuff on top.
//
@property void   (*didDrawViewsCallback)( UIWindow *window,
                                          id <UIGraphicsContext> context,
                                          struct CGFrameInfo *info);


// These callbacks will be called in this sequence for every frame.
// It should be obvious, that you don't do any system calls in these callbacks
// and finish ASAP. The mulle_absolutetime_t is the time the render started it will
// be the same through all callbacks.
//
@property void   (*willLayoutViewsCallback)( UIWindow *window,
                                             struct CGFrameInfo *info);
@property void   (*didLayoutViewsCallback)( UIWindow *window,
                                            struct CGFrameInfo *info);

@property void   (*didCreateViewsRenderQueueCallback)( UIWindow *window,
                                                       struct CGFrameInfo *info);

//
// stage #0: after _preLayoutAnimator
// stage #1: after _postLayoutAnimator
// stage #2: after CALayer "privat" animations
// return YES if animations happened (and a redraw should happen)
@property BOOL   (*didAnimateViewsCallback)( UIWindow *window,
                                             struct CGFrameInfo *info,
                                             NSInteger stage);

// the view will have the frame and bounds of the window, it contains the
// planes if these are defined, otherwise directly the contentView
// setting the view, will set the firstResponder to nil and the window
// responder to the view. This view will not use autoresizing mask or
// margins or padding
@property( retain) UIView                     *view;

//
// these properties return nil, if styleMask did not contain UIWindowStylePlanes
// These will be subviews of "view" and "contentPlane" will be the contentView.
//
@property( readonly, assign) UIWindowPlane    *alertPlane;
@property( readonly, assign) UIWindowPlane    *dragAndDropPlane;
// MEMO: If there is one or more UIScrollView between the tooltipping UIView or
//       the menu originator, then there needs to be some way, that scrolls are
//       also scrolling entries (or that the scrollview wipes the tooltip and
//       menu away)
@property( readonly, assign) UIWindowPlane    *menuPlane;
@property( readonly, assign) UIWindowPlane    *toolTipPlane;
@property( readonly, assign) UIWindowPlane    *contentPlane;


// Convenience for quick hacks
// Window will be resizable if the view is resizable
// margins will be observed to create spacing around the view
// if any axis is < 32 in size, 32 will be used
//
+ (instancetype) windowWithView:(UIView *) view
                titleUTF8String:(char *) title               
                      styleMask:(NSUInteger) styleMask;
+ (instancetype) windowWithView:(UIView *) view
                 titleUTF8String:(char *) title;

// even more convenient, even less configurable, for even more
// convenience checkout UIApplication+UIWindow
+ (instancetype) windowWithLayer:(id <UILayer>) layer
                 titleUTF8String:(char *) title
                       styleMask:(NSUInteger) styleMask;
                                              
+ (instancetype) windowWithLayer:(id <UILayer>) layer
                 titleUTF8String:(char *) title;


- (UIView *) contentView;
- (void) setContentView:(UIView *) view; // will either change contentPlane or view depending on setup

// does not deal with focus of events
//- (void) show;
//- (void) hide;

- (BOOL) isTracking;
- (BOOL) receivesMouseMotionEvents;
//
// needs Display is a combination of needsLayout and needsRedraw, needsAnimation
// bits defined in UIWindowDisplayBits
//

// force re-layout on next render, setting this flag does not affect other
// flags
- (void) setNeedsLayout                      MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) needsLayout                         MULLE_OBJC_THREADSAFE_METHOD;

// this flag means, that the there are animations running
- (void) setNeedsAnimation                   MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) needsAnimation                      MULLE_OBJC_THREADSAFE_METHOD;

// this flag means, that the UIView hierarchy needs to be drawn into
// the framebuffer
- (void) setNeedsRedraw                      MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) needsRedraw                         MULLE_OBJC_THREADSAFE_METHOD;


- (CAAnimator *) preLayoutAnimator;
- (CAAnimator *) postLayoutAnimator;

// won't get retained!
- (void) addToLayoutDelegates:(id <UIWindowLayoutDelegate>) delegate;
- (void) removeFromLayoutDelegates:(id <UIWindowLayoutDelegate>) delegate;

- (void) addToViewControllers:(UIViewController *) controller;
- (void) removeFromViewControllers:(UIViewController *) controller;

- (BOOL) isWindowPlane:(UIView *) view;

@end


