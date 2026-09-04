//
//  UIWindow+RenderQueue.m
//  MulleUIWindow
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "UIWindow+RenderQueue.h"

#import "import-private.h"

#import "UIWindow+Layout.h"
#import "UIWindow+DebugPrivate.h"
#import "UIView+RenderQueue.h"



@implementation UIWindow ( RenderQueue)

@dependency UIWindow( Layout);


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
           graphicsContext:(id <UIGraphicsContext>) context
{
   struct UIRenderQueueContext  v;

   v.context  = context;
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
                   graphicsContext:(id <UIGraphicsContext>) context
{
   UIWindowRenderLog( "%s", CGFrameInfoUTF8String( info));

   MulleWindowProfileBegin();

   _mulle_pointerarray_reset( &_renderQueue);
   [self createRenderQueue:&_renderQueue
           graphicsContext:context];

   MulleWindowProfileEnd();

   UIWindowRenderLog( "%td layers in the queue", _mulle_pointerarray_get_count( &_renderQueue));
}



// will be called by "UIWindowDefaultRenderViews"
UIWindowDisplayBits
   UIWindowDefaultPrepareRenderQueue( UIWindow *self,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *info,
                                      UIWindowDisplayBits displayBits)
{
   //
   // create the renderQueue. This will set the transforms for all
   // the layer and calculate the actual opacity, which is then stored
   // in layer transform and layer alpha.
   //
   [self createRenderQueueForFrame:info
                   graphicsContext:context];

   //
   // this animateFrame: runs unconditonally over the displayQueue
   // that will be then also be used by drawFrame:
   //
   displayBits = [self animateRenderQueueLayersInFrame:info
                                           displayBits:displayBits];

   UIWindowDisplayBitsLogVerbose( "returns (%s)", UIWindowDisplayBitsUTF8String( displayBits));
   return( displayBits);
}

@end
