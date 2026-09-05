//
//  UIWindow+Layout.h
//  MulleUIWindow
//
//  Copyright (c) 2025 Nat! - Mulle kybernetiK.
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
#ifdef __has_include
# if __has_include( "UIWindow.h")
#  import "UIWindow.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@interface UIWindow( Layout)

// debug method, depending on how UIWindow is compiled, this will
// check for duplicated -layout calls to a UIView
- (void) addLayoutedView:(UIView *) view     MULLE_OBJC_THREADSAFE_METHOD;

// used in setFrame: to catch subviews "managing" a superview state
- (BOOL) isLayoutedView:(UIView *) view      MULLE_OBJC_THREADSAFE_METHOD;


//
// If you have preLayoutAnimations, layout will always be called
// -layout is needed for keeping tracking rects in sync (indirectly, by
// invalidating the quadtree)
//
- (UIWindowDisplayBits) preLayoutAnimations:(struct CGFrameInfo *) info;

- (void) layoutFrame:(struct CGFrameInfo *) info;

// runs even if layout is not called
- (UIWindowDisplayBits) postLayoutAnimations:(struct CGFrameInfo *) info;

// returns YES if animation ran
- (UIWindowDisplayBits) animateRenderQueueLayersInFrame:(struct CGFrameInfo *) info
                                displayBits:(UIWindowDisplayBits) displayBits;

@end



@interface UIWindow( LayoutFuture) < MulleObjCFuture>

- (void) createRenderQueueForFrame:(struct CGFrameInfo *) info
                   graphicsContext:(id <UIGraphicsContext>) context;

@end

//
// this function will call methods in this order (if needed)
//
// +-----------------------------+
// | willLayoutWithAbsoluteTime: |
// +-----------------------------+
//        |
//        v
// +----------------------+
// | preLayoutAnimations: |
// +----------------------+
//        |
//        v
// +--------------+
// | layoutFrame: |
// +--------------+
//        |
//        v
// +-----------------------+
// | postLayoutAnimations: |
// +-----------------------+


MULLE_UI_WINDOW_GLOBAL
UIWindowDisplayBits
   UIWindowDefaultLayoutViews( UIWindow *self,
                               struct CGFrameInfo *info,
                               UIWindowDisplayBits displayBits);


#if 0
//
// this function will call methods in this order (if needed)
//
//        |
//        v
// +-----------------------------+
// | createRenderQueueForFrame: |  // Place [UIViews layers] in _renderQueue
// +-----------------------------+
//        |
//        v
// +---------------+
// | animateFrame: |                // animate those in _renderQueue
// +---------------+
//
UIWindowDisplayBits
   UIWindowDefaultPrepareRenderQueue( UIWindow *self,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *info,
                                      UIWindowDisplayBits displayBits);
#endif
