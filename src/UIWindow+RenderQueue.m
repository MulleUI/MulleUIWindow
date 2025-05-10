//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "UIWindow+RenderQueue.h"

#import "import-private.h"

#import "UIWindow+Layout.h"
#import "UIWindow+DebugPrivate.h"
#import "UIView+RenderQueue.h"


@implementation UIWindow ( RenderQueue)

- (UIWindowDisplayBits) willLayoutWithAbsoluteTime:(mulle_absolutetime_t) renderStart
{
   UIView               *view;
   UIWindowDisplayBits  displayBits;
   UIWindowDisplayBits  bits;

   UIWindowRenderLog( "%.6f", renderStart);

   displayBits = 0;
   mulle_pointerarray_for( &_layoutDelegates, view)
   {
      bits         = [view willLayoutWithAbsoluteTime:renderStart];
      UIWindowDisplayBitsLogVerbose( "-[%#@ willLayoutWithAbsoluteTime:] returned (0x%tx)", view, bits);
      displayBits |= bits;
   }

   UIWindowDisplayBitsLogVerbose( "returns (%s)", UIWindowDisplayBitsUTF8String( displayBits));
   return( displayBits);
}



- (void) setClipsToBounds:(BOOL) flag
{
   assert( ! flag);
}


//
// not UIView because of the clipping rectangle and identity transform
// start
//
- (void) createRenderQueue:(struct mulle_pointerarray *) queue
{
   struct UIRenderQueueContext  v;

   v.xform    = CGAffineTransformMakeIdentity();
   v.clipRect = CGRectMake( -INFINITY, -INFINITY, INFINITY, INFINITY);
   v.alpha    = 1.0;

   //UIViewSubviewsFor( self->_view, view)
   {
      [self->_view createRenderQueue:queue
                             context:&v];
   }
}


- (void) createRenderQueueForFrame:(struct CGFrameInfo *) info
{
   UIWindowRenderLog( "%s", CGFrameInfoUTF8String( info));

   MulleWindowProfileBegin();

   _mulle_pointerarray_reset( &_renderQueue);
   [self createRenderQueue:&_renderQueue];

   if( _didCreateViewsDrawingQueueCallback)
      (*_didCreateViewsDrawingQueueCallback)( self, info);

   MulleWindowProfileEnd();

   UIWindowRenderLog( "%td layers in the queue", _mulle_pointerarray_get_count( &_renderQueue));
}



UIWindowDisplayBits
   UIWindowDefaultPrepareRenderQueue( UIWindow *self,
                                      struct CGFrameInfo *info,
                                      UIWindowDisplayBits displayBits)
{
   //
   // create the renderQueue. This will set the transforms for all
   // the layer and calculate the actual opacity, which is then stored
   // in layer transform and layer alpha.
   //
   [self createRenderQueueForFrame:info];

   //
   // this animateFrame: runs unconditonally over the displayQueue
   // that will be then also be used by drawFrame:
   //
   displayBits = [self animateViewsInFrame:info
                              displayBits:displayBits];

   UIWindowDisplayBitsLogVerbose( "returns (%s)", UIWindowDisplayBitsUTF8String( displayBits));
   return( displayBits);
}

@end
