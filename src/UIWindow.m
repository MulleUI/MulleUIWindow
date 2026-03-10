#define _GNU_SOURCE

#import "UIWindow.h"

#import "import-private.h"

#import "UIView+UIWindow.h"
#import "UIWindow+FrameInfo.h"
#import "UIWindow+UIEvent.h"
#import "UIWindow+DebugPrivate.h"


//#define RENDER_DEBUG
//#define FLAG_DEBUG

@interface UIPureWindow ( Private)

- (void) _init;
- (instancetype) _initWithFrame:(CGRect) frame;

@end


@interface UIWindow ( SetFrame)

- (void) _setFrame:(CGRect) frame;

@end


@implementation UIWindow


static struct
{
   struct MulleObjCIMPArray   _initCategoryIMPs;
   struct MulleObjCIMPArray   _deallocCategoryIMPs;
} Self;


+ (void) initialize
{
   struct mulle_allocator   *allocator;

   // don't rerun for subclass
   if( MulleObjCClassGetID( self) != @selector( UIWindow))
      return;

   allocator = MulleObjCClassGetAllocator( self);
   MulleObjCIMPArrayInitCategoryOnly( &Self._initCategoryIMPs, self, @selector( initCategory), allocator);
   MulleObjCIMPArrayInitCategoryOnly( &Self._deallocCategoryIMPs, self, @selector( deallocCategory), allocator);
}


+ (void) deinitialize
{
   MulleObjCIMPArrayDone( &Self._deallocCategoryIMPs);
   MulleObjCIMPArrayDone( &Self._initCategoryIMPs);
}


// conveniences for quick hacks
+ (instancetype) windowWithView:(UIView *) view
                titleUTF8String:(char *) title
                      styleMask:(NSUInteger) styleMask
{
   BOOL           isResizable;
   CGRect         frame;
   NSUInteger     autoresizingMask;
   UIEdgeInsets   margins;
   UIView         *rootView;
   UIWindow       *window;

   autoresizingMask = [view autoresizingMask];
   isResizable      = UIViewAutoresizingIsScaling( autoresizingMask) ||
                      UIViewAutoresizingIsFlexible( autoresizingMask);
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleResizable, isResizable);

   margins = [view margins];
   frame   = [view frame];
   if( ! UIEdgeInsetsEqualToEdgeInsets( margins, UIEdgeInsetsZero))
   {
      // need to wrap into view for margins
      frame        = UIEdgeInsetsExtrudeRect( frame, margins);
      frame.origin = CGPointZero;

      rootView     = [[self viewClass] viewWithFrame:frame];
      [rootView setAutoresizingMask:UIViewAutoresizingScaleToFill];
      [rootView addSubview:view];
   }
   else
      rootView = view;

   [rootView setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [rootView setMargins:UIEdgeInsetsZero];

   frame.origin = CGPointZero;
   window       = [self windowWithFrame:frame
                        titleUTF8String:title ? title : "Demo"
                              styleMask:styleMask];
   [window setView:rootView];
   return( window);
}


+ (instancetype) windowWithView:(UIView *) view
                titleUTF8String:(char *) title
{
   return( [self windowWithView:view 
                 titleUTF8String:title
                       styleMask:UIWindowStyleMaskDefault & ~UIWindowStylePlanes]);
}


// conveniences for quick hacks

+ (instancetype) windowWithLayer:(id <UILayer>) layer
                 titleUTF8String:(char *) title
                       styleMask:(NSUInteger) styleMask
{
   UIView          *view;
   CGRect          frame;
   UIEdgeInsets    margins;
   Class           viewClass;

   // convenience
   frame   = [layer frame];
   margins = UIEdgeInsetsMake( frame.origin.x, frame.origin.y,
                               frame.origin.x, frame.origin.y);
   frame.origin = CGPointZero;
   [layer setFrame:frame];

   viewClass = [self viewClass];
   assert( viewClass);

   view = [viewClass viewWithLayer:layer];
   [view setNameUTF8String:"layerContainerView"];
   [view setMargins:margins];
   [view setAutoresizingMask:UIViewAutoresizingScaleToFill];

   return( [self windowWithView:view
                titleUTF8String:title
                      styleMask:styleMask]);
}

+ (instancetype) windowWithLayer:(id <UILayer>) layer
                 titleUTF8String:(char *) title
{
   return( [self windowWithLayer:layer 
                 titleUTF8String:title
                       styleMask:UIWindowStyleMaskDefault & ~UIWindowStylePlanes]);
}


//
// No OSWindow calls in here
//
- (void) setupContentPlanesInRect:(CGRect) frame 
{
   Class    windowPlaneClass;

   assert( _view);

   windowPlaneClass = [[self class] windowPlaneClass];

   _contentPlane = [windowPlaneClass viewWithFrame:frame];

   [_contentPlane setNameUTF8String:"Window/ContentPlane"];
   [_contentPlane setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [_contentPlane setClipsToBounds:NO];
   [_view addSubview:_contentPlane];

   _toolTipPlane = [windowPlaneClass viewWithFrame:frame];
   [_toolTipPlane setNameUTF8String:"Window/ToolTipPlane"];
   [_toolTipPlane setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [_toolTipPlane setClipsToBounds:NO];
   // why is hiding this a good idea ?
   [_toolTipPlane setHidden:YES];
   [_view addSubview:_toolTipPlane];

   _menuPlane = [windowPlaneClass viewWithFrame:frame];
   [_menuPlane setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [_menuPlane setNameUTF8String:"Window/MenuPlane"];
   [_menuPlane setClipsToBounds:NO];
   // why is hiding this a good idea ?
   [_menuPlane setHidden:YES];
   [_view addSubview:_menuPlane];

   _dragAndDropPlane = [windowPlaneClass viewWithFrame:frame];

   [_dragAndDropPlane setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [_dragAndDropPlane setNameUTF8String:"Window/DragAndDropPlane"];
   [_dragAndDropPlane setClipsToBounds:NO];
   // why is hiding this a good idea ?
   [_dragAndDropPlane setHidden:YES];
   [_view addSubview:_dragAndDropPlane];

   _alertPlane = [windowPlaneClass viewWithFrame:frame];

   [_alertPlane setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [_alertPlane setNameUTF8String:"Window/AlertPlane"];
   [_alertPlane setClipsToBounds:NO];
   // why is hiding this a good idea ?
   [_alertPlane setHidden:YES];
   [_view addSubview:_alertPlane];
}


- (BOOL) isWindowPlane:(UIView *) view
{
   return( view == _contentPlane || 
           view == _alertPlane || 
           view == _menuPlane || 
           view == _dragAndDropPlane || 
           view == _toolTipPlane);
}


- (void) _init
{
   [super _init];

   _asyncAnimationRate   = 1.0 / 60.0;
   _loadDefaultFont      = YES;
   _refreshContentMode   = CGContentModeTopLeft;
   _trackingAreasEnabled = YES;
}


- (instancetype) _initWithFrame:(CGRect) frame
{
   UIWindowDisplayBits        displayBits;

   self = [super _initWithFrame:frame];
   if( ! self)
      return( self);

   // this is done by startThread
   // _windowPropertyLock = [NSLock new];
   _viewHierarchyLock  = [NSRecursiveLock new];

   // initialize various plane for the future, currently only
   // _contentPlane can be used

   _mulle_pointerarray_init( &_renderQueue, 128, MulleObjCInstanceGetAllocator( self));
   _mulle_pointerarray_init( &_layoutDelegates, 8, MulleObjCInstanceGetAllocator( self));
   _mulle_pointerarray_init( &_controllers, 4, MulleObjCInstanceGetAllocator( self));

   // don't use ~0 it traces ugly
   displayBits = UIWindowDisplayNeedsLayout
                 | UIWindowDisplayNeedsAnimation
                 | UIWindowDisplayNeedsRedraw;
   _mulle_atomic_pointer_nonatomic_write( &_needsDisplay, (void *) displayBits);

   // this calls _init on all categories, protocolclasses and classes from
   // UIWindow up
   MulleObjCIMPArrayCallReverse( &Self._initCategoryIMPs, self, self);

   return( self);
}


//
// When we create a window on Linux, the first one usually stays where
// it's at, and doesn't get a refresh or move notice. But a window manager
// may reposition the subsequent window (or even the first), so we get
// a move and refresh event. The refresh event will hit after the first
// render forcing a second render sortof immediately, as the eventloop is
// positioned byhind the renderloop.
//
- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
{
   Class    viewClass;
   UIView   *view;
   CGRect   bounds;

   self = [super initWithFrame:frame
               titleUTF8String:title
                     styleMask:styleMask];
   if( ! self)
      return( self);

   if( ! (styleMask & UIWindowStyleNoView))
   {
      bounds       = [self bounds];
      // UIView init, looks kinda strange passing self here but its for the
      // benefit of TTYWindow which needs to create a layer from osWindow now
      viewClass = [[self class] viewClass];
      view      = [viewClass viewWithFrame:bounds];
      [view setNameUTF8String:"Window/Root"];
      [view setAutoresizingMask:UIViewAutoresizingScaleToFill];
      [self setView:view];
      if( styleMask & UIWindowStylePlanes)
         [self setupContentPlanesInRect:bounds];
   }
   return( self);
}


- (void) finalize
{
   assert( [NSThread mulleIsMainThread]);

   // unmount all subviews, the subviews -window method will now return nil
   // which allows them to finalize

   [_alertPlane removeFromSuperview];
   _alertPlane = nil;
   [_contentPlane removeFromSuperview];
   _contentPlane = nil;
   [_dragAndDropPlane removeFromSuperview];
   _dragAndDropPlane = nil;
   [_menuPlane removeFromSuperview];
   _menuPlane = nil;
   [_toolTipPlane removeFromSuperview];
   _toolTipPlane = nil;

   // get rid of controllers here
   mulle_idarray_call_all( &_controllers, @selector( mullePerformFinalize), nil);

   [_view setWindow:nil];
   [_view mullePerformFinalize];
   [_view autorelease];

   _view           = nil;
   _responder      = nil;
   _firstResponder = nil;

   [super finalize];
}


- (void) dealloc
{
   MulleObjCIMPArrayCall( &Self._deallocCategoryIMPs, self, self);

   [_postLayoutAnimator release];
   [_preLayoutAnimator release];

   mulle_idarray_release_all( &_controllers);
   mulle_pointerarray_done( &_controllers);   // reset intentional=
   mulle_idarray_release_all( &_trackingViews);
   mulle_pointerarray_done( &_trackingViews);
   mulle_idarray_release_all( &_enteredAreas);
   mulle_pointerarray_done( &_enteredAreas);
   mulle_pointerarray_done( &_layoutDelegates);
   mulle_pointerarray_done( &_renderQueue);


   // now done locally in _dealloc
   //_mulle__pointerset_done( &_layoutedViews, MulleObjCInstanceGetAllocator( self));

   mulle_quadtree_destroy( _quadtree);

   [_viewHierarchyLock release];

   [super dealloc];
}


//
// gain and relinquish are tailored to transfer between the UIWindow+Thread
// and the mainThread. Not for anything else (so far)
//
- (void) mulleGainAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   // more todo
   assert( mulle_pointerset_get( uniquing, self) == self);

   [super mulleGainAccessWithUniquingSet:uniquing];

   if( mulle_pointerset_insert( uniquing, _preLayoutAnimator))
      [_preLayoutAnimator mulleGainAccessWithUniquingSet:uniquing];
   if( mulle_pointerset_insert( uniquing, _postLayoutAnimator))
      [_postLayoutAnimator mulleGainAccessWithUniquingSet:uniquing];
}


- (void) mulleRelinquishAccessWithUniquingSet:(struct mulle_pointerset *) uniquing
{
   assert( mulle_pointerset_get( uniquing, self) == self);

   // at this point should we tidy up some more stuff ?
   _mulle__pointerset_reset( &_layoutedViews);

   if( mulle_pointerset_insert( uniquing, _postLayoutAnimator))
      [_postLayoutAnimator mulleRelinquishAccessWithUniquingSet:uniquing];
   if( mulle_pointerset_insert( uniquing, _preLayoutAnimator))
      [_preLayoutAnimator mulleRelinquishAccessWithUniquingSet:uniquing];

   [super mulleRelinquishAccessWithUniquingSet:uniquing];
}


// defined by UIView actually
- (BOOL) __isUIWindow
{
   return( YES);
}


- (void) setView:(UIView *) view
{
   // don't waste planes, if view is the same
   if( view == _view)
      return;

   // UIWindow wont support it
   assert( UIEdgeInsetsEqualToEdgeInsets( [view padding], UIEdgeInsetsZero));
   assert( UIEdgeInsetsEqualToEdgeInsets( [view margins], UIEdgeInsetsZero));

   // less head scratching if someone tries to be too clever, not noticing
   // that the root view will be resized "brute force"
   assert( [view autoresizingMask] == UIViewAutoresizingScaleToFill ||
           [view autoresizingMask] == UIViewAutoresizingFlexibleSize);

   assert( _viewHierarchyLock);
   [view shareRecursiveLock:_viewHierarchyLock];

   [_view setWindow:nil];
   [_view autorelease];

   _view             = [view retain];
   _responder        = view;
   _firstResponder   = nil;
   [view setWindow:self];

   _alertPlane       = nil;
   _contentPlane     = nil;
   _menuPlane        = nil;
   _dragAndDropPlane = nil;
   _toolTipPlane     = nil;

}


+ (Class) viewClass
{
   return( [UIView class]);
}


+ (Class) windowPlaneClass
{
   return( [UIWindowPlane class]);
}


- (UIView *) contentView
{
   // unsure about this assert
   // assert( _view || [self mulleIsFinalized]);
   return( _contentPlane ? _contentPlane : _view);
}


- (void) setContentView:(UIView *) view
{
   assert( view);

   if( _contentPlane)
   {
      [[_contentPlane superview] replaceSubview:_contentPlane
                                       withView:view];
      _contentPlane = view;
      return;
   }

   [self setView:view];
}


- (void) setNeedsStyling
{
   [self setNeedsDisplayBit:UIWindowDisplayNeedsStyling];
}


- (BOOL) needsStyling
{
   return( [self needsDisplay] & UIWindowDisplayNeedsStyling ? YES : NO);
}


- (void) setNeedsLayout
{
   [self setNeedsDisplayBit:UIWindowDisplayNeedsLayout];
}


- (BOOL) needsLayout
{
   return( [self needsDisplay] & UIWindowDisplayNeedsLayout ? YES : NO);
}


- (void) setNeedsAnimation
{
   [self setNeedsDisplayBit:UIWindowDisplayNeedsAnimation];
}


- (BOOL) needsAnimation
{
   return( [self needsDisplay] & UIWindowDisplayNeedsAnimation ? YES : NO);
}


- (void) setNeedsRedraw
{
   [self setNeedsDisplayBit:UIWindowDisplayNeedsRedraw];
}


- (BOOL) needsRedraw
{
   return( [self needsDisplay] & UIWindowDisplayNeedsRedraw ? YES : NO);

}


- (BOOL) isTracking
{
   return( mulle_pointerarray_get_count( &_trackingViews) != 0);
}


- (BOOL) receivesMouseMotionEvents
{
   if( [self isTracking])
      return( YES);
   return( [_firstResponder isMouseMotionEnabled]);
}


- (CGAffineTransform) transformForDrawingQueue:(CGAffineTransform) inherited
{
   return( CGAffineTransformMakeIdentity());
}


- (void) addToLayoutDelegates:(id <UIWindowLayoutDelegate>) delegate
{
   assert( _mulle_pointerarray_find( &_layoutDelegates, delegate) == mulle_not_found_e);
   assert( [(id) delegate respondsToSelector:@selector( willLayoutWithAbsoluteTime:)]);

   _mulle_pointerarray_add( &_layoutDelegates, delegate);
}


- (void) removeFromLayoutDelegates:(id <UIWindowLayoutDelegate>) delegate
{
   extern void   mulle_pointerarray_remove( struct mulle_pointerarray *, void *);

   mulle_pointerarray_remove( &_layoutDelegates, delegate);
}


- (void) addToViewControllers:(UIViewController *) controller
{
   assert( _mulle_pointerarray_find( &_controllers, controller) == mulle_not_found_e);

   [controller retain];
   _mulle_pointerarray_add( &_controllers, controller);
   [controller setWindow:self];
}


- (void) removeFromViewControllers:(UIViewController *) controller
{
   extern void   mulle_pointerarray_remove( struct mulle_pointerarray *, void *);
   uintptr_t    index;

   // defined in UIView
   index = _mulle_pointerarray_find( &_controllers, controller);
   if( index != mulle_not_found_e)
   {
      [controller setWindow:nil];
      [controller autorelease];
      _mulle_pointerarray_remove_in_range( &_controllers, mulle_range_make( index, 1));
   }
}


- (CAAnimator *) preLayoutAnimator
{
   if( ! _preLayoutAnimator)
      _preLayoutAnimator = [CAAnimator new];
   return( _preLayoutAnimator);
}


- (CAAnimator *) postLayoutAnimator
{
   if( ! _postLayoutAnimator)
      _postLayoutAnimator = [CAAnimator new];
   return( _postLayoutAnimator);
}


- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp
{
   [super dumpWithIndent:indent
                    FILE:fp];

   [self->_view dumpWithIndent:indent + 1
                                 FILE:fp];
}


- (void) dumpAnimationsToFILE:(FILE *) fp
{
   mulle_fprintf( fp, "Pre Layout:\n%@\n", _preLayoutAnimator);
   mulle_fprintf( fp, "Post Layout:\n%@\n", _postLayoutAnimator);
}


- (void) dumpAnimations
{
   [self dumpAnimationsToFILE:mulleui_log_fp];
   fflush( mulleui_log_fp);
}

@end
