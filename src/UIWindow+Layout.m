//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "UIWindow+Layout.h"

#import "import-private.h"

#import "UIWindow+RenderQueue.h"
#import "UIWindow+DebugPrivate.h"

#ifdef DEBUG
# ifndef DEBUG_DUPLICATE_LAYOUT
#  define DEBUG_DUPLICATE_LAYOUT 1
# endif
#endif
#ifndef DEBUG_DUPLICATE_LAYOUT
#  define DEBUG_DUPLICATE_LAYOUT 0
#endif


@implementation UIWindow ( Layout)

- (BOOL) isLayoutedView:(UIView *) view
{
#if DEBUG_DUPLICATE_LAYOUT
   return( _mulle__pointerset_get( &_layoutedViews, view) ? YES : NO);
#else
   return( NO);
#endif
}


- (void) addLayoutedView:(UIView *) view
{
#if DEBUG_DUPLICATE_LAYOUT
   assert( ! _mulle__pointerset_get( &_layoutedViews, view));
   if( _isLayouting)
      _mulle__pointerset_insert( &_layoutedViews, view, MulleObjCInstanceGetAllocator( self));
#endif
}


- (UIWindowDisplayBits) preLayoutAnimations:(struct CGFrameInfo *) info
{
   BOOL                   didAnimate;
   mulle_relativetime_t   animationRate;
   UIWindowDisplayBits    displayBits;

   UIWindowRenderLog( "");

   MulleWindowProfileBegin();

   animationRate = UIWindowGetAnimationRate( self);
   didAnimate    = [_preLayoutAnimator animateWithAbsoluteTime:info->now
                                                 animationRate:animationRate];
   if( _didAnimateViewsCallback)
      (*_didAnimateViewsCallback)( self, info, 0);

   MulleWindowProfileEnd();

   UIWindowRenderLog( "did %sanimate", didAnimate ? "" : "not ");

   displayBits = didAnimate ? UIWindowDisplayDidAnimate : 0;
   UIWindowDisplayBitsLogVerbose( "returns (%s)", UIWindowDisplayBitsUTF8String( displayBits));
   return( displayBits);
}


- (UIWindowDisplayBits) postLayoutAnimations:(struct CGFrameInfo *) info
{
   BOOL                   didAnimate;
   mulle_relativetime_t   animationRate;
   UIWindowDisplayBits    displayBits;

   UIWindowRenderLog( "");

   MulleWindowProfileBegin();

   //
   // Layout changing animations should be place into the preLayoutAnimator
   //
#ifdef DEBUG
   if( [_postLayoutAnimator hasLayoutChangingAnimations])
   {
      static BOOL   warn;

      if( ! warn)
      {
         MulleUILog( "Layout changing animation should be placed into the preLayoutAnimator");
         warn = YES;
      }
   }
#endif

   animationRate = UIWindowGetAnimationRate( self);
   didAnimate    = [_postLayoutAnimator animateWithAbsoluteTime:info->now
                                                  animationRate:animationRate];
   if( _didAnimateViewsCallback)
      (*_didAnimateViewsCallback)( self, info, 1);

   MulleWindowProfileEnd();

   UIWindowRenderLog( "did %sanimate", didAnimate ? "" : "not ");

   displayBits = didAnimate ? UIWindowDisplayDidAnimate : 0;
   UIWindowDisplayBitsLogVerbose( "returns (%s)", UIWindowDisplayBitsUTF8String( displayBits));
   return( displayBits);
}


#if DEBUG_DUPLICATE_LAYOUT
- (void) initCategory
{
   _mulle__pointerset_init( &_layoutedViews, 64, MulleObjCInstanceGetAllocator( self));
}


- (void) deallocCategory
{
   _mulle__pointerset_done( &_layoutedViews, MulleObjCInstanceGetAllocator( self));
}
#endif


- (void) layout
{
   CGRect   bounds;

#if DEBUG_DUPLICATE_LAYOUT
   assert( ! _isLayouting);
   _isLayouting = YES;
   _mulle__pointerset_done( &_layoutedViews, MulleObjCInstanceGetAllocator( self));
   _mulle__pointerset_init( &_layoutedViews, 64, MulleObjCInstanceGetAllocator( self));
#endif

   bounds = [self bounds];
   [self->_view setFrame:bounds];
   [self->_view layout];

   // this is for debugging
   assert( [self->_view autoresizingMask] == UIViewAutoresizingScaleToFill ||
           [self->_view autoresizingMask] == UIViewAutoresizingFlexibleSize);
   assert( UIEdgeInsetsEqualToEdgeInsets( [self->_view padding], UIEdgeInsetsZero));
   assert( UIEdgeInsetsEqualToEdgeInsets( [self->_view margins], UIEdgeInsetsZero));

#if DEBUG_DUPLICATE_LAYOUT
   _mulle__pointerset_reset( &_layoutedViews);
   _isLayouting = NO;
#endif
   _quadtreeNeedsSetup = YES;
}


- (void) layoutFrame:(struct CGFrameInfo *) info
{
   UIWindowRenderLog( "%s", CGFrameInfoUTF8String( info));

   MulleWindowProfileBegin();
   /*
    * Layout
    */
   if( _willLayoutViewsCallback)
      (*_willLayoutViewsCallback)( self, info);

   //
   // do layout before the animation step, as this may generate animations
   //
#if LAYOUT_ANIMATIONS
   [self beginLayout:info];
#endif
   [self layout];
#if LAYOUT_ANIMATIONS
   [self endLayout];
#endif
   if( _didLayoutViewsCallback)
      (*_didLayoutViewsCallback)( self, info);

   MulleWindowProfileEnd();
}


//
// will be followed by "UIWindowDefaultPrepareRenderQueue", which will
// call animateFrame: below after setting up the drawing queue
//
UIWindowDisplayBits   UIWindowDefaultLayoutViews( UIWindow *self,
                                                  struct CGFrameInfo *info,
                                                  UIWindowDisplayBits displayBits)
{
   UIWindowDisplayBits   animationDisplayBits;
   UIWindowDisplayBits   returnBits;

   //_viewsNeedTrackingAreaUpdate = NO;

   returnBits            = displayBits;

   animationDisplayBits  = [self willLayoutWithAbsoluteTime:info->now];
   animationDisplayBits |= [self preLayoutAnimations:info];

   // if original displayBits contained layout request, of if there are
   // preLayoutAnimations, we run the layouter
   if( (displayBits & UIWindowDisplayNeedsLayout) || animationDisplayBits)
   {
      [self layoutFrame:info];
      returnBits |= UIWindowDisplayNeedsRedraw | UIWindowDisplayNeedsAnimation;

      // MEMO: this gets triggered too often
      returnBits |= UIWindowDisplayNeedsMouseEvent;
   }

   returnBits |= [self postLayoutAnimations:info];
   //if( _viewsNeedTrackingAreaUpdate)
   //   displayBits |= UIWindowDisplayNeedsMouseEvent;

   if( displayBits != returnBits)
      UIWindowDisplayBitsLogVerbose( "augments (%s)", UIWindowDisplayBitsUTF8String( returnBits));
   return( returnBits);
}


- (UIWindowDisplayBits) animateViewsInFrame:(struct CGFrameInfo *) info
                                displayBits:(UIWindowDisplayBits) displayBits
{
   BOOL                   didAnimate;
   mulle_relativetime_t   animationRate;

   UIWindowRenderLog( "%s", CGFrameInfoUTF8String( info));

   /*
    * Animate
    */
   if( ! (displayBits & UIWindowDisplayNeedsAnimation))
      return( displayBits);

   animationRate = UIWindowGetAnimationRate( self);
   didAnimate    = [CAAnimation animateObjects:&_renderQueue
                                  absoluteTime:info->now
                                 animationRate:animationRate];
   //
   // can animations add and subtract layers and views ?
   // they may, but they won't show up this render
   //
   // have no didAnimate callback, because we would like to pipeline
   // with rendering, or but the animation step into the render part ?
   //
   if( _didAnimateViewsCallback)
      didAnimate |= (*_didAnimateViewsCallback)( self, info, 2);

   if( didAnimate)
   {
      displayBits |= UIWindowDisplayDidAnimate;
      displayBits |= UIWindowDisplayNeedsRedraw;
   }
   UIWindowDisplayBitsLogVerbose( "returns (%s)", UIWindowDisplayBitsUTF8String( displayBits));
   return( displayBits);
}

@end
